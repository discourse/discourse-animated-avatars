# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorGifsicleExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    SiteSetting.animated_gif_avatar_to_webp = false
  end

  def make_creator(file, filename, opts = {})
    klass = Class.new(UploadCreator)
    klass.prepend(described_class)
    klass.new(file, filename, opts)
  end

  it "successfully uploads a non-GIF avatar without invoking gifsicle (regression)" do
    upload =
      make_creator(
        file_from_fixtures("logo.png"),
        "logo.png",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
  end

  it "successfully uploads a non-GIF image that is not an avatar" do
    upload = make_creator(file_from_fixtures("logo.png"), "logo.png").create_for(user.id)

    expect(upload).to be_persisted
  end

  it "successfully uploads an animated GIF avatar when gifsicle is installed" do
    skip "gifsicle not installed" unless system("which gifsicle > /dev/null 2>&1")

    upload =
      make_creator(file_from_fixtures("animated.gif"), "animated.gif", type: "avatar").create_for(
        user.id,
      )

    expect(upload).to be_persisted
    expect(upload.animated).to eq(true)
  end

  it "resizes and crops an animated GIF avatar while preserving animation" do
    skip "gifsicle not installed" unless system("which gifsicle > /dev/null 2>&1")
    SiteSetting.avatar_sizes = "20"

    upload =
      UploadCreator.new(
        file_from_fixtures(
          "nonsquare_animated.gif",
          "images",
          DiscourseAnimatedAvatars::Engine.root.join("spec/fixtures"),
        ),
        "nonsquare_animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.extension).to eq("gif")

    stored_path = Discourse.store.path_for(upload)
    expect(FastImage.size(stored_path)).to eq([20, 20])
    expect(FastImage.animated?(stored_path)).to eq(true)
  end
end

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorNoGifsicleExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    SiteSetting.animated_gif_avatar_to_webp = false
  end

  def make_creator(file, filename, opts = {})
    klass = Class.new(UploadCreator)
    klass.prepend(described_class)
    klass.new(file, filename, opts)
  end

  it "skips cropping an animated GIF avatar to preserve animation" do
    upload =
      make_creator(
        file_from_fixtures("animated.gif"),
        "animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.animated).to eq(true)

    # should_crop? returns false for animated avatars, so the stored file
    # keeps its original dimensions rather than being cropped to avatar_sizes.max
    stored_path = Discourse.store.path_for(upload)
    w, _h = FastImage.size(stored_path)
    expect(w).not_to eq(Discourse.avatar_sizes.max)
  end

  it "successfully uploads a non-animated image as an avatar" do
    upload =
      make_creator(file_from_fixtures("logo.png"), "logo.png", type: "avatar").create_for(user.id)

    expect(upload).to be_persisted
  end
end
