# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorAnimatedAvatarExtension
    extend ActiveSupport::Concern

    def crop!
      return super unless @opts[:type] == "avatar" && animated?
      convert_to_webp = @image_info.type.to_s == "gif" && SiteSetting.animated_gif_avatar_to_webp
      webp = Tempfile.new(%w[animated_avatar .webp]) if convert_to_webp
      size = Discourse.avatar_sizes.max

      # libvips animated image thumbnail cropping is bugged as of v8.18.
      # Just force resize without cropping
      DiscourseVips.thumbnail(
        input_path: @file.path,
        output_path: webp ? webp.path : @file.path,
        width: size,
        height: size,
        size: :force,
        animated: true,
        output_format: convert_to_webp ? "webp" : @image_info.type.to_s,
        quality: convert_to_webp ? SiteSetting.animated_gif_avatar_webp_quality : nil,
        operation: :upload_animated_avatar,
        timeout: OptimizedImage::MAX_CONVERT_SECONDS,
      )
      if webp
        @file.respond_to?(:close!) ? @file.close! : @file.close
        @file = webp
        @filename = @filename.sub(/\.gif$/i, ".webp")
      end
      extract_image_info!
    rescue => error
      webp&.close!
      Discourse.warn_exception(
        error,
        message: "Failed to process animated avatar, uploading original",
      )
    end
  end
end
