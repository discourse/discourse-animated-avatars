import animatedBoundAvatar from "discourse/plugins/discourse-animated-avatars/app/helpers/animated-bound-avatar";

const AnimatedAvatar = <template>
  {{animatedBoundAvatar @outletArgs.user "huge"}}
</template>;

export default AnimatedAvatar;
