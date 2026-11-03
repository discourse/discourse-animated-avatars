# frozen_string_literal: true

module PageObjects
  module Pages
    class AnimatedAvatarProfile < PageObjects::Pages::User
      def has_webp_avatar?
        has_css?(".user-profile-avatar img.avatar[src$='.webp']") do |avatar|
          avatar.evaluate_script("this.complete && this.naturalWidth === 120")
        end
      end
    end
  end
end
