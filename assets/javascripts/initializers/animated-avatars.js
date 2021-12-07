import { get } from "@ember/object";
import { iconHTML } from "discourse-common/lib/icon-library";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { schedule } from "@ember/runloop";
import { withPluginApi } from "discourse/lib/plugin-api";

function getPauseAnimateAvatarEventFn(
  element = null,
  avatarSelector = "img.animated-avatar"
) {
  return (event) => {
    console.log("pause animate");
    let images = [event.currentTarget];
    if (element !== null) {
      images = element.querySelectorAll(avatarSelector);
    }
    images.forEach((img) => {
      img.src = img.src.replace(/\.gif$/, ".png");
    });
  };
}

function getAnimateAvatarEventFn(
  element = null,
  avatarSelector = "img.animated-avatar"
) {
  return (event) => {
    console.log("animate");
    let images = [event.currentTarget];
    if (element !== null) {
      images = element.querySelectorAll(avatarSelector);
    }
    images.forEach((img) => {
      img.src = img.src.replace(/\.png$/, ".gif");
    });
  };
}

export function hoverExtension(selector = "img.animated-avatar") {
  return {
    pluginId: "discourse-animated-avatar",

    didInsertElement() {
      this._super(...arguments);
      let targets = this.element.querySelectorAll(selector);

      this._pauseAnimateAvatarEvent = getPauseAnimateAvatarEventFn();
      this._animateAvatarEvent = getAnimateAvatarEventFn();

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
      let targets = this.element.querySelectorAll(selector);

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
        if (get(user, "user")?.animated_avatar != null) {
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

      api.modifyClass("component:topic-list", hoverExtension());

      api.reopenWidget("post", {
        mouseOver(event) {
          const element = event.target.closest(".animated-avatar");
          if (element) {
            getAnimateAvatarEventFn(
              element,
              ".main-avatar>.avatar"
            )(event.originalEvent);
          }
        },
        mouseOut(event) {
          const element = event.target.closest(".animated-avatar");
          if (element) {
            getPauseAnimateAvatarEventFn(
              element,
              ".main-avatar>.avatar"
            )(event.originalEvent);
          }
        },
      });
    });
  },
};
