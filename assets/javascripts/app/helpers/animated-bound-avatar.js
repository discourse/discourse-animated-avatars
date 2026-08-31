import { trustHTML } from "@ember/template";
import { prefersReducedMotion } from "discourse/lib/utilities";
import boundAvatar from "discourse/ui-kit/helpers/d-bound-avatar";
import { animatedExtension } from "discourse/plugins/discourse-animated-avatars/app/lib/animated-avatar-utils";

export default function (user, size) {
  const avatar = boundAvatar(user, size);

  if (!user.animated_avatar || prefersReducedMotion()) {
    return avatar;
  }

  const ext = animatedExtension(user.animated_avatar);
  if (!ext) {
    return avatar;
  }

  return trustHTML(avatar.toString().replace(/\.png/, `.${ext}`));
}
