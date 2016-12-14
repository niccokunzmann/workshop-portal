class Mailer
  def send_generic_email(hide_recipients, recipients, reply_to, subject, content)
    if hide_recipients
      recipients.each do |recipient|
        PortalMailer.generic_email(recipient, reply_to, subject, content).deliver_now
      end
    else
      PortalMailer.generic_email(recipients, reply_to, subject, content).deliver_now
    end
  end
end