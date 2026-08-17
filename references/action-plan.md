# Model 2 — Action Plan

Only build this once the founder has explicitly agreed to the strategy in
`.calm/strategy.md`. Every action plan must derive directly from that
strategy's APOP — see the action-plan rule in the main SKILL.md.

Write the plan to `.calm/action-plan.md`, replacing the previous version
(history lives in `.calm/decisions.md` and in `.calm/weekly.md`'s
priorities-over-time, not in multiple copies of this file).

Don't produce a sprawling six-month task list. Use three horizons, with
precision decreasing the further out you go:

- **Now — next 30 days.** Very concrete.
- **Next — days 31–90.** Clear objectives and deliverables.
- **Later — months 4–6.** Direction, milestones, decision points — not fake
  precision.

## Output format

For each horizon:

```markdown
### Objective
One clear objective for the period.

### Why this matters
One short sentence tying it back to the GTM thesis.

### Actions
```

For each action, use exactly these fields:

```markdown
**Action:** What exactly needs to happen.
**Why:** Why it matters to the GTM thesis.
**Responsible:** Founder / cofounder / marketing / sales / product / named person.
**Due:** Specific date or week.
**Deliverable:** The tangible output.
**Success signal:** What would indicate real progress or a useful learning.
**Status:** Not started / In progress / Done / Blocked.
```

Example:

> **Action:** Interview 10 Heads of Product matching the ICP.
> **Why:** Validate whether the problem is sufficiently painful and urgent.
> **Responsible:** Founder.
> **Due:** Week 2.
> **Deliverable:** 10 completed conversations + notes.
> **Success signal:** At least 5 independently describe the same problem and 2 show willingness to test or pay.
> **Status:** Not started.

## The rule

Every action must connect to at least one APOP area (Alignment,
Positioning, Offer, or Promotion). If it doesn't, question whether it
belongs in the plan at all — this is how Calm avoids generating busywork.

## Assets inside the plan

When an action requires a deliverable that needs actual copy or a page or a
campaign (not just a task like "run 10 interviews"), list it as a
**Deliverable** in the action and then produce it using
`references/assets.md`. The asset library is generated from execution
needs surfaced here — never build assets speculatively, ahead of an action
that needs them.

Example:

> **Action:** Test new positioning with the first 20 target accounts.
> **Deliverables:** Outreach message v1 + landing page v1.
