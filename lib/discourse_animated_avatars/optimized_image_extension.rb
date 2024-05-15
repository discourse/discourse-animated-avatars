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
    end
  end
end
