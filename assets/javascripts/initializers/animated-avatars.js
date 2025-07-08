import { next } from "@ember/runloop";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import { prefersReducedMotion } from "discourse/lib/utilities";

let animatedImages = [];
let allowAnimation = true;

function userCardShown() {
  return document.querySelector("#user-card.show");
}

// Only play when the user card is not shown
function playAvatarAnimation(img) {
  if (!userCardShown()) {
    play(img);
  }
}

function play(img) {
  if (img && allowAnimation) {
    let animatedImg = img.src.replace(/\.png$/, ".gif");
    if (animatedImg !== img.src) {
      img.src = img.src.replace(/\.png$/, ".gif");
      animatedImages.push(img);
    }
  }
}

function pause(img) {
  if (img) {
    let animatedImg = img.src.replace(/\.gif$/, ".png");
    if (animatedImg !== img.src) {
      img.src = img.src.replace(/\.gif$/, ".png");
    }
    animatedImages = animatedImages.filter((item) => item !== img);
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

function getPauseAnimateAvatarEventFn(
  eventParentSelector = null,
  avatarSelector = null
) {
  return (e) => {
    const target =
      eventParentSelector != null
        ? e.target.closest(eventParentSelector)
        : e.target;

    // We are still hovering over a parent target, do not pause
    const center = document.elementsFromPoint(e.clientX, e.clientY);
    if (center.some((ele) => ele === target)) {
      return;
    }

    const images =
      avatarSelector != null
        ? target?.querySelectorAll(avatarSelector)
        : [target];
    images?.forEach((img) => {
      pause(img);
    });
  };
}

function getAnimateAvatarEventFn(
  eventParentSelector = null,
  avatarSelector = null
) {
  return (e) => {
    const target =
      eventParentSelector != null
        ? e.target.closest(eventParentSelector)
        : e.target;
    const images =
      avatarSelector != null
        ? target?.querySelectorAll(avatarSelector)
        : [target];
    images?.forEach((img) => {
      playAvatarAnimation(img);
    });
  };
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

  withSilencedDeprecations("discourse.post-stream-widget-overrides", () =>
    customizeWidgetPost(api)
  );
}

function customizeWidgetPost(api) {
  // Always animated
  const siteSettings = api.container.lookup("service:site-settings");
  if (siteSettings.animated_avatars_always_animate) {
    api.reopenWidget("post", {
      didRenderWidget() {
        if (
          this.attrs.animated_avatar &&
          this.siteSettings.animated_avatars_always_animate
        ) {
          document
            .querySelectorAll(".animated-avatar .main-avatar img.avatar")
            .forEach((img) => {
              img.src = img.src.replace(/\.png$/, ".gif");
            });
        }
      },
    });
  }

  // Only animate on hover, and keyboard focus events
  else {
    api.onAppEvent(
      "keyboard:move-selection",
      ({ articles, selectedArticle }) => {
        articles?.forEach((a) => {
          if (a.classList.contains("animated-avatar")) {
            pause(a.querySelector(".main-avatar img.avatar"));
          }
        });
        if (selectedArticle.classList.contains("animated-avatar")) {
          playAvatarAnimation(
            selectedArticle.querySelector(".main-avatar img.avatar")
          );
        }
      }
    );

    api.reopenWidget("post", {
      mouseOver: getAnimateAvatarEventFn(
        ".animated-avatar",
        ".main-avatar>.avatar"
      ),
      mouseOut: getPauseAnimateAvatarEventFn(
        ".animated-avatar",
        ".main-avatar>.avatar"
      ),
    });
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
