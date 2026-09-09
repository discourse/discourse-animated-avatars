# frozen_string_literal: true

def animated_avatars_count
  puts "Database: #{RailsMultisite::ConnectionManagement.current_db}"
  counts =
    Upload
      .where(id: UserAvatar.select(:custom_upload_id))
      .where(extension: %w[gif webp], animated: true)
      .group(:extension)
      .count
  gif_count = counts["gif"] || 0
  webp_count = counts["webp"] || 0
  puts "Animated custom avatars: #{gif_count} GIF, #{webp_count} WebP (#{gif_count + webp_count} total)"
end

def animated_avatars_gif_to_webp
  puts "Database: #{RailsMultisite::ConnectionManagement.current_db}"

  unless SiteSetting.animated_gif_avatar_to_webp
    puts "Skipping — animated_gif_avatar_to_webp is disabled"
    return
  end

  scope =
    UserAvatar
      .joins(:custom_upload)
      .where(uploads: { extension: "gif", animated: true })
      .preload(:user, :custom_upload)

  converted = 0
  failed = 0

  puts "Converting animated GIF avatars to WebP..."

  scope.find_each do |user_avatar|
    upload = user_avatar.custom_upload
    user = user_avatar.user

    print "  Upload ##{upload.id} for @#{user.username} (#{upload.filesize} bytes) ... "

    begin
      path = Discourse.store.path_for(upload) || Discourse.store.download(upload)

      File.open(path) do |file|
        new_upload =
          UploadCreator.new(
            file,
            upload.original_filename,
            type: "avatar",
            force_optimize: true,
          ).create_for(user.id)

        raise new_upload.errors.full_messages.join(", ") unless new_upload.persisted?

        user_avatar.update!(custom_upload_id: new_upload.id)
        user.update!(uploaded_avatar_id: new_upload.id) if user.uploaded_avatar_id == upload.id
        # The old GIF upload is now unreferenced and will be removed by
        # Jobs::CleanUpUploads once the grace period (clean_orphan_uploads_grace_period_hours) elapses.

        converted += 1
        puts "done (#{new_upload.filesize} bytes, #{(upload.filesize.to_f / new_upload.filesize).round(1)}x smaller)"
      end
    rescue => e
      failed += 1
      puts "FAILED — #{e.message}"
      db = RailsMultisite::ConnectionManagement.current_db
      Rails.logger.error(
        "[#{db}] animated_avatars:gif_to_webp upload ##{upload.id} user ##{user.id}: #{e.message}\n#{e.backtrace.first(5).join("\n")}",
      )
    end
  end

  puts "Done: #{converted} converted, #{failed} failed"
end

namespace :animated_avatars do
  desc "Count animated GIF and WebP custom avatars"
  task count_animated: :environment do
    RailsMultisite::ConnectionManagement.each_connection { animated_avatars_count }
  end

  desc "Convert all animated GIF custom avatars to WebP"
  task gif_to_webp: :environment do
    RailsMultisite::ConnectionManagement.each_connection { animated_avatars_gif_to_webp }
  end
end
