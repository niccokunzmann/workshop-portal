require "rails_helper"

RSpec.feature "Event participants overview", :type => :feature do
  before :each do
    @event = FactoryGirl.create(:event)
  end

  scenario "logged in as Organizer I can sucessfully select a group for a participant", js: true do
    login(:organizer)
    @user = FactoryGirl.create(:user)
    @profile = FactoryGirl.create(:profile, user: @user)
    @application_letter = FactoryGirl.create(:application_letter_accepted, user: @user, event: @event)
    @participant_group = FactoryGirl.create(:participant_group, application_letter: @application_letter)
    visit "/events/#{@event.id}/participants"
    select I18n.t("participant_groups.options.#{ParticipantGroup::GROUPS[9]}"), from: 'participant_group_group'
    expect(page).to have_text(I18n.t("participant_groups.update.successful"))
  end

  scenario "logged in as Coach I can see a table with the participants and sort them by group" do
    login(:organizer)
    for i in 1..5
      user = FactoryGirl.create(:user)
      profile = FactoryGirl.create(:profile, user: user, last_name: i.to_s)
      application_letter = FactoryGirl.create(:application_letter_accepted, user: user, event: @event)
      participant_group = FactoryGirl.create(:participant_group, application_letter: application_letter, group: i)
    end

    visit "/events/#{@event.id}/participants"

    table = page.find('table')
    @event.participants.each do |participant|
      expect(table).to have_text(participant.profile.name)
    end

    link_name = I18n.t("activerecord.attributes.participant_group.group")
    click_link link_name
    sorted_by_group = @event.participants.sort_by {|p| @event.participant_group_for(p).send("group") }
    names = sorted_by_group.map {|p| p.profile.name }
    expect(page).to contain_ordered(names)

    click_link link_name # again
    expect(page).to contain_ordered(names.reverse)
  end


  def login(role)
    @profile = FactoryGirl.create(:profile)
    @profile.user.role = role
    login_as(@profile.user, :scope => :user)
  end
end
