# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module OptimizedImageExtension
    extend ActiveSupport::Concern

    class_methods do
      def resize_animated_gif(from, to, width, height, opts = {})
        instructions = resize_animated_gif_instructions(from, to, "#{width}x#{height}", opts)
        Discourse::Utils.execute_command(*instructions)
      end

      def resize_animated_gif_instructions(from, to, dimensions, opts = {})
        ensure_safe_paths!(from, to)
        resize_method = opts[:scale_image] ? "scale" : "resize-fit"

        instructions = %W[gifsicle --colors=#{opts[:colors] || 256}]

        instructions << "--crop" << opts[:crop] if opts[:crop]

        instructions.concat(
          %W[--#{resize_method} #{dimensions} --optimize=3 --output #{to} #{from}],
        )
      end

      def resize_animated_webp(from, to, width, height, opts = {})
        ensure_safe_paths!(from, to)
        instructions = [from, "-coalesce"]

        if (crop_size = opts[:crop_size])
          instructions.concat(
            ["-gravity", "Center", "-crop", "#{crop_size}x#{crop_size}+0+0", "+repage"],
          )
        end

        instructions.concat(
          %W[
            -gravity
            center
            -#{thumbnail_or_resize}
            #{width}x#{height}^
            -extent
            #{width}x#{height}
            -layers
            optimize
            #{to}
          ],
        )

        ImageMagick.magick(
          *instructions,
          operation: :animated_webp_resize,
          read: [from],
          write: [File.dirname(to)],
          nice: 10,
          timeout: OptimizedImage::MAX_CONVERT_SECONDS,
        )
      end

      # Override resize to preserve animation for GIFs and animated WebP.
      # APNG thumbnails are intentionally first-frame only (super handles them correctly).
      def resize(from, to, width, height, opts = {})
        if (upload = Upload.find_by(id: opts[:upload_id]))
          resize_method =
            if upload.extension == "gif"
              :resize_animated_gif
            elsif upload.extension == "webp" && upload.animated?
              :resize_animated_webp
            end

          if resize_method
            begin
              return send(resize_method, from, to, width, height, opts)
            rescue => e
              Rails.logger.warn(
                "#{resize_method} failed for upload #{opts[:upload_id]}, falling back to ImageMagick: #{e.message}",
              )
            end
          end
        end
        super
      end
    end
  end
end
