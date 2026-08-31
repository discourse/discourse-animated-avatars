# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::UploadCreatorAnimatedApngExtension do
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

  it "skips cropping an animated APNG avatar to preserve the full animation" do
    apng = Tempfile.new(%w[nonsquare .png])
    IO.copy_stream(fixture_path("nonsquare_animated.apng"), apng)
    apng.rewind

    upload =
      make_creator(apng, "nonsquare_animated.png", type: "avatar", force_optimize: true).create_for(
        user.id,
      )

    expect(upload).to be_persisted
    expect(upload.animated).to eq(true)

    stored_path = Discourse.store.path_for(upload)
    w, h = FastImage.size(stored_path)
    expect(w).not_to eq(h), "APNG upload should not be cropped to a square"
  end

  it "does not skip cropping a static PNG avatar" do
    upload =
      make_creator(
        file_from_fixtures("logo.png"),
        "logo.png",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)

    expect(upload).to be_persisted
    expect(upload.animated).not_to eq(true)
  end
end
