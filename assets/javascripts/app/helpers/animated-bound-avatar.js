import boundAvatar from "discourse/helpers/bound-avatar";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { htmlHelper } from "discourse-common/lib/helpers";

export default htmlHelper((user, size) => {
  const avatar = boundAvatar(user, size);
  if (avatar) {
    if (user.animated_avatar != null && !prefersReducedMotion()) {
      if (avatar.__string) {
        avatar.__string = avatar.__string.replace(/\.png/, ".gif");
      } else {
        console.warn('discourse-animated-avatar: The avatar string variable has changed, probably after an update of Discourse. Falling back on static avatar. The object is now ', avatar);
      }
    }
  } else {
    console.warn('discourse-animated-avatar: Cannot find the avatar object, probably after an update of Discourse. Falling back on static avatar.');
  }
  return avatar;
});
