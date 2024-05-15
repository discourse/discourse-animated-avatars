# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module UploadCreatorNoGifsicleExtension
    extend ActiveSupport::Concern

    def should_crop?
      return false if ["avatar"].include?(@opts[:type]) && animated?
      super
    end
  end
end
