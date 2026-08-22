# Calm GTM — Complete local acceptance report

**Acceptance date:** 2026-08-22
**Scope:** source skill, installer, CLI, local memory, four GTM models, derived
tracker, compatibility baseline, and real project assets.
**Result:** PASS for the complete deterministic local contract.

## Product contract verified

1. Strategy is always APOP: Alignment, Positioning, Offer, Promotion.
2. The strategy output contains one thesis and exactly the immutable 12
   questions from `references/apop-questions.csv`.
3. Clarification is conversational and may continue as needed, but it never
   creates a thirteenth strategy field.
4. The action plan exists only after explicit strategy agreement and always
   uses Now / Next / Later.
5. Each horizon contains at most three actions.
6. An asset exists only when an agreed action needs it and the founder
   separately requests it or explicitly approves its short brief. Plan
   agreement alone never authorizes asset generation.
7. The weekly check-in always uses five visible sections and does not rewrite
   APOP on weak evidence.
8. `overview.md` and opt-in `dashboard.html` are derived local views, never a
   fifth source of GTM state.
9. No account, hosted dashboard, CRM, external sync, database, Notion, or
   Airtable is required by the core.

## Reference journey and deliverable documents

| Gate | Evidence | Documents present |
|---|---|---|
| Installation | [01 — initialized](golden-path/relaycert/snapshots/01-initialized/.calm/) | `intake.md`, `sources.md`, `overview.md` |
| Founder intake | [02 — intake complete](golden-path/relaycert/snapshots/02-intake-complete/.calm/) | intake preserved; no premature strategy |
| Strategy proposed | [03 — strategy proposed](golden-path/relaycert/snapshots/03-strategy-proposed/.calm/) | `strategy.md`, `strategy.csv`; no plan |
| Strategy agreed | [04 — strategy agreed](golden-path/relaycert/snapshots/04-strategy-agreed/.calm/) | unchanged 12 answers; approval metadata only |
| Plan proposed | [04a — plan proposed](golden-path/relaycert/snapshots/04a-plan-proposed/.calm/) | `action-plan.md`, `action-plan.csv`; execution locked |
| Plan agreed | [04b — plan agreed](golden-path/relaycert/snapshots/04b-plan-agreed/.calm/) | unchanged plan; no asset before separate approval |
| Asset approved | [05 — plan and asset](golden-path/relaycert/snapshots/05-plan-and-asset/.calm/) | `assets.csv` and finished outreach asset after explicit founder approval |
| Weekly check-in | [06 — weekly](golden-path/relaycert/snapshots/06-weekly/.calm/) | `weekly.md`, `weekly.csv`; APOP unchanged on weak evidence |
| Optional HTML | [07 — HTML opt-in](golden-path/relaycert/snapshots/07-html-opt-in/.calm/) | regenerated `overview.md` and local `dashboard.html` |

The complete founder-to-weekly conversation is recorded in
[conversation.md](golden-path/relaycert/conversation.md). The
machine-verifiable semantic rules are in
[acceptance.md](golden-path/relaycert/acceptance.md).

## Final deliverable bundle

The final accepted `.calm/` state is
[07-html-opt-in/.calm/](golden-path/relaycert/snapshots/07-html-opt-in/.calm/):

- [intake.md](golden-path/relaycert/snapshots/07-html-opt-in/.calm/intake.md)
- [strategy.md](golden-path/relaycert/snapshots/07-html-opt-in/.calm/strategy.md)
  and [strategy.csv](golden-path/relaycert/snapshots/07-html-opt-in/.calm/strategy.csv)
- [action-plan.md](golden-path/relaycert/snapshots/07-html-opt-in/.calm/action-plan.md)
  and [action-plan.csv](golden-path/relaycert/snapshots/07-html-opt-in/.calm/action-plan.csv)
- [weekly.md](golden-path/relaycert/snapshots/07-html-opt-in/.calm/weekly.md)
  and [weekly.csv](golden-path/relaycert/snapshots/07-html-opt-in/.calm/weekly.csv)
- [sources.md](golden-path/relaycert/snapshots/07-html-opt-in/.calm/sources.md)
- [assets.csv](golden-path/relaycert/snapshots/07-html-opt-in/.calm/assets.csv)
  and [finished outreach asset](golden-path/relaycert/snapshots/07-html-opt-in/.calm/assets/outreach-owner-v1.md)
- [overview.md](golden-path/relaycert/snapshots/07-html-opt-in/.calm/overview.md)
  and [dashboard.html](golden-path/relaycert/snapshots/07-html-opt-in/.calm/dashboard.html)

## Real asset construction verified

[The project-asset fixture](fixtures/project-asset/) proves that Calm does not
merely return a prompt when an agreed action requires a code deliverable and
the founder explicitly asks Calm to build it:

- the agreed action is `ACT-001`;
- `assets.csv` records `ASSET-001` and the real primary file;
- `.calm/assets/ASSET-001.md` lists every affected project path;
- `site/index.html` and `site/styles.css` are finished project files;
- `tests/landing-page-smoke.sh` verifies the delivered page;
- the copy states that the offer is under validation and invents no proof.

This fixture demonstrates capability, not a universal landing-page, owned
distribution, or search recommendation.

## Executed test matrix

| Area | Verified behavior |
|---|---|
| Golden path | all gates, fixed schemas, 12 questions, max three actions per horizon, separate strategy/plan/asset approvals, evidence discipline |
| Live semantic conversation | one local Codex forward-test completed intake, material clarification, the exact 12-question APOP strategy, separate strategy and plan approvals, one approved asset, and a weak-signal weekly review without changing APOP |
| Clean-room installation | installed current CLI version, portable user and project skills, canonical questions, project `AGENTS.md` |
| CLI | TTY/non-TTY, Codex/Claude/fallback, intake, status, HTML, ancestor roots |
| Existing projects | no repeated onboarding, proposed-plan lock, asset-index reread before revisions, legacy schema preservation |
| CSV safety | one shared production parser; quoted commas and quotes supported; multiline physical records rejected atomically; last valid tracker preserved |
| Assets | finished text asset, multi-file project asset, monotonic IDs, existing-row preservation, `Superseded` lifecycle |
| Weekly | five sections, stable strategy on weak signals, strong-change semantic contract |
| Installer | fresh install, reinstall, v1.1 migration, upgrade, absolute and relative homes, spaces, conflicts, complete runtime package, legacy-copy warnings, permissions, network errors |
| Portability | complete suite on macOS; all applicable tests in an isolated Linux container; the v1.1 Git-archive fixture is skipped there because that image has no Git, while the same migration test passes on macOS; POSIX syntax checked with `sh`, `dash`, and `bash` |
| Site boundary | route success/502/504 tests, lint, and a production Next.js Webpack build pass; the public pin is updated only after the matching immutable tag exists |

Commands:

```sh
sh tests/run.sh
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py .
npm run lint # from the site repository
npm test # from the site repository
./node_modules/.bin/next build --webpack # from the site repository
```

## Explicit boundaries

- Native Windows remains outside shell-based V1; a future `install.ps1` is a
  separate decision.
- A script cannot inject a conversation into every graphical coding-agent UI;
  the universal baseline is the terminal, with automatic handoff only for a
  compatible coding-agent CLI and an explicit copy-paste fallback for every
  other coding agent.
- The live Codex forward-test validates one compatible CLI path. It does not
  imply that every coding agent or graphical interface supports automatic
  prompt injection; other agents retain the same terminal and copy-paste
  fallback contract.
- Commit, tag, push, site pin change, deployment, and public installation
  verification remain separate release actions performed only after explicit
  publication approval.
