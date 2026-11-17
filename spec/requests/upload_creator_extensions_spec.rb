# frozen_string_literal: true

RSpec.describe "animated avatars upload API" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }

  before do
    enable_current_plugin
    sign_in(user)
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
  end

  it "uploads a static PNG avatar without interference from animated avatar extensions" do
    post "/uploads.json",
         params: {
           file: Rack::Test::UploadedFile.new(file_from_fixtures("logo.png")),
           upload_type: "avatar",
         }

    expect(response.status).to eq(200), response.body
    expect(response.parsed_body["id"]).to be_present
  end
end
