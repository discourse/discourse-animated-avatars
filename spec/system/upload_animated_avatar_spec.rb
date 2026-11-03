# frozen_string_literal: true

RSpec.describe "Uploading an animated avatar" do
  fab!(:user) { Fabricate(:user, trust_level: 4, refresh_auto_groups: true) }

  let(:account_preferences) { PageObjects::Pages::UserPreferencesAccount.new }
  let(:avatar_selector) { PageObjects::Modals::AvatarSelector.new }
  let(:profile) { PageObjects::Pages::AnimatedAvatarProfile.new }

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|webp|png"
    SiteSetting.animated_gif_avatar_to_webp = true
    SiteSetting.avatar_sizes = "120"
    allow(UploadCreator).to receive(:new).and_wrap_original do |original, file, filename, opts|
      original.call(file, filename, opts.merge(force_optimize: true))
    end
    sign_in(user)
  end

  it "lets a user convert a GIF avatar to WebP and keep it after refreshing" do
    account_preferences.open_avatar_selector_modal(user)
    avatar_selector.upload_image(file_from_fixtures("animated.gif").path)
    expect(avatar_selector).to have_custom_picture_selected
    avatar_selector.click_primary_button
    expect(avatar_selector).to be_closed

    profile.visit(user)
    profile.expand_info_panel
    expect(profile).to have_webp_avatar

    page.refresh
    expect(profile).to have_webp_avatar
  end
end
