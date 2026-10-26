# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars do
  fab!(:user)

  context "when ImageMagick is unavailable" do
    before do
      enable_current_plugin
      SiteSetting.authorized_extensions = "gif|webp|png"
      allow(ImageMagick).to receive(:magick).and_raise(
        Errno::ENOENT.new("No such file or directory - magick"),
      )
    end

    def fixture_path(name)
      File.expand_path("../fixtures/images/#{name}", __dir__)
    end

    it "uploads an animated WebP avatar at original dimensions when resize fails" do
      webp = Tempfile.new(%w[animated .webp])
      IO.copy_stream(fixture_path("animated.webp"), webp)
      webp.rewind

      upload =
        UploadCreator.new(webp, "animated.webp", type: "avatar", force_optimize: true).create_for(
          user.id,
        )

      expect(upload).to be_persisted
      expect(upload.animated).to eq(true)
      expect(FastImage.animated?(Discourse.store.path_for(upload))).to eq(true)
    end

    it "preserves the original animated GIF when WebP conversion fails" do
      SiteSetting.animated_gif_avatar_to_webp = true

      upload =
        UploadCreator.new(
          file_from_fixtures("animated.gif"),
          "animated.gif",
          type: "avatar",
          force_optimize: true,
        ).create_for(user.id)

      expect(upload).to be_persisted
      expect(upload.animated).to eq(true)
      expect(upload.extension).to eq("gif")
      expect(FastImage.animated?(Discourse.store.path_for(upload))).to eq(true)
    end

    it "uploads a non-square animated WebP avatar without cropping when resize fails" do
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
      expect(FastImage.animated?(Discourse.store.path_for(upload))).to eq(true)
    end

    it "preserves a non-square animated GIF when WebP conversion fails" do
      SiteSetting.animated_gif_avatar_to_webp = true

      gif = Tempfile.new(%w[nonsquare .gif])
      IO.copy_stream(fixture_path("nonsquare_animated.gif"), gif)
      gif.rewind

      upload =
        UploadCreator.new(
          gif,
          "nonsquare_animated.gif",
          type: "avatar",
          force_optimize: true,
        ).create_for(user.id)

      expect(upload).to be_persisted
      expect(upload.animated).to eq(true)
      expect(upload.extension).to eq("gif")
      expect(FastImage.animated?(Discourse.store.path_for(upload))).to eq(true)
    end
  end
end
