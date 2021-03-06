require 'rails_helper'

RSpec.describe "application_letters/edit", type: :view do
  before(:each) do
    @event = assign(:event, FactoryGirl.create(:event))
    @application_letter = assign(:application_letter, FactoryGirl.create(:application_letter, :event_id => @event.id))
  end

  it "renders the edit application form" do
    render

    assert_select "form[action=?][method=?]", application_letter_path(@application_letter), "post" do
      assert_select "textarea#application_letter_motivation[name=?]", "application_letter[motivation]"
      assert_select "textarea#application_letter_annotation[name=?]", "application_letter[annotation]"
      assert_select "input#custom_application_fields_", count: @application_letter.event.custom_application_fields.count
      @application_letter.event.custom_application_fields.each { |field_name|
        assert_select "label.control-label[for=custom_application_fields_]", field_name
      }
    end
  end

  it "renders a warning when the application deadline is over" do
    @application_letter = assign(:application_letter, FactoryGirl.build(:application_letter, :deadline_over))
    render
    expect(rendered).to have_content(I18n.t("application_letters.form.warning"))
  end

  it "renders a disabled submit button" do
    @application_letter = assign(:application_letter, FactoryGirl.create(:application_letter))
    @application_letter.event.application_deadline = Date.yesterday
    render
    expect(rendered).to have_button(I18n.t("helpers.submit.update", model: ApplicationLetter.model_name.human), disabled: true)
  end
end
