# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorGifsicleExtension
    extend ActiveSupport::Concern

    def crop!
      filename_with_correct_ext = "image.#{@image_info.type}"
      if @opts[:type] == "avatar"
        width = height = Discourse.avatar_sizes.max

        # Center crop
        original_size_squared = @image_info.size.min
        start_x = (@image_info.size[0] - original_size_squared) / 2
        start_y = (@image_info.size[1] - original_size_squared) / 2
        crop = "#{start_x},#{start_y}+#{original_size_squared}" # Gifsicle crop args

        OptimizedImage.resize_animated(
          @file.path,
          @file.path,
          width,
          height,
          filename: filename_with_correct_ext,
          crop: crop,
        )
      else
        super
      end
    end
  end
end
