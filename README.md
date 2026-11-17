# discourse-animated-avatars

Adds the ability for users to upload animated avatars (gif, webp) which will animate on hover or selection in posts, user cards, and profile pages

## Settings

- `animated_avatars_always_animate` - Always displays animated avatar. If false, only displays on hover or selection. (default false)
- `animated_gif_avatar_to_webp` - auto converts animated gif avatars to webp on upload, reducing file size. (default: true)
- `animated_gif_avatar_webp_quality` - the quality of the converted gif to webp. Recommended settings between 75% to 100% (default: 80%)

## Resizing

Animated avatars are resized to a square with libvips, which Discourse already includes, so no extra packages are needed. Animations that are not square are stretched to fit, not cropped.
