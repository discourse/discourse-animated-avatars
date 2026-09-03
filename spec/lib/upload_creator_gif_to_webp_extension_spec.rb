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

  def fixture_path(name)
    File.expand_path("../fixtures/images/#{name}", __dir__)
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

  it "center-crops a non-square animated GIF avatar to a square WebP" do
    gif = Tempfile.new(%w[nonsquare .gif])
    IO.copy_stream(fixture_path("nonsquare_animated.gif"), gif)
    gif.rewind

    upload =
      make_creator(gif, "nonsquare_animated.gif", type: "avatar", force_optimize: true).create_for(
        user.id,
      )

    expect(upload).to be_persisted
    expect(upload.extension).to eq("webp")
    expect(upload.animated).to eq(true)

    stored_path = Discourse.store.path_for(upload)
    w, h = FastImage.size(stored_path)
    expect(w).to eq(h)
  end

  it "does not convert when animated_gif_avatar_to_webp is disabled" do
    SiteSetting.animated_gif_avatar_to_webp = false

    upload =
      make_creator(
        file_from_fixtures("animated.gif"),
        "animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("gif")
    expect(upload.animated).to eq(true)
  end

  it "does not convert a non-avatar animated GIF" do
    upload = make_creator(file_from_fixtures("animated.gif"), "animated.gif").create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("gif")
  end
end
