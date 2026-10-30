# frozen_string_literal: true

RSpec.describe DiscourseAnimatedAvatars::OptimizedImageExtension do
  before { enable_current_plugin }

  def run_probe(script:, from:, to:)
    allow(Discourse::SafeExec).to receive(:capture).and_wrap_original do |capture, *args, **options|
      capture.call(RbConfig.ruby, "--disable-gems", "-e", script, from, to, **options)
    end

    OptimizedImage.resize_animated_gif(from, to, 20, 20)
  end

  describe ".resize_animated_gif" do
    it "resizes an animated GIF to a separate output and in place" do
      skip "gifsicle not installed" unless system("gifsicle", "--version", out: File::NULL)

      Dir.mktmpdir do |directory|
        from = File.join(directory, "input.gif")
        to = File.join(directory, "output.gif")
        FileUtils.cp(file_from_fixtures("animated.gif").path, from)

        OptimizedImage.resize_animated_gif(from, to, 20, 20)

        expect(FastImage.size(to)).to eq([20, 20])
        expect(FastImage.animated?(to)).to eq(true)

        OptimizedImage.resize_animated_gif(to, to, 10, 10)

        expect(FastImage.size(to)).to eq([10, 10])
        expect(FastImage.animated?(to)).to eq(true)
      end
    end

    it "confines filesystem access to the input and output locations" do
      skip "Landlock is not supported" unless Discourse::SafeExec.landlock_supported?

      Dir.mktmpdir do |directory|
        input_directory = File.join(directory, "input")
        output_directory = File.join(directory, "output")
        FileUtils.mkdir_p([input_directory, output_directory])
        from = File.join(input_directory, "avatar.gif")
        to = File.join(output_directory, "avatar.gif")
        secret = File.join(input_directory, "secret")
        File.write(from, "avatar")
        File.write(secret, "secret")

        output = run_probe(from:, to:, script: <<~RUBY)
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

        expect(output).to eq("read denied\nwrite denied\n")
        expect(File.read(to)).to eq("avatar")
        expect(File.read(secret)).to eq("secret")
      end
    end

    it "denies network access and child processes" do
      skip "Landlock is not supported" unless Discourse::SafeExec.landlock_supported?

      Tempfile.create("avatar") do |file|
        output = run_probe(from: file.path, to: file.path, script: <<~RUBY)
              require "socket"
              begin
                Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
              rescue Errno::EPERM
                puts "network denied"
              end
              begin
                Process.wait(fork { exit! })
              rescue Errno::EPERM
                puts "fork denied"
              end
            RUBY

        expect(output).to eq("network denied\nfork denied\n")
      end
    end

    it "clears inherited environment variables even without Landlock" do
      allow(Landlock).to receive(:supported?).and_return(false)

      Tempfile.create("avatar") do |file|
        output =
          run_probe(
            from: file.path,
            to: file.path,
            script: "puts ENV.keys.reject { |key| %w[PATH LANG LC_ALL].include?(key) }.inspect",
          )

        expect(output).to eq("[]\n")
      end
    end

    it "terminates processing that exceeds the conversion timeout" do
      Tempfile.create("avatar") do |file|
        stub_const(OptimizedImage, "MAX_CONVERT_SECONDS", 0.1) do
          expect { run_probe(script: "sleep 30", from: file.path, to: file.path) }.to raise_error(
            Discourse::Utils::CommandError,
          )
        end
      end
    end
  end
end
