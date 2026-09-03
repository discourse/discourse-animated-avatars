# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UserAvatarsControllerExtension
    extend ActiveSupport::Concern

    def get_optimized_image(upload, size)
      return super unless upload.animated? && %w[gif webp].include?(upload.extension)
      return upload if request.format == "image/#{upload.extension}"
      # Force PNG so the .png avatar URL serves an actual PNG file — core's resize uses [0]
      # (first frame), guaranteeing the thumbnail is static regardless of source format.
      upload.get_optimized_image(size, size, format: "png")
    end
  end
end
