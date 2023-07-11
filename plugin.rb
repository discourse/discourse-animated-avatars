# frozen_string_literal: true
# name: discourse-animated-avatars
# about: This plugin adds support for animated avatars
# version: 0.1
# url: https://github.com/discourse/discourse-animated-avatars

after_initialize do
  reloadable_patch do
    gifsicle_installed =
      begin
        Discourse::Utils.execute_command(
          "gifsicle",
          "--version",
          "&>",
          "/dev/null",
          failure_message: "gifsicle not found",
        )
        true
      rescue StandardError
        false
      end

    # new crop functions if gifsicle is installed
    if gifsicle_installed
      class ::UploadCreator
        alias_method :crop_orig!, :crop!
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
            crop_orig!
          end
        end
      end
    else
      # fallback if no gifsicle, no cropping for animated avatars
      class ::UploadCreator
        alias_method :should_crop_orig?, :should_crop?
        def should_crop?
          return false if ["avatar"].include?(@opts[:type]) && animated?
          should_crop_orig?
        end
        alias_method :crop_orig!, :crop!
      end
    end

    class ::OptimizedImage
      def self.resize_animated(from, to, width, height, opts = {})
        optimize("resize_animated", from, to, "#{width}x#{height}", opts)
      end
      def self.resize_animated_instructions(from, to, dimensions, opts = {})
        ensure_safe_paths!(from, to)
        resize_method = opts[:scale_image] ? "scale" : "resize-fit"

        instructions = %W[gifsicle --colors=#{opts[:colors] || 256}]

        instructions << "--crop" << opts[:crop] if opts[:crop]

        instructions.concat(
          %W[--#{resize_method} #{dimensions} --optimize=3 --output #{to} #{from}],
        )
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
    pass_tl_check = staff? || trust_level >= SiteSetting.animated_avatars_min_trust_level_to_display
    uploaded_avatar&.url if uploaded_avatar&.animated? && pass_tl_check
  end

  add_to_serializer(:basic_user, :animated_avatar) do
    user.try(:animated_avatar)
  rescue StandardError
    nil
  end
  add_to_serializer(:post, :animated_avatar) do
    object.user.try(:animated_avatar)
  rescue StandardError
    nil
  end
end

Discourse::Application.routes.append do
  get "user_avatar/:hostname/:username/:size/:version.gif" => "user_avatars#show",
      :constraints => {
        hostname: /[\w\.-]+/,
        size: /\d+/,
        username: RouteFormat.username,
        format: :gif,
      }
end
