# frozen_string_literal: true
# name: animated-avatars
# about: This plugin adds support for animated avatars
# version: 0.1
# url: https://github.com/featheredtoast/discourse-animated-avatars

after_initialize do
  reloadable_patch do
    class ::UploadCreator
      alias_method :should_crop_orig?, :should_crop?
      def should_crop?
        return false if ['avatar'].include?(@opts[:type]) && animated?
        should_crop_orig?
      end
    end
    class ::UserAvatarsController
      alias_method :get_optimized_image_orig, :get_optimized_image
      def get_optimized_image(upload, size)
        return upload if (upload.extension == "gif" && request.format == "image/gif")
        get_optimized_image_orig(upload, size)
      end
    end
  end
  add_to_class(:user, :animated_avatar) do
    uploaded_avatar&.url if uploaded_avatar&.animated?
  end

  add_to_serializer(:basic_user, :animated_avatar) do
    user.try(:animated_avatar)
  end
end

Discourse::Application.routes.append do
  get "user_avatar/:hostname/:username/:size/:version.gif" => "user_avatars#show", constraints: { hostname: /[\w\.-]+/, size: /\d+/, username: RouteFormat.username, format: :gif }
end
