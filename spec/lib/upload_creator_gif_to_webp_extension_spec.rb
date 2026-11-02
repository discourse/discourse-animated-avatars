# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorGifToWebpExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    SiteSetting.animated_gif_avatar_to_webp = true
  end

  def make_creator(file, filename, opts = {})
    klass = Class.new(UploadCreator)
    klass.prepend(described_class)
    klass.new(file, filename, opts)
  end

  it "converts an animated GIF avatar to WebP" do
    upload =
      make_creator(
        file_from_fixtures("animated.gif"),
        "animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("webp")
    expect(upload.animated).to eq(true)
  end

  it "does not convert a non-avatar animated GIF" do
    upload = make_creator(file_from_fixtures("animated.gif"), "animated.gif").create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("gif")
  end
end
