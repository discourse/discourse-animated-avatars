import { htmlSafe } from "@ember/template";
import boundAvatar from "discourse/helpers/bound-avatar";
import { prefersReducedMotion } from "discourse/lib/utilities";

export default function (user, size) {
  const avatar = boundAvatar(user, size);

  if (!user.animated_avatar || prefersReducedMotion()) {
    return avatar;
  }

  return htmlSafe(avatar.toString().replace(/\.png/, ".gif"));
}
