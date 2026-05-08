# @opflow/plugin

Source for the `opflow` Claude Code plugin: skills, slash commands, and a `plugin.json` manifest.

## Distribution

Published as a public Claude Code marketplace at `josef32/opflow-claude-plugin`. The orchestrator's settings UI and invitation acceptance screen point users at:

```
/plugin marketplace add josef32/opflow-claude-plugin
/plugin install opflow@opflow
```

The plugin ships **no MCP registration** — Claude Code's marketplace schema does not support HTTPS-served plugin trees, so we can't bake a per-user JWT into a plugin's `.mcp.json` over plain HTTP. Users register the orchestrator as an MCP server in a separate `claude mcp add` step, with their token sourced from their project Settings page.

## Layout

```
.claude-plugin/marketplace.json    marketplace manifest — lists plugins
plugin/                            single plugin
├── .claude-plugin/plugin.json     plugin manifest (name, version)
├── skills/<name>/SKILL.md         skill definitions (auto-trigger via description)
└── commands/<name>.md             explicit slash commands (/handover, /issue, ...)
```

The `owner/repo`-style install (`/plugin marketplace add josef32/opflow-claude-plugin`) requires `.claude-plugin/marketplace.json` at the repo root; the marketplace's `plugins[0].source` then points at the plugin's directory (`./plugin`).

## Why a separate package

- Source-of-truth lives in this repo; no drift between in-repo dev and external users.
- Versioned at `1.0.0` (mutable tip) — `/plugin update` always re-fetches latest.
- Keeps skill content auditable as ordinary files in CI.

## Publishing

Mirror this directory to the public `josef32/opflow-claude-plugin` GitHub repo when contents change. (Automation TBD; the simplest path is a git subtree push or a small CI job.)

## See

- Plan: orchestrator project plan #36 — *Onboarding via Claude Code Plugin (per-user marketplace URL)*.
