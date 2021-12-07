import { iconHTML } from "discourse-common/lib/icon-library";
import { prefersReducedMotion } from "discourse/lib/utilities";
import { withPluginApi } from "discourse/lib/plugin-api";

export function hoverExtension(selector = "img.animated-avatar") {
  return {
    pluginId: "discourse-animated-avatar",

    didInsertElement() {
      this._super(...arguments);
      let targets = this.element.querySelectorAll(selector);

      this._pauseAnimateAvatarEvent = (event) => {
        let images = [event.currentTarget];
        if (selector != "img.animated-avatar") {
          images = event.currentTarget.querySelectorAll("img.animated-avatar");
        }
        images.forEach((img) => {
          img.src = img.src.replace(/\.gif$/, ".png");
        });
      };
      this._animateAvatarEvent = (event) => {
        let images = [event.currentTarget];
        if (selector != "img.animated-avatar") {
          images = event.currentTarget.querySelectorAll("img.animated-avatar");
        }
        images.forEach((img) => {
          img.src = img.src.replace(/\.png$/, ".gif");
        });
      };

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
        if (get(user, "user").animated_avatar) {
          return ["animated-avatar"];
        }
        return [];
      });

      api.modifyClass("component:topic-list", hoverExtension());
    });
  },
};
