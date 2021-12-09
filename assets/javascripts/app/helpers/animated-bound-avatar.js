import { get } from "@ember/object";
import { htmlHelper } from "discourse-common/lib/helpers";
import { prefersReducedMotion } from "discourse/lib/utilities";
import boundAvatar from "discourse/helpers/bound-avatar";

export default htmlHelper((user, size) => {
  const avatar = boundAvatar.compute([user, size], {});
  if (user.animated_avatar != null && !prefersReducedMotion()) {
    avatar.string = avatar.string.replace(/\.png/, ".gif");
  }
  return avatar;
});
