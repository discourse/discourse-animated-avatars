# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorAnimatedWebpExtension
    extend ActiveSupport::Concern

    def crop!
      if @opts[:type] == "avatar" && @image_info.type.to_s == "webp" && animated?
        width = height = Discourse.avatar_sizes.max
        original_size_squared = @image_info.size.min
        OptimizedImage.resize_animated_webp(
          @file.path,
          @file.path,
          width,
          height,
          crop_size: original_size_squared,
        )
        extract_image_info!
      else
        super
      end
    end
  end
end
