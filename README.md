# discourse-animated-avatars

Adds the ability for users to upload gif avatars which will animate on hover or selection in posts, user cards, and profile pages

## Enable gif resizing

Optionally, your `app.yml` may be configured to install gifsicle in addition to the plugin.

This allows gif uploads to be cropped and resized to fit a square avatar. If the dependency is not included,
gif uploads will keep the original aspect ratio.

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
