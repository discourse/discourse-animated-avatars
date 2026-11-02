# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorAnimatedAvatarExtension
    extend ActiveSupport::Concern

    def crop!
      return super unless @opts[:type] == "avatar" && animated?
      size = Discourse.avatar_sizes.max

      # libvips animated image thumbnail cropping is bugged as of v8.18.
      # Just force resize without cropping
      DiscourseVips.thumbnail(
        input_path: @file.path,
        output_path: @file.path,
        width: size,
        height: size,
        size: :force,
        animated: true,
        output_format: @image_info.type.to_s,
        operation: :upload_animated_avatar,
        timeout: OptimizedImage::MAX_CONVERT_SECONDS,
      )
      extract_image_info!
    rescue => error
      Discourse.warn_exception(
        error,
        message: "Failed to resize animated avatar, uploading without crop",
      )
    end
  end
end
