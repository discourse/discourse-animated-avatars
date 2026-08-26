# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorGifsicleExtension do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }

  before do
    enable_current_plugin
    sign_in(user)
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    allow(Rails.env).to receive(:test?).and_return(false)
  end

  around do |example|
    original_upload_creator = UploadCreator
    stub_const(Object, :UploadCreator, Class.new(original_upload_creator)) do
      UploadCreator.prepend(described_class)
      example.run
    end
  end

  it "uploads PNG avatars through the uploads API" do
    post "/uploads.json",
         params: {
           file: Rack::Test::UploadedFile.new(file_from_fixtures("logo.png")),
           upload_type: "avatar",
         }

    expect(response.status).to eq(200), response.body
    expect(response.parsed_body["id"]).to be_present
  end
end
