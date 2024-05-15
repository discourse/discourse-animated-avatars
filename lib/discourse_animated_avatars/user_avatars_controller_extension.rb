# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UserAvatarsControllerExtension
    extend ActiveSupport::Concern

    def get_optimized_image(upload, size)
      return upload if (upload.extension == "gif" && request.format == "image/gif")
      super
    end
  end
end
