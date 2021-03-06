class EmailsController < ApplicationController

  def show
    authorize! :send_email, Email
    @event = Event.find(params[:event_id])

    status = get_status
    @templates = EmailTemplate.with_status(status)
    if status == :acceptance
      @addresses = @event.email_addresses_of_type_without_notification_sent(:accepted)
    elsif (status == :rejection)
      @addresses = @event.email_addresses_of_type_without_notification_sent(:rejected)
      if @event.has_participants_without_status_notification?(:alternative)
        @addresses.append(@event.email_addresses_of_type_without_notification_sent(:alternative))
      end  
    else 
      @addresses = []
    end

    @email = Email.new(hide_recipients: true, reply_to: Rails.configuration.reply_to_address, recipients: @addresses.join(','),
                       subject: '', content: '')
    @send_generic = false
    render :email
  end

  def submit_application_result
    authorize! :send_email, Email
    if params[:send]
      send_application_result_email
    elsif params[:save]
      save_template
    end
  end

  def submit_generic
    authorize! :send_email, Email
    @templates = []
    @event = Event.find(params[:id])
    if params[:send]
      send_generic
    end
  end

  private

  def send_application_result_email
    @email = Email.new(email_params)
    @event = Event.find(params[:event_id])
    status = get_status
    if @email.valid?
      @attachments = []
      if status == :acceptance
        @attachments.push(@event.get_ical_attachment)
        @attachments.push(AgreementLetter.get_attachment)
      end

      @email.send_email(@attachments)

      update_event(@event)

      redirect_to @event, notice: t('emails.submit.sending_successful')
    else
      @templates = EmailTemplate.with_status(status)

      flash.now[:alert] = t('emails.submit.sending_failed')
      @send_generic = false
      render :email
    end
  end

  def send_generic
    @email = Email.new(email_params)
    if @email.valid?
      @email.send_email
      redirect_to @event, notice: t('emails.submit.sending_successful')
    else
      flash.now[:alert] = t('emails.submit.sending_failed')
      @send_generic = true
      render :email
    end
  end

  def save_template
    @email = Email.new(email_params)

    @template = EmailTemplate.new({ status: get_status, hide_recipients: @email.hide_recipients,
                                    subject: @email.subject, content: @email.content })

    if @email.validates_presence_of(:subject, :content) && @template.save
      flash.now[:success] = t('emails.submit.saving_successful')
    else
      flash.now[:alert] = t('emails.submit.saving_failed')
    end
    @event = Event.find(params[:event_id])
    @templates = EmailTemplate.with_status(get_status)

    @send_generic = false
    render :email
  end

  def update_event(event)
    status = get_status
    if status == :acceptance
      event.set_status_notification_flag_for_applications_with_status(:accepted)
      event.acceptances_have_been_sent = true
      if not (event.has_participants_without_status_notification?(:rejected) || @event.has_participants_without_status_notification?(:alternative))
        event.rejections_have_been_sent = true
      end
    elsif get_status == :rejection
      event.rejections_have_been_sent = true
      event.set_status_notification_flag_for_applications_with_status(:rejected)
      event.set_status_notification_flag_for_applications_with_status(:alternative)
    end
    event.save
  end

  def get_status
    params[:status] ? params[:status].to_sym : :default
  end

  # Only allow a trusted parameter "white list" through.
  def email_params
    params.require(:email).permit(:hide_recipients, :recipients, :reply_to, :subject, :content)
  end
end
