# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UserAvatarsControllerExtension
    extend ActiveSupport::Concern

    def get_optimized_image(upload, size)
      return upload if upload.extension == "gif" && request.format == "image/gif"
      return upload if upload.extension == "webp" && upload.animated? && request.format == "image/webp"
      return upload if upload.extension == "png" && upload.animated? && request.format == "image/apng"
      super
    end
  end
end
