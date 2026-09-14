# claude-code-hud

My Claude Code status line: the renderer, its column config, and an installer.

    5h Usage │ 7d Usage │ Context │ Model │ Repo │ Directory │ Version
    21% (~3h) │ 2% (~167h) │ 42% Used │ Opus 5 │ my-repo | main │ D:/code/my-repo │ ● v2.0.0

## Install on a new machine

Needs `node`. Clone and run:

    git clone https://github.com/Domizze/claude-code-hud.git
    cd claude-code-hud
    ./install.sh

Or without a clone, if the repo is public:

    curl -fsSL https://raw.githubusercontent.com/Domizze/claude-code-hud/main/install.sh | bash

While it's private, the piped form needs `gh` (`gh auth login` first):

    gh api repos/Domizze/claude-code-hud/contents/install.sh -H "Accept: application/vnd.github.raw" | bash

Re-run any of them to update. The installer copies from the clone when it
finds one and downloads otherwise, backs up `settings.json` to
`settings.json.bak` before touching it (and refuses to write if that file
isn't valid JSON), then smoke-tests a real render before declaring success.

## What the Repo column shows

Git repo folder + branch. Prefixes the branch with `worktree` when the
current directory is a linked git worktree, shows a short sha on detached
HEAD, and `-` outside a repo. One `git rev-parse` per render.

## Columns

`config.jsonc` toggles columns; `true` shows, `false` hides. Defaults: the
Standard group on, the rest off.

    5h Usage, 7d Usage, Context, Model, Version,
    Session, Changes, Directory, Repo, Cost,
    Tokens, Output Tokens, Cache, API Time, 5h Reset, 7d Reset

`"layout"` is `"vertical"` (labels above values) or `"horizontal"`.

Column **order** is positional in `render()` inside the `.mjs`, not driven
by `config.jsonc`.

## Notes

- No npm dependencies.
- The 5h/7d columns read `~/.claude/.credentials.json`, so log into Claude
  Code on that machine first or they show `N/A`.
- The renderer is third-party code of unknown provenance, kept private for
  that reason.
