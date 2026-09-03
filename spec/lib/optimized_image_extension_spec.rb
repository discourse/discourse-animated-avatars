# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::OptimizedImageExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    SiteSetting.animated_gif_avatar_to_webp = false
  end

  def fixture_path(name)
    File.expand_path("../fixtures/images/#{name}", __dir__)
  end

  describe "PNG thumbnail generation for animated uploads (served at .png avatar URLs)" do
    it "generates a static PNG thumbnail for an animated WebP upload" do
      webp = Tempfile.new(%w[animated .webp])
      IO.copy_stream(fixture_path("animated.webp"), webp)
      webp.rewind

      upload = UploadCreator.new(webp, "animated.webp", type: "avatar").create_for(user.id)
      expect(upload.animated).to eq(true)

      thumbnail = OptimizedImage.create_for(upload, 120, 120, format: "png")
      expect(thumbnail).to be_present

      path = Discourse.store.path_for(thumbnail)
      expect(FastImage.type(path)).to eq(:png)
      expect(FastImage.animated?(path)).to be_falsy
    end

    it "generates a static PNG thumbnail for an animated GIF upload" do
      upload =
        UploadCreator.new(
          file_from_fixtures("animated.gif"),
          "animated.gif",
          type: "avatar",
        ).create_for(user.id)
      expect(upload.animated).to eq(true)

      thumbnail = OptimizedImage.create_for(upload, 120, 120, format: "png")
      expect(thumbnail).to be_present

      path = Discourse.store.path_for(thumbnail)
      expect(FastImage.type(path)).to eq(:png)
      expect(FastImage.animated?(path)).to be_falsy
    end
  end
end
