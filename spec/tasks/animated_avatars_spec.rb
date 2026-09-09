# frozen_string_literal: true

RSpec.describe "animated_avatars rake tasks" do
  before do
    enable_current_plugin
    SiteSetting.authorized_extensions = "gif|webp|png"
    SiteSetting.animated_gif_avatar_to_webp = true
  end

  def run_count
    capture_stdout { Rake::Task["animated_avatars:count_animated"].execute }
  end

  def run_gif_to_webp
    capture_stdout { Rake::Task["animated_avatars:gif_to_webp"].execute }
  end

  def make_custom_avatar(user, extension:, animated: true)
    upload =
      Fabricate(
        :upload,
        user: user,
        extension: extension,
        animated: animated,
        original_filename: "avatar.#{extension}",
      )
    user.create_user_avatar! unless user.user_avatar
    user.user_avatar.update!(custom_upload_id: upload.id)
    user.update!(uploaded_avatar_id: upload.id)
    upload
  end

  def make_real_gif_avatar(user)
    SiteSetting.animated_gif_avatar_to_webp = false
    upload =
      UploadCreator.new(
        file_from_fixtures("animated.gif"),
        "animated.gif",
        type: "avatar",
        force_optimize: true,
      ).create_for(user.id)
    user.create_user_avatar! unless user.user_avatar
    user.user_avatar.update!(custom_upload_id: upload.id)
    user.update!(uploaded_avatar_id: upload.id)
    SiteSetting.animated_gif_avatar_to_webp = true
    upload
  end

  describe "animated_avatars:count_animated" do
    it "counts only animated custom avatars by format, ignoring non-avatar and non-animated uploads" do
      user_gif = Fabricate(:user)
      user_webp = Fabricate(:user)
      user_static = Fabricate(:user)

      make_custom_avatar(user_gif, extension: "gif")
      make_custom_avatar(user_webp, extension: "webp")
      make_custom_avatar(user_static, extension: "gif", animated: false)
      Fabricate(:upload, extension: "gif", animated: true, original_filename: "post.gif")

      output = run_count

      expect(output).to include("1 GIF")
      expect(output).to include("1 WebP")
      expect(output).to include("2 total")
    end
  end

  describe "animated_avatars:gif_to_webp" do
    fab!(:user)
    let!(:gif_upload) { make_real_gif_avatar(user) }

    it "skips when animated_gif_avatar_to_webp is disabled" do
      SiteSetting.animated_gif_avatar_to_webp = false
      output = run_gif_to_webp
      expect(output).to include("Skipping")
    end

    it "converts to a real animated WebP, updates references, and reports converted count" do
      output = run_gif_to_webp

      new_upload = Upload.find(user.user_avatar.reload.custom_upload_id)
      expect(new_upload.id).not_to eq(gif_upload.id)
      expect(new_upload.extension).to eq("webp")
      expect(FastImage.type(Discourse.store.path_for(new_upload))).to eq(:webp)
      expect(FastImage.animated?(Discourse.store.path_for(new_upload))).to eq(true)
      expect(user.reload.uploaded_avatar_id).to eq(new_upload.id)
      expect(output).to include("1 converted")
    end

    it "does not update uploaded_avatar_id when the user is not actively displaying the GIF" do
      other = Fabricate(:upload, original_filename: "other.gif", extension: "gif")
      user.update!(uploaded_avatar_id: other.id)

      run_gif_to_webp

      expect(user.reload.uploaded_avatar_id).to eq(other.id)
    end

    it "only processes animated GIF custom avatars" do
      webp_user = Fabricate(:user)
      webp_upload = make_custom_avatar(webp_user, extension: "webp")

      run_gif_to_webp

      expect(webp_user.user_avatar.reload.custom_upload_id).to eq(webp_upload.id)
    end

    context "when UploadCreator raises" do
      before do
        allow_any_instance_of(UploadCreator).to receive(:create_for).and_raise("conversion failed")
      end

      it "reports the failure, preserves references, and reports failed count" do
        output = run_gif_to_webp

        expect(output).to include("FAILED")
        expect(output).to include("1 failed")
        expect(user.user_avatar.reload.custom_upload_id).to eq(gif_upload.id)
        expect(user.reload.uploaded_avatar_id).to eq(gif_upload.id)
      end
    end
  end
end
