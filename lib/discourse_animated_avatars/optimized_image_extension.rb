# frozen_string_literal: true

module DiscourseAnimatedAvatars
  module OptimizedImageExtension
    extend ActiveSupport::Concern

    class_methods do
      def resize_animated(from, to, width, height, opts = {})
        optimize("resize_animated", from, to, "#{width}x#{height}", opts)
      end

      def resize_animated_instructions(from, to, dimensions, opts = {})
        ensure_safe_paths!(from, to)
        resize_method = opts[:scale_image] ? "scale" : "resize-fit"

        instructions = %W[gifsicle --colors=#{opts[:colors] || 256}]

        instructions << "--crop" << opts[:crop] if opts[:crop]

        instructions.concat(
          %W[--#{resize_method} #{dimensions} --optimize=3 --output #{to} #{from}],
        )
      end

      # Override resize to preserve animation for GIFs
      def resize(from, to, width, height, opts = {})
        if opts[:upload_id]
          upload = Upload.find_by(id: opts[:upload_id])
          return resize_animated(from, to, width, height, opts) if upload&.extension == "gif"
        end
        super
      end
    end
  end
end
