# frozen_string_literal: true

module DiscourseAnimatedAvatars
  class Engine < ::Rails::Engine
    engine_name "discourse-animated-avatars"
    isolate_namespace DiscourseAnimatedAvatars
    config.autoload_paths << File.join(config.root, "lib")
  end
end
