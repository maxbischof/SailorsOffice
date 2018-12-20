require "rails_helper"

feature "User signs in" do
	scenario "successfully" do
		create_user
		sign_in
		expect(page).to have_css 'h2', text: 'Current Regattas'   
	end
end
