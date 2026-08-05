# grand-trmnl

Every screen departs from here — a monorepo of plugins for [TRMNL](https://trmnl.com) e-paper displays.

## Plugins

| Plugin | Purpose |
| --- | --- |
| [parcel](plugins/parcel/) | [Parcel](https://parcelapp.net) package tracking — delivery anticipation at a glance |

## Layout

Each plugin under `plugins/<name>/` is a self-contained [trmnlp](https://github.com/usetrmnl/trmnlp) project. Shared tooling lives at the root: [mise](https://mise.jdx.dev) pins the toolchain, renovate keeps it current.

```sh
mise install            # toolchain (ruby, python, trmnlp, linters)
mise run dev [plugin]   # local preview at :4567 (defaults to parcel)
mise run lint           # markdownlint
```

Rendering previews requires Firefox and ImageMagick (see each plugin's DEV.md for why Firefox is load-bearing).
