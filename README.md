# discourse-animated-avatars

Adds the ability for users to upload animated avatars (gif, webp) which will animate on hover or selection in posts, user cards, and profile pages

## Settings

- `animated_avatars_always_animate` - Always displays animated avatar. If false, only displays on hover or selection. (default false)
- `animated_gif_avatar_to_webp` - auto converts animated gif avatars to webp on upload, reducing file size. (default: true)
- `animated_gif_avatar_webp_quality` - the quality of the converted gif to webp. Recommended settings between 75% to 100% (default: 80%)

## Enable gif resizing

Optionally, your `app.yml` may be configured to install gifsicle in addition to the plugin.

This allows gif uploads to be cropped and resized to fit a square avatar. If the dependency is not included,
gif uploads will keep the original aspect ratio. The dependency is not required for auto gif to webp conversion.

```
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/discourse-animated-avatars.git
    - exec:
        cd: $home/plugins/discourse-animated-avatars
        raise_on_fail: false
        cmd:
          - $home/plugins/discourse-animated-avatars/scripts/install.sh
```
