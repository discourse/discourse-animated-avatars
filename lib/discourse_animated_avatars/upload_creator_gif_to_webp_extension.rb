# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorGifToWebpExtension
    extend ActiveSupport::Concern

    def should_crop?
      # When conversion is enabled, return true so crop! fires even when gifsicle
      # is absent (UploadCreatorNoGifsicleExtension would otherwise return false).
      return true if should_convert_animated_gif?
      super
    end

    def crop!
      return super unless should_convert_animated_gif?

      webp = Tempfile.new(%w[gif_to_webp .webp])

      OptimizedImage.resize_animated_webp(
        @file.path,
        webp.path,
        Discourse.avatar_sizes.max,
        Discourse.avatar_sizes.max,
        crop_size: @image_info.size.min,
        quality: SiteSetting.animated_gif_avatar_webp_quality,
      )

      @file.respond_to?(:close!) ? @file.close! : @file.close
      @file = webp
      @filename = @filename.sub(/\.gif$/i, ".webp")
      extract_image_info!
    end

    private

    def should_convert_animated_gif?
      SiteSetting.animated_gif_avatar_to_webp && @opts[:type] == "avatar" &&
        @image_info.type.to_s == "gif" && animated?
    end
  end
end
