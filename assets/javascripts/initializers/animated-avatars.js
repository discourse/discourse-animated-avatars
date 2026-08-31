import { next } from "@ember/runloop";
import { withPluginApi } from "discourse/lib/plugin-api";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { animatedExtension } from "discourse/plugins/discourse-animated-avatars/app/lib/animated-avatar-utils";

let animatedImages = []; // [{ img, ext }, ...]
let allowAnimation = true;

function play(img, ext) {
  if (img && allowAnimation && ext) {
    const animatedSrc = img.src.replace(/\.png$/, `.${ext}`);
    if (animatedSrc !== img.src) {
      img.src = animatedSrc;
      animatedImages.push({ img, ext });
    }
  }
}

function pauseAll(resumable = false) {
  animatedImages?.forEach(({ img, ext }) => {
    img.src = img.src.slice(0, -(ext.length + 1)) + ".png";
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
  animatedImages?.forEach(({ img, ext }) => {
    img.src = img.src.replace(/\.png$/, `.${ext}`);
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
      const ext = animatedExtension(post.animated_avatar);
      const animate =
        value &&
        ext &&
        (siteSettings.animated_avatars_always_animate ||
          keyboardSelected ||
          decoratorState?.get(ANIMATED_AVATAR_ACTIVE));

      if (animate) {
        return value.replace(/\.png$/, `.${ext}`);
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

      const userCardService = api.container.lookup("service:user-card");

      api.onAppEvent("user-card:after-show", () => {
        // Allow render
        next(() => {
          // Do not animate other images
          pauseAll();

          // Play on user card with fewer conditions
          const cardImg = document.querySelector(
            "#user-card img.animated-avatar"
          );
          if (cardImg) {
            play(cardImg, animatedExtension(userCardService?.user?.animated_avatar));
          }
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
