import boundAvatar from "discourse/helpers/bound-avatar";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { htmlHelper } from "discourse-common/lib/helpers";

export default htmlHelper((user, size) => {
  const avatar = boundAvatar(user, size);
  if (user.animated_avatar != null && !prefersReducedMotion()) {
    console.log(avatar);
    avatar.__string = avatar.__string.replace(/\.png/, ".gif");
  }
  return avatar;
});
