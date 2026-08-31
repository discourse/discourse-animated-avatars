# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorAnimatedApngExtension
    extend ActiveSupport::Concern

    def should_crop?
      # ImageMagick reads only frame 0 from APNG (treats it as plain PNG), so cropping
      # the upload in-place would destroy the animation in the stored file.
      return false if @opts[:type] == "avatar" && @image_info.type.to_s == "png" && animated?
      super
    end
  end
end
