import { prefersReducedMotion } from "discourse/lib/utilities";
import { next } from "@ember/runloop";
import { withPluginApi } from "discourse/lib/plugin-api";

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

export default {
  name: "animated-avatars",

  initialize() {
    withPluginApi("0.8.7", (api) => {
      //disable if prefers reduced motion
      if (prefersReducedMotion()) {
        return;
      }

      window.addEventListener("blur", this.blurEvent);
      window.addEventListener("focus", this.focusEvent);

      api.customUserAvatarClasses((user) => {
        if (user?.animated_avatar != null) {
          return ["animated-avatar"];
        }
        return [];
      });

      api.includePostAttributes("animated_avatar");
      api.addPostClassesCallback((attrs) => {
        if (attrs?.animated_avatar != null) {
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
