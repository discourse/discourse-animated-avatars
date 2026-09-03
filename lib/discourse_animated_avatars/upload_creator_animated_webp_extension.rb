# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorAnimatedWebpExtension
    extend ActiveSupport::Concern

    def crop!
      return super unless @opts[:type] == "avatar" && @image_info.type.to_s == "webp" && animated?
      size = Discourse.avatar_sizes.max
      OptimizedImage.resize_animated_webp(
        @file.path,
        @file.path,
        size,
        size,
        crop_size: @image_info.size.min,
      )
      extract_image_info!
    end
  end
end
