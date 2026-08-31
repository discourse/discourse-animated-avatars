# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorAnimatedWebpExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
  end

  def make_creator(file, filename, opts = {})
    klass = Class.new(UploadCreator)
    klass.prepend(described_class)
    klass.new(file, filename, opts)
  end

  def fixture_path(name)
    File.expand_path("../fixtures/images/#{name}", __dir__)
  end

  it "crops a non-square animated WebP avatar to a square" do
    webp = Tempfile.new(%w[nonsquare .webp])
    IO.copy_stream(fixture_path("nonsquare_animated.webp"), webp)
    webp.rewind

    upload =
      make_creator(
        webp,
        "nonsquare_animated.webp",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.animated).to eq(true)

    stored_path = Discourse.store.path_for(upload)
    w, h = FastImage.size(stored_path)
    expect(w).to eq(h)
  end

  it "successfully uploads an animated WebP avatar" do
    webp = Tempfile.new(%w[animated .webp])
    IO.copy_stream(fixture_path("animated.webp"), webp)
    webp.rewind

    upload =
      make_creator(webp, "animated.webp", type: "avatar", force_optimize: true).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.animated).to eq(true)
  end
end
