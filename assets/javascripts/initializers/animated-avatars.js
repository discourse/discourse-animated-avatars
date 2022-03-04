import { get } from "@ember/object";
import { iconHTML } from "discourse-common/lib/icon-library";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { next } from "@ember/runloop";
import { withPluginApi } from "discourse/lib/plugin-api";

let animatedImages = [];

function userCardShown() {
  return document.querySelector("#user-card.show");
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
    if (center.some((ele) => ele == target)) {
      return;
    }

    const images =
      avatarSelector != null
        ? target?.querySelectorAll(avatarSelector)
        : [target];
    images.forEach((img) => {
      // Only replace img source if this differs
      let animatedImg = img.src.replace(/\.gif$/, ".png");
      if (animatedImg !== img.src) {
        img.src = img.src.replace(/\.gif$/, ".png");
        animatedImages = animatedImages.filter((item) => item !== img);
      }
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
    images.forEach((img) => {
      // Only replace img source if this differs
      let animatedImg = img.src.replace(/\.png$/, ".gif");
      if (animatedImg !== img.src && !userCardShown()) {
        img.src = img.src.replace(/\.png$/, ".gif");
        animatedImages.push(img);
      }
    });
  };
}

export function hoverExtension(parentSelector = null, avatarSelector = null) {
  return {
    didInsertElement() {
      this._super(...arguments);
      let targets = [this.element];

      this._pauseAnimateAvatarEvent = getPauseAnimateAvatarEventFn(
        parentSelector,
        avatarSelector
      );
      this._animateAvatarEvent = getAnimateAvatarEventFn(
        parentSelector,
        avatarSelector
      );

      targets.forEach((target) => {
        target.addEventListener("mouseover", this._animateAvatarEvent, false);
        target.addEventListener(
          "mouseout",
          this._pauseAnimateAvatarEvent,
          false
        );
      });
    },

    willDestroyElement() {
      this._super(...arguments);
      let targets = [this.element];

      targets.forEach((target) => {
        target.removeEventListener("mouseover", this._animateAvatarEvent);
        target.removeEventListener("mouseout", this._pauseAnimateAvatarEvent);
      });
    },
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

      //      api.modifyClass("component:user-card-contents", {
      //        pluginId: "discourse-animated-avatar",
      //        ...hoverExtension(".card-content", "img.animated-avatar"),
      //      });

      api.onAppEvent("user-card:after-show", () => {
        // Allow render
        next(() => {
          // Do not animate other images
          animatedImages.forEach((img) => {
            img.src = img.src.replace(/\.gif$/, ".png");
          });
          animatedImages = [];

          const img = document.querySelector("#user-card img.animated-avatar");
          if (img) {
            img.src = img.src.replace(/\.png$/, ".gif");
          }
        });
      });
      api.onAppEvent(
        "keyboard:move-selection",
        ({ articles, selectedArticle }) => {
          articles.forEach((a) => {
            if (a.classList.contains("animated-avatar")) {
              const img = a.querySelector(".main-avatar img.avatar");
              if (img) {
                img.src = img.src.replace(/\.gif$/, ".png");
              }
            }
          });
          if (selectedArticle.classList.contains("animated-avatar")) {
            const img = selectedArticle.querySelector(
              ".main-avatar img.avatar"
            );
            if (img && !userCardShown()) {
              img.src = img.src.replace(/\.png$/, ".gif");
            }
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
};
