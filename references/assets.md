# Model 3 — Assets

Only create an asset when it's listed as a **Deliverable** on an agreed
action in `.calm/action-plan.md`. Don't produce every asset that could
plausibly exist — the plan defines what's needed, not this list.

Save each asset as its own file under `.calm/assets/` (e.g.
`.calm/assets/outreach-message-v1.md`), so it can be referenced, reused, and
revised independently.

Also add one row to `.calm/assets.csv` (create it with the header row below
if it doesn't exist yet; never delete prior rows) as a plain index of what
exists, not the content itself. Use exactly this header row, in this order,
every time — never rename, reorder, add, or remove columns:

```
Asset Name,Category,Purpose,Linked Action,File,Status
```

`Status` is `Draft` or `Final`. This is how a founder sees, at a glance,
everything that's been produced without opening every file.

Every asset must inherit the currently agreed ICP, positioning, offer, GTM
motion, and tone from `.calm/strategy.md` — don't reinvent messaging
per-asset. If the material the founder supplied (website copy, LinkedIn
bio, deck) contains language that already resonates, reuse and sharpen it
rather than writing generic copy from scratch.

## Categories

**Messaging** — core message, elevator explanation, outreach message,
follow-up, partnership message, referral request, customer interview
invitation.

**Website** — landing page structure, hero copy, value proposition, proof
section, CTA, pricing explanation.

**Sales** — discovery call guide, demo narrative, objection handling, pilot
offer, follow-up summary.

**Paid acquisition** (only when paid is part of the agreed strategy) —
campaign hypothesis, audience, keywords, creative angle, ad copy, landing
page, budget test, conversion event, stop/continue criteria.

**Content or generosity** (only when relevant to the agreed motion) — the
founder's high-value free asset: benchmark, useful research, template,
calculator, teardown, guide, free tool, educational resource. Something
genuinely useful on its own, not a thin excuse to collect an email.

## Output format

Every asset starts with this header block, then the finished asset itself:

```markdown
**Purpose:** Why this asset exists.
**Audience:** Who it is for.
**Desired action:** What should happen after someone encounters it.
**Message:** The core idea it must communicate.

---

[the finished asset]
```

Avoid generic copy — every asset should read as if it were written for this
specific founder's specific customer, not a template with the blanks filled
in.
