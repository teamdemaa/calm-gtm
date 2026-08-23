# Calm GTM

Calm GTM is a portable, evidence-driven GTM partner for founders building
vertical SaaS. It turns natural founder context into four stable outputs:

1. an APOP strategy: Alignment, Positioning, Offer, and Promotion;
2. a Now / Next / Later action plan derived from the agreed strategy;
3. only assets the founder explicitly asks for or approves, when an agreed
   action requires them;
4. a weekly check-in that learns from evidence without overreacting.

Everything stays in plain local files. The core requires no account, API key,
database, CRM, Notion workspace, hosted dashboard, or external sync.

## Install

Run this from the project where you want Calm GTM:

```sh
curl -fsSL https://calmgtm.com/install | sh
```

The installer adds the `calm` CLI, installs the skill in supported agent
locations, initializes `.calm/`, and starts the first handoff when an
interactive compatible CLI is available.

For automation or a non-interactive setup:

```sh
curl -fsSL https://calmgtm.com/install | sh -s -- --no-start
```

Set `CALM_GTM_HOME` to use an alternate user-home root. Set
`CALM_GTM_TELEMETRY=0` to disable the fail-open completed-install event.

### Skills and targets

The repository has a multi-skill installer, but `calm-gtm` is the only skill
installed by default. Once an optional add-on is registered by its own release
lot, it must be selected explicitly:

```sh
./scripts/install.sh --skill calm-prospect-ethically --target agents --no-start
./scripts/install.sh --skill calm-produce-video --target codex --no-start
./scripts/install.sh --all-skills --target all --no-start
```

`--skill` and `--target` may each be repeated. Supported targets are the
portable user and project `.agents` locations, the user `.codex` location, and
the user `.claude` location. With no target option, the installer preserves the
existing behavior: it installs `.agents` copies and adds Claude only when
detected.

Every skill copy has an independent content manifest. An unchanged managed
copy can be upgraded; a locally modified or unmanaged copy is preserved and
reported instead of being overwritten. Selecting only an add-on does not
initialize `.calm/` or start the Calm GTM workflow.

## First run

Run `calm init` in a terminal. The first question appears there:

> Tell me what you’re building, where you are today, and what feels hardest right now. Write naturally — I’ll ask only what I need.

The CLI records the intake. The current adapters can pass a static handoff to
Codex or Claude Code when their command-line entrypoint is available; every
other coding agent receives the same printable handoff. This adapter list is
not a product dependency. The skill—not the CLI—reads sources, separates facts
from hypotheses, asks material clarifying questions, and produces the GTM work.

The portable promise is the terminal question and local handoff. No installer
can universally inject a new conversation into an already-open graphical
coding-agent interface. When no compatible CLI is available, Calm prints the
handoff to paste into the agent the founder uses.

Clarification stays conversational. The persisted strategy always contains one
thesis and the same 12 canonical APOP questions; no clarification creates a new
strategy field. Strategy agreement and plan agreement are separate explicit
founder turns.

```sh
calm init
calm init --no-start
calm init --intake founder-context.txt --no-start
calm init --agent codex
calm status
calm status --html
```

`calm init` is idempotent and does not repeat onboarding when a strategy is
already present. `calm status` regenerates the universal local overview.
`--html` additionally creates an optional static local view—never a hosted
dashboard or a second source of truth.

## Local files

```text
.calm/
  intake.md
  overview.md
  dashboard.html       # optional, derived
  strategy.md
  strategy.csv
  action-plan.md
  action-plan.csv      # authoritative action rows and statuses
  weekly.md
  weekly.csv
  sources.md
  assets.csv          # history-preserving index; Draft / Final / Superseded
  assets/
```

The four models remain the source of GTM judgment. `overview.md` and
`dashboard.html` are disposable derived views.

Assets are never produced from plan approval alone. When an agreed action needs
one, Calm names a short asset brief in the conversation and waits for the
founder to approve or change it. A sufficiently specific direct request from
the founder also counts as approval. Only then does Calm create the finished
text deliverable under `.calm/assets/` or build an approved landing page,
directory, blog, newsletter, or other code asset in the real project. A prompt
is only an explicit request or a fallback when the target cannot be accessed.

## Compatibility

The portable baseline on macOS, Linux, and WSL is installation, the terminal
question, `.calm/` files, a project skill under `.agents/skills/calm-gtm`, and
an `AGENTS.md` pointer.

- **Codex CLI:** native skill discovery and automatic CLI handoff.
- **Claude Code:** personal skill installation and automatic CLI handoff when
  the `claude` command is available.
- **Other coding agents that read `AGENTS.md`:** portable project instructions
  and files; start the conversation manually in that agent.
- **Graphical agent interfaces:** no script can universally inject a message
  into an already-open GUI. Calm prints an honest manual handoff instead.
- **Native Windows:** not part of this shell-based V1. A separate
  `install.ps1` should be considered before claiming native Windows support.

The installer preserves locally modified managed copies and reports a conflict
instead of silently overwriting them. It also migrates the legacy Calm GTM
`AGENTS.md` block without creating duplicates.

## Repository contract

`tests/golden-path/relaycert/` is the acceptance journey from installation to
weekly check-in. Its snapshots are the semantic contract; deterministic tests
cover state gates, schemas, installation mechanics, and derived views.
`tests/ACCEPTANCE-REPORT.md` is the human-readable delivery document linking
the full journey, final `.calm` deliverables, real project-asset fixture, test
matrix, and remaining publication boundaries.

The packaging and extension boundaries are specified in
[`docs/multi-skill-foundation.md`](docs/multi-skill-foundation.md). The skill
allow-list lives in `skills/registry.tsv`; each registered skill owns a fast,
offline `quick_validate` script, and `scripts/validate-skills.sh` runs them all.

## Learn more

- [Calm GTM](https://calmgtm.com)
- [Vertical SaaS ideas](https://calmgtm.com/ideas)
- [Journey](https://calmgtm.com/experiments)
