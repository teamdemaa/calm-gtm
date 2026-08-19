# Model 1 — APOP Strategy

The strategy is the foundation everything else depends on. Do not build the
action plan or any assets until the founder has explicitly agreed with it.

APOP (Alignment, Positioning, Offer, Promotion) is your internal reasoning
model — don't present it to the founder as a questionnaire. Extract as much
of it as possible from what they've told you and whatever you fetched from
their website/LinkedIn/materials; ask only about what's missing and
material.

Write the strategy to `.calm/strategy.md`, replacing the previous version if
one exists (the *history* of what changed lives in `.calm/weekly.md`'s
"Strategy changes" notes, not in multiple copies of the strategy file).

Also append 12 rows to `.calm/strategy.csv` (create it with the header row
below if it doesn't exist yet) — one row per question in the extraction
checklist below, every time you write or revise the strategy. Unlike
`strategy.md`, this file is append-only: never delete or overwrite prior
rows, so the founder can filter by period and see how each answer evolved.
Use exactly this header row, in this order, every time — never rename,
reorder, add, or remove columns:

```
Period,Area,Question,Answer
```

`Period` is the date of this version of the strategy. `Question` must match
the checklist question verbatim, word for word — never paraphrase it.

## Internal extraction checklist

These are the exact questions you're trying to answer for each APOP area,
before you ask the founder anything. They are for your own reasoning, not a
form to hand the founder verbatim — extract as much as you can from what
they already told you and whatever you fetched, and only surface the ones
still unanswered, in natural conversation. Keep these three per area fixed;
don't swap them for different questions.

**Alignment**
1. What do you want this company to bring you?
2. What are you particularly good at, and how do you know?
3. What constraints are you working with right now: time, money, energy?

**Positioning**
1. Who do you want to serve as a priority?
2. What important problem are you solving for them?
3. What does the customer do today instead, and what makes your way of solving it different?

**Offer**
1. What concrete outcome is the customer coming for?
2. What exactly does the offer include?
3. What's the price, how is it billed, and is it validated or still a hypothesis?

**Promotion**
1. How do the right customers discover you?
2. What helps them move to purchase?
3. How do you nurture the relationship to encourage repeat purchase and referral?

## Output format

Use this structure every time:

```markdown
## Calm GTM Strategy

### GTM thesis
One short paragraph: who we're starting with, what important problem we're
solving, what they should buy, and how we believe we can reach and convert
them.

## A — Alignment

### The company we are trying to build
What the founder wants this business to become — lifestyle vs. venture
scale, profitability goals, desired founder involvement, team size, time
horizon, founder energy/constraints.

### Founder advantage
What the founder or team is particularly good at. Only state strengths
backed by what they told you or what you found on their site/LinkedIn —
never invent one.

### Founder role
What the founder should keep doing personally for now, and what should
eventually become repeatable/independent of them.

## P — Positioning

### Starting ICP
The smallest useful starting customer group — specific, not "startups" or
"small businesses" unless the evidence genuinely supports that breadth.
Include where relevant: company type, size, role/persona, context, trigger,
current behavior, pain signal, disqualifiers.

### Important problem
The problem in the customer's own language — prioritize the problem they
care about over the mechanism of the product.

### Current alternative
What the customer does today instead: another product, manual work,
spreadsheets, agencies, internal process, or nothing at all.

### Positioning
One concise statement: who this is for, what important outcome/problem it
addresses, and why this approach is meaningfully different.

### Why this could win
The current strategic advantage. Label hypotheses explicitly as hypotheses.

## O — Offer

### Desired outcome
The concrete result the customer is buying — outcome, not feature list.

### Offer
Exactly what the customer gets.

### Pricing and packaging
The current pricing model or hypothesis. If unvalidated, say so plainly —
including if the only "evidence" is a number on the website.

### Proof required
What evidence would make the offer more credible: customer result,
testimonial, usage proof, ROI, case study, product experience, etc.

## P — Promotion

### Primary GTM motion
Pick one primary route to market (founder-led sales, outbound, paid search,
paid social, PLG, SEO, content, creators, partnerships, community,
integrations, events, referrals, marketplaces...). Choose — don't list.

### Supporting motion
Optional. At most one by default.

### Why this motion
Why it fits the ICP, the buying behavior, the current stage, the
economics — and what still needs to be tested.

### How we earn attention
A genuinely useful way to create relevance or value before asking for a
bigger commitment, only if it's realistic for this business — don't force a
lead magnet that doesn't fit.

### Path to purchase
The likely path: discovery → interest → trust → evaluation → purchase.

### Retention, repeat purchase, expansion, or referral
The post-purchase mechanism that actually matters for this business.

## What we know
The few most important things backed by evidence (founder's own words,
fetched site/LinkedIn content, or prior validated learnings).

## What we believe
The few most important strategic hypotheses — labeled as hypotheses.

## What we need to learn
The key unknowns that could change the strategy.

## What we are deliberately not doing
2–5 things the founder should ignore for now. This is a core part of the
value Calm provides — don't skip it.
```

## Close every strategy with

> This is the GTM strategy I would build around right now.
>
> Do you want to:
> - agree and build the action plan;
> - challenge something;
> - change something?

Do not move into the action plan until the founder agrees, explicitly, in
this conversation.

## Revising an existing strategy

Never rewrite the whole document from scratch when new evidence comes in.
Update only the APOP areas the evidence actually justifies, and log the
change under "Strategy changes" in `.calm/weekly.md` (see
`references/weekly-update.md`), in this form:

> **Positioning changed this week.**
>
> Previous hypothesis: "Support teams need better insight."
> New hypothesis: "Product leaders need a reliable way to know which
> support problems deserve roadmap attention."
>
> Why: 7 of 9 customer conversations reacted more strongly to the second
> problem.

If the revision happens outside the weekly rhythm, add a new entry to
`.calm/weekly.md` for it rather than skipping the log — don't create a
separate decisions file.
