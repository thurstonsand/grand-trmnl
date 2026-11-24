# grand-trmnl

Every screen departs from here — a monorepo of plugins for [TRMNL](https://trmnl.com) e-paper displays.

## Plugins

| Plugin                    | Purpose                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------ |
| [parcel](plugins/parcel/) | [Parcel](https://parcelapp.net) package tracking — delivery anticipation at a glance |

## Layout

Each plugin under `plugins/<name>/` is a self-contained [trmnlp](https://github.com/usetrmnl/trmnlp) project. Shared tooling lives at the root: [mise](https://mise.jdx.dev) provisions the machine, activates the project environment, pins the toolchain, and runs tasks; Renovate keeps it current.

```sh
mise trust            # once, per clone
mise bootstrap --yes  # once, and whenever mise.toml changes
mise run dev [plugin] # local preview at :4567 (defaults to parcel)
mise run lint         # markdownlint; also gates commits
```

Bootstrap installs Ruby gems from `Gemfile.lock` in frozen mode. Run Ruby tools with `mise x -- bundle exec`, for example `mise x -- bundle exec trmnlp version`. Renovate updates the Gemfile and refreshes its lock weekly; the Gemfile's three-day cooldown also applies to transitive gems when Bundler resolves the lock.

For a manual gem update, edit `Gemfile` and run `mise x -- env -u BUNDLE_FROZEN bundle lock --update trmnl_preview`, then commit `Gemfile` and `Gemfile.lock` together.
