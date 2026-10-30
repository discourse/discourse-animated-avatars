# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::OptimizedImageExtension do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|png|jpg|webp"
    SiteSetting.animated_gif_avatar_to_webp = false
  end

  def fixture_path(name)
    File.expand_path("../fixtures/images/#{name}", __dir__)
  end

  describe "PNG thumbnail generation for animated uploads (served at .png avatar URLs)" do
    it "generates a static PNG thumbnail for an animated WebP upload" do
      webp = Tempfile.new(%w[animated .webp])
      IO.copy_stream(fixture_path("animated.webp"), webp)
      webp.rewind

      upload = UploadCreator.new(webp, "animated.webp", type: "avatar").create_for(user.id)
      expect(upload.animated).to eq(true)

      thumbnail = OptimizedImage.create_for(upload, 120, 120, format: "png")
      expect(thumbnail).to be_present

      path = Discourse.store.path_for(thumbnail)
      expect(FastImage.type(path)).to eq(:png)
      expect(FastImage.animated?(path)).to be_falsy
    end

    it "generates a static PNG thumbnail for an animated GIF upload" do
      upload =
        UploadCreator.new(
          file_from_fixtures("animated.gif"),
          "animated.gif",
          type: "avatar",
        ).create_for(user.id)
      expect(upload.animated).to eq(true)

      thumbnail = OptimizedImage.create_for(upload, 120, 120, format: "png")
      expect(thumbnail).to be_present

      path = Discourse.store.path_for(thumbnail)
      expect(FastImage.type(path)).to eq(:png)
      expect(FastImage.animated?(path)).to be_falsy
    end
  end

  describe ".resize_animated_gif" do
    it "confines filesystem access to the input and output files" do
      skip "Landlock is not supported" unless Discourse::SafeExec.landlock_supported?

      Dir.mktmpdir do |directory|
        from = File.join(directory, "input.gif")
        to = File.join(directory, "output.gif")
        secret = File.join(directory, "secret")
        File.write(from, "avatar")
        File.write(secret, "secret")

        allow(Discourse::SafeExec).to receive(
          :capture,
        ).and_wrap_original do |capture, *command, **options|
          output_path = command[command.index("--output") + 1]
          capture.call(RbConfig.ruby, "--disable-gems", "-e", <<~RUBY, from, output_path, **options)
            File.write(ARGV[1], File.read(ARGV[0]))
            begin
              File.read(#{secret.inspect})
            rescue Errno::EACCES
              puts "read denied"
            end
            begin
              File.write(#{secret.inspect}, "changed")
            rescue Errno::EACCES
              puts "write denied"
            end
          RUBY
        end

        output = OptimizedImage.resize_animated_gif(from, to, 20, 20)

        expect(output).to eq("read denied\nwrite denied\n")
        expect(File.read(to)).to eq("avatar")
        expect(File.read(secret)).to eq("secret")
      end
    end
  end
end
