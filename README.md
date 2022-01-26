# discourse-animated-avatars

Adds the ability for users to upload gif avatars which will animate on hover or selection in posts, user cards, and profile pages

## app.yml

your `app.yml` needs to be configured to install gifsicle in addition to the plugin:

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
