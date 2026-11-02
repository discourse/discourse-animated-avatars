# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorAnimatedAvatarExtension do
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

  it "resizes a non-square animated WebP avatar to a square" do
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
    w, h = FastImage.size(Discourse.store.path_for(upload))
    expect(w).to eq(h)
  end

  it "resizes an animated GIF avatar in place" do
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
end
