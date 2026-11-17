# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorAnimatedAvatarExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    SiteSetting.avatar_sizes = "120"
  end

  def fixture_path(name)
    File.expand_path("../fixtures/images/#{name}", __dir__)
  end

  it "resizes a non-square animated WebP avatar to a square" do
    webp = Tempfile.new(%w[nonsquare .webp])
    IO.copy_stream(fixture_path("nonsquare_animated.webp"), webp)
    webp.rewind

    upload =
      UploadCreator.new(
        webp,
        "nonsquare_animated.webp",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.animated).to eq(true)
    w, h = FastImage.size(Discourse.store.path_for(upload))
    expect([w, h]).to eq([120, 120])
    expect(FastImage.animated?(Discourse.store.path_for(upload))).to eq(true)
  end

  it "resizes an animated GIF avatar in place" do
    SiteSetting.animated_gif_avatar_to_webp = false

    upload =
      UploadCreator.new(
        file_from_fixtures("animated.gif"),
        "animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("gif")
    expect(upload.animated).to eq(true)
    expect(FastImage.size(Discourse.store.path_for(upload))).to eq([120, 120])
    expect(FastImage.animated?(Discourse.store.path_for(upload))).to eq(true)
  end

  it "converts and resizes an animated GIF avatar to WebP" do
    SiteSetting.animated_gif_avatar_to_webp = true

    upload =
      UploadCreator.new(
        file_from_fixtures("animated.gif"),
        "animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("webp")
    stored_path = Discourse.store.path_for(upload)
    expect(FastImage.type(stored_path)).to eq(:webp)
    expect(FastImage.size(stored_path)).to eq([120, 120])
    expect(FastImage.animated?(stored_path)).to eq(true)
  end

  it "uses the configured quality for the converted WebP avatar" do
    SiteSetting.animated_gif_avatar_to_webp = true

    uploads =
      [10, 95].map do |quality|
        SiteSetting.animated_gif_avatar_webp_quality = quality
        UploadCreator.new(
          file_from_fixtures("animated.gif"),
          "animated.gif",
          type: "avatar",
          force_optimize: true,
        ).create_for(user.id)
      end

    expect(uploads).to all(be_persisted)
    expect(uploads.first.filesize).to be < uploads.last.filesize
  end

  it "preserves the GIF format for an animated image outside an avatar upload" do
    upload =
      UploadCreator.new(file_from_fixtures("animated.gif"), "animated.gif").create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("gif")
  end
end
