# puck.misaki.fi

The website for **Puck Around** — neon air hockey for the people around one
iPhone or iPad. Landing, support, and privacy pages.

The game itself is open source (MIT) at
[github.com/vlumi/puckaround](https://github.com/vlumi/puckaround). **This site
is not**: the marketing copy and artwork are all rights reserved. The
repository is public for transparency, not for reuse.

## Build

Static site, built with [Hugo Extended](https://gohugo.io/). No JS, no external
assets — plain HTML/CSS.

The Hugo version is **pinned** in [`.hugoversion`](.hugoversion). Hugo is a
build-time tool, not a runtime — there's no security reason to chase updates,
and a bump is the thing most likely to *break* the build. So pin it and update
**deliberately**: bump `.hugoversion`, run a local build, and commit only if
it's clean. (The box's nginx / OS / certbot are what stay current, not Hugo.)

```sh
hugo server        # local preview at http://localhost:1313
hugo               # one-off build into ./public
```

## Deploy

Served by nginx over HTTPS (Let's Encrypt / certbot) on the host for
`puck.misaki.fi`. [`deploy.sh`](deploy.sh) does it in one step: it
fetches the **pinned** Hugo Extended (cached per-version under
`~/.local/share/puckaround-hugo`, no root, never the system Hugo), pulls, and
builds straight into the web root.

```sh
./deploy.sh                          # pull, build, publish to /var/www/puck
WEBROOT=/some/other/path ./deploy.sh # override the publish dir
./deploy.sh --no-pull                # build the working tree as-is
```

[`nginx.conf.example`](nginx.conf.example) is the server block it's served from.

## Content

Four pages, all small:

- `layouts/index.html` — the landing page, written directly in the template
  since it's structure rather than prose.
- `content/screenshots.md` — the gallery. Shots come from the app repo's
  `make shots` capture tree, named identically (`rally-iphone.png`, …): drop
  the PNGs into `assets/img/shots/` and Hugo resizes them at build time.
  Until a capture lands, its slot renders a labelled placeholder.
- `content/support.md` — the questions a couch game actually provokes.
- `content/privacy.md` — mirrors
  [PRIVACY.md](https://github.com/vlumi/puckaround/blob/main/PRIVACY.md) in the
  app repo. **Keep the two in step**: App Store Connect points at one of them,
  and a privacy policy that contradicts itself is worse than either version
  alone.

## Assets

`static/appicon.png` is the app's own icon, rendered by the game's drawing
code (`make icon` in the app repo) rather than drawn separately, so the site
and the App Store listing can't drift apart. Regenerate it there and copy it
here; the favicons are downscales of the same file.

## Styling

One stylesheet, `assets/css/main.css`, in the app's own language: the neon
cabinet — near-black violet ground, the two seat colors (magenta down, cyan
up, as the game is held), glow used sparingly. Compiled + fingerprinted by
Hugo so nginx can cache it hard.
