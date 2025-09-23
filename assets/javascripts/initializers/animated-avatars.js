import { next } from "@ember/runloop";
import { withPluginApi } from "discourse/lib/plugin-api";
import { prefersReducedMotion } from "discourse/lib/utilities";

let animatedImages = [];
let allowAnimation = true;

function play(img) {
  if (img && allowAnimation) {
    let animatedImg = img.src.replace(/\.png$/, ".gif");
    if (animatedImg !== img.src) {
      img.src = img.src.replace(/\.png$/, ".gif");
      animatedImages.push(img);
    }
  }
}

function pauseAll(resumable = false) {
  animatedImages?.forEach((img) => {
    img.src = img.src.replace(/\.gif$/, ".png");
  });

  // pause all either due to a resumable event (temporarily prevent any animation event to fire until event is over)
  // or we are stopping all animation, and will listen for future events to fire new animations
  if (resumable) {
    allowAnimation = false;
  } else {
    animatedImages = [];
  }
}

function resumeAll() {
  allowAnimation = true;
  animatedImages?.forEach((img) => {
    img.src = img.src.replace(/\.png$/, ".gif");
  });
}

function customizePost(api) {
  const ANIMATED_AVATAR_ACTIVE = Symbol("avatar-animated-state");

  api.addTrackedPostProperties("animated_avatar");
  api.addPostClassesCallback((post) => {
    if (post?.animated_avatar != null) {
      return ["animated-avatar"];
    }
    return [];
  });

  const siteSettings = api.container.lookup("service:site-settings");

  api.registerValueTransformer(
    "post-avatar-template",
    ({ value, context: { post, keyboardSelected, decoratorState } }) => {
      const animate =
        value &&
        post.animated_avatar &&
        (siteSettings.animated_avatars_always_animate ||
          keyboardSelected ||
          decoratorState?.get(ANIMATED_AVATAR_ACTIVE));

      if (animate) {
        return value.replace(/\.png$/, ".gif");
      }

      return value;
    }
  );

  if (!siteSettings.animated_avatars_always_animate) {
    api.registerValueTransformer(
      "post-event-listener",
      ({ value: events, context: { decoratorState } }) => {
        events.push({
          event: "mouseenter",
          callback: () => {
            if (!decoratorState.has(ANIMATED_AVATAR_ACTIVE)) {
              decoratorState.set(ANIMATED_AVATAR_ACTIVE, true);
            }
          },
        });
        events.push({
          event: "mouseleave",
          callback: () => {
            decoratorState.delete(ANIMATED_AVATAR_ACTIVE);
          },
        });
      }
    );
  }
}

export default {
  name: "animated-avatars",

  initialize() {
    withPluginApi((api) => {
      //disable if prefers reduced motion
      if (prefersReducedMotion()) {
        return;
      }

      customizePost(api);

      window.addEventListener("blur", this.blurEvent);
      window.addEventListener("focus", this.focusEvent);

      api.customUserAvatarClasses((user) => {
        if (user?.animated_avatar != null) {
          return ["animated-avatar"];
        }
        return [];
      });

      api.onAppEvent("user-card:after-show", () => {
        // Allow render
        next(() => {
          // Do not animate other images
          pauseAll();

          // Play on user card with fewer conditions
          play(document.querySelector("#user-card img.animated-avatar"));
        });
      });
    });
  },

  blurEvent() {
    pauseAll(true);
  },

  focusEvent() {
    resumeAll();
  },

  teardown() {
    window.removeEventListener("blur", this.blurEvent);
    window.removeEventListener("focus", this.focusEvent);
  },
};
