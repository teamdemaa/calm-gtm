# Multi-skill foundation contract

This repository distributes a small family of independent agent skills. It is
not a shared application platform.

## Boundaries

- `calm-gtm` remains the default and keeps its four models: APOP strategy,
  action plan, founder-approved assets, and weekly update.
- Add-ons live under `skills/<name>/`. They may consume founder-approved Calm
  outputs as files, but they do not add state, fields, or behavior to the core.
- No application database, API, authentication, product code, or private
  application asset belongs in this repository.
- A skill bundle is lightweight. Large runtimes and brand packs are separate,
  optional packages and are never installed by selecting a skill.
- Every mutation gate belongs to the skill that performs the mutation. An
  add-on must not interpret a Calm plan or asset approval as authorization for
  an unrelated external action.

## Registry

`skills/registry.tsv` is the installation allow-list. Each non-comment line is
pipe-delimited and has five fields:

```text
name|source|default|layout|quick_validate
```

- `name` is a lowercase skill identifier containing letters, digits, and
  hyphens.
- `source` is a relative directory that cannot escape the repository.
- `default` is `yes` or `no`. Only `calm-gtm` is installed by default.
- `layout` is `core` for the root Calm package or `bundle` for an add-on.
- `quick_validate` is an executable POSIX shell validator relative to the
  repository root.

The core layout installs `SKILL.md`, `references/`, and its single
`scripts/quick_validate.sh`. A bundle installs `SKILL.md` plus any present
`agents/`, `assets/`, `references/`, and `scripts/` trees. Files outside those
paths are never copied into agent skill locations.

## Installer contract

`scripts/install.sh` supports repeatable `--skill NAME`, `--all-skills`, and
repeatable `--target agents|codex|claude|all` options.

- With no skill option, only registry entries marked `yes` are selected.
- With no target option, the backward-compatible portable `.agents` target is
  installed and Claude is added only when its home or CLI is detected.
- `agents` installs both the user copy and the project copy, then adds an
  idempotent per-skill block to the project's `AGENTS.md`.
- `codex` and `claude` install user copies under their native skill roots.
- The same skill may be installed into several targets. Each copy has its own
  content manifest and can evolve independently.
- An unchanged managed copy may be upgraded and obsolete managed files may be
  pruned. A modified or unmanaged copy is preserved and reported as a
  conflict. One conflict never authorizes overwriting another target.
- Unknown skills, malformed registry rows, escaping paths, incomplete bundles,
  and invalid release archives fail before user or project mutation.

## Validation contract

Every registry entry owns a `quick_validate` script. It must be deterministic,
offline, and fast enough for local preflight. `scripts/validate-skills.sh`
validates the registry itself, rejects symlinks in installable bundles, checks
that frontmatter names match registry names, and runs every skill validator.

The full acceptance suite remains the release gate. Quick validation is a
package-level preflight, not a substitute for behavioral and installation
tests.

## Planned add-on order

1. `calm-prospect-ethically`: prove the generic bundle, configuration, mutation
   gates, deduplication, opposition handling, and public-source evidence model
   without external sending.
2. `calm-produce-video`: reuse the proven bundle contract, then add explicit
   optional runtime and brand-pack interfaces without embedding either.

Keeping that order exercises the safety and portability contract before the
more complex runtime boundary is introduced.
