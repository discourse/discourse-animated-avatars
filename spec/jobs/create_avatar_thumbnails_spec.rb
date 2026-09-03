# frozen_string_literal: true

RSpec.describe Jobs::CreateAvatarThumbnails do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|webp"
    SiteSetting.animated_gif_avatar_to_webp = false
  end

  it "generates static PNG thumbnails for animated WebP avatars" do
    webp_path = File.expand_path("../fixtures/images/animated.webp", __dir__)
    webp = Tempfile.new(%w[animated .webp])
    IO.copy_stream(webp_path, webp)
    webp.rewind

    upload = UploadCreator.new(webp, "animated_avatar.webp", type: "avatar").create_for(user.id)
    expect(upload.animated).to eq(true)

    Discourse.avatar_sizes.each do |size|
      OptimizedImage.create_for(upload, size, size, format: "png")
    end

    png_thumbnails = upload.optimized_images.where(extension: ".png")
    expect(png_thumbnails.count).to be > 0

    png_thumbnails.each do |optimized_image|
      path = Discourse.store.path_for(optimized_image)
      expect(FastImage.type(path)).to eq(:png),
      "Thumbnail #{optimized_image.width}x#{optimized_image.height} file should be PNG"
      expect(FastImage.animated?(path)).to be_falsy,
      "Thumbnail #{optimized_image.width}x#{optimized_image.height} should be static"
    end
  end

  it "generates static PNG thumbnails for animated GIF avatars" do
    upload =
      UploadCreator.new(
        file_from_fixtures("animated.gif"),
        "animated_avatar.gif",
        type: "avatar",
      ).create_for(user.id)
    expect(upload.animated).to eq(true)
    expect(upload.extension).to eq("gif")

    Discourse.avatar_sizes.each do |size|
      OptimizedImage.create_for(upload, size, size, format: "png")
    end

    png_thumbnails = upload.optimized_images.where(extension: ".png")
    expect(png_thumbnails.count).to be > 0

    png_thumbnails.each do |optimized_image|
      path = Discourse.store.path_for(optimized_image)
      expect(FastImage.type(path)).to eq(:png),
      "Thumbnail #{optimized_image.width}x#{optimized_image.height} file should be PNG"
      expect(FastImage.animated?(path)).to be_falsy,
      "Thumbnail #{optimized_image.width}x#{optimized_image.height} should be static"
    end
  end
end
