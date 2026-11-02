# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorGifToWebpExtension
    extend ActiveSupport::Concern

    def should_crop?
      return true if animated_gif_avatar?
      super
    end

    def crop!
      return super unless animated_gif_avatar?
      return super unless SiteSetting.animated_gif_avatar_to_webp

      webp = Tempfile.new(%w[gif_to_webp .webp])

      DiscourseVips.gif_to_webp(
        input_path: @file.path,
        output_path: webp.path,
        quality: SiteSetting.animated_gif_avatar_webp_quality,
        timeout: OptimizedImage::MAX_CONVERT_SECONDS,
      )

      @file.respond_to?(:close!) ? @file.close! : @file.close
      @file = webp
      @filename = @filename.sub(/\.gif$/i, ".webp")
      extract_image_info!
      super
    rescue => error
      webp&.close!
      Discourse.warn_exception(
        error,
        message: "Failed to convert animated GIF to WebP, uploading original",
      )
    end

    private

    def animated_gif_avatar?
      @opts[:type] == "avatar" && @image_info.type.to_s == "gif" && animated?
    end
  end
end
