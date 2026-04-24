# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::CreateAvatarThumbnails do
  fab!(:user)

  let(:animated_gif_path) { "#{Rails.root}/spec/fixtures/images/animated.gif" }

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif"
  end

  it "preserves animation in optimized avatar images" do
    file = File.open(animated_gif_path)
    upload = UploadCreator.new(
      file,
      "animated_avatar.gif",
      type: "avatar",
      for_user: user,
    ).create_for(user.id)
    file.close

    expect(upload).to be_persisted, "Upload failed: #{upload.errors.full_messages.join(', ')}"
    expect(upload.animated?).to eq(true)

    # create optimized images
    Discourse.avatar_sizes.each do |size|
      result = OptimizedImage.create_for(upload, size, size)
      puts "Created optimized image #{size}x#{size}: #{result.inspect}" if result.nil?
    end

    upload.reload

    # Verify at least one optimized image exists
    expect(upload.optimized_images.count).to be > 0,
      "No optimized images were created. Check ImageMagick command."

    # Check that optimized images preserve animation (multiple frames)
    upload.optimized_images.each do |optimized_image|
      optimized_path = Discourse.store.path_for(optimized_image)
      frame_count = `identify "#{optimized_path}" 2>/dev/null | wc -l`.strip.to_i

      expect(frame_count).to be > 1,
        "Optimized image #{optimized_image.width}x#{optimized_image.height} " \
        "has only #{frame_count} frame - animation was not preserved"
    end
  end
end
