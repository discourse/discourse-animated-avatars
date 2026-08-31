# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorNoGifsicleExtension
    extend ActiveSupport::Concern

    def should_crop?
      return false if @opts[:type] == "avatar" && @image_info.type.to_s == "gif" && animated?
      super
    end
  end
end
