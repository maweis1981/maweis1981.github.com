---
layout: post
title: "I Moved My Development to Phones: Notes From the AI Perpetual Motion Machine"
subtitle: "One project, one phone. A few Claude Code sessions running in parallel. And then GitHub flagged my AI as abuse."
date: 2026-05-20
author: Max (Ma Wei)
location: Singapore
series: AI-Native Engineering
part: 1
categories: [AI-Native Engineering]
tags:
  - AI-Native Engineering
  - Claude Code
  - Agentic Workflow
  - Software Engineering
  - Developer Tools
canonical_url: https://maweis.com/ai-native-engineering/01
---

## Notes From the AI Perpetual Motion Machine

---

**TL;DR**

1. In the Vibe Coding era, **code is stateless**. It can be discarded at any time before delivery.
2. **The bottleneck isn't the AI. It's the toolchain underneath it.**
3. AI isn't replacing engineers. **AI is replacing the tools designed for engineers.**

The rest is the argument.

---

## A Weird Picture

My current development setup probably looks insane.

**A few phones spread across my desk. Each one runs a Claude Code session for a different project. And one phone, dedicated entirely to watching TestFlight.**

I used to be a heavy user of `ghostty + fish + claude code` CLI — all local terminal, all the time.

Then I started running multiple projects in parallel with an agent-team approach. The terminal model broke down.

Not because it couldn't technically handle it. Because **my attention couldn't**.

Switching projects = switching context = switching the agent's working memory = switching my own brain.

So I made a rule:

> **One project, one phone.**

Each phone keeps Claude Code in the foreground, always there, always one tap away. Like a row of cubicles, each with its own Claude inside, doing its own work.

I'm based in Singapore. What I'm actually working on, beyond shipping product, is this:

> **What should software engineering look like in the AI era?**

This post is field notes from someone trying to figure that out in real time.

---

## Why So Many Phones?

This is the question I get most. So let's start here.

### The Real Reason: Avoiding Context Switching

When you run multiple sessions on one device, every switch means:

- Claude has to reload the context
- The agent has to re-understand what you were just doing
- You have to mentally re-enter the project

**Humans switch. AIs switch. Both get dumber.**

This is context-switching cost, but amplified — because in the AI era, every "window" you switch between has its own working memory loading up behind it.

So the rule is brutal in its simplicity: **one project, one phone**.

### The Phone Isn't a Dev Machine — It's a Remote Control

Let me be clear about this — **the phones aren't doing the actual development**.

Claude Code runs in a cloud environment. Code, builds, tests, deploys — all in the cloud.

**The phones only do three things:**

- Display the current session state
- Take my instructions and forward them to Claude
- Push Claude's output back to my eyes

The cloud does the work. The phones do the pointing.

That's it.

### The Special Phone: The Product Window

There's one more phone on the desk. **It doesn't run Claude. It runs TestFlight.**

We build AI products at [NGMOB](https://ngmob.com) — including [Kolens](https://kolens.ai) and [GoGlow AI](https://goglowai.com).

Claude writes the code → CI/CD ships → a new build pushes to TestFlight automatically.

That phone just sits there, TestFlight always open.

When a new build arrives, I tap update, and I can see what Claude did in the last hour. Live.

**One phone produces, another phone verifies.** The entire perpetual motion loop closes on my desk.

---

## The First Principle: State vs Stateless

Now the foundation.

The core of this paradigm isn't Claude. Isn't MCP. Isn't phones. It's one sentence:

> **Code, during the Vibe Coding stage, is stateless.**

In traditional development, code is stateful.

Every line matters — because a human wrote it, and every line is condensed thinking. So we commit it, review it, protect it, test it, version it in Git with full history.

Vibe Coding breaks this assumption.

**Code that Claude writes can be discarded at any point before delivery.**

It has no "author authority." Its only meaning is one thing — **whether it can reach production and create real value**.

Code that doesn't make it to production — no matter how clean, no matter how well-commented — **is just stateless intermediate output**.

### The Whole Engineering Logic Inverts

Once you accept this, the design logic of the entire engineering system flips:

| Dimension | Traditional Dev | AI Perpetual Motion |
|---|---|---|
| **Core asset** | The code | **The delivery pipeline** |
| **Source of truth** | Commit history | Issue history |
| **What review protects** | Code quality | **Intent correctness** |
| **Unit of collaboration** | The PR | **The product feature** |
| **Pace philosophy** | Slow craft | **Perpetual motion + closed-loop verification** |
| **Version control goal** | Recover history | **Trace intent** |

This table is worth reading twice.

It's not saying "traditional dev is bad."

It's saying — **when the way code gets produced changes, the entire order built around code must be realigned.**

### What "Discarding Stateless Code" Actually Looks Like

Concretely.

I ask Claude to implement a feature on a feature branch. It modifies 40 files in a cloud session, runs 100 test cycles, and produces 5 different versions of the implementation along the way.

**4 of those 5 versions get thrown away by Claude itself.**

Only the final version — the one that runs, passes tests, meets the acceptance criteria — ever gets pushed.

The other 4 never touch GitHub. Nobody ever needs to know they existed.

They are genuinely stateless intermediates — **existing only briefly inside Claude's session memory**.

This kind of disposal is unthinkable in human collaboration.

Can you imagine a human engineer saying "most of what I wrote today, I'm just throwing out"?

But for an agent, that's the default behavior.

**This is the deepest semantic split between Vibe Coding and traditional programming.**

---

## What the Whole System Actually Looks Like

Everything lives in the cloud. The existing engineering stack is reused. But **the role of each layer is reassigned.**

### Layer 1: GitHub Is the Foundation — But Issues Matter More Than Code

GitHub still holds the code, of course.

But in my system, **what GitHub really carries is the issues**.

Every dev task is bound to an issue. The AI's reasoning, alternative solutions, implementation notes, test results, failure modes, retry strategies — **all of it lives in the issue**.

**Issues are the knowledge base. Code is just one output of an issue.**

This inversion matters.

Code will be rewritten endlessly as the product evolves. But the reasoning in the issue — *why this approach* — **never expires**.

When a future agent picks up the project, what it reads first isn't the codebase. **It's the issue history.**

### Layer 2: All Claude Code Sessions Run in the Cloud

Not on my laptop. Not on my phone.

Cloud sessions mean:

- No dependence on any single device
- True parallel sessions across multiple projects
- When a feature is done, **immediately start a fresh session to keep Claude sharp**

That last one is critical.

Long sessions get dumber as context accumulates. This is a fundamental limitation of current LLMs.

So **proactively killing old sessions and starting new ones** is itself a piece of engineering discipline.

Each session is like a disposable container: comes in clean, does one thing, gets thrown away.

### Layer 3: The Delivery Pipeline Must Close on Day One

This is the easiest part to skip, and the most fatal.

> **However fast Vibe Coding goes, if the code can't be delivered to preview / production / TestFlight, it's all stateless garbage.**

So on day one of any project, you must wire up:

- GitHub Actions deploy pipeline
- Pick one: Cloudflare / Vercel / Railway / Fly.io — make services discoverable and reachable
- For mobile, automate the TestFlight / Internal Testing push
- If you can expose your APIs as **MCP servers**, **the second flywheel of the perpetual motion machine starts spinning**

That last point needs explaining.

**In this paradigm, MCP isn't a development tool. It's the runtime interface of your product.**

When your own product's services are exposed via MCP, Claude can **use MCP to simulate the user-product interaction that would happen during Vibe Coding** — testing what it just wrote, itself.

For our products: if image generation, subscription validation, and user profile APIs are all MCP-exposed, Claude in a cloud session can write code and then immediately simulate a user flow through MCP.

Write → verify → fix → re-verify — **without me in the loop**.

This is the second wheel of the perpetual motion machine.

---

## Why I Call It the "Perpetual Motion Machine"

Stack the layers together and you get this:


```
  Issue (task + acceptance criteria)
       │
       ▼
  Cloud Claude Code session (writes code)
       │
       ▼
  GitHub (push, PR)
       │
       ▼
  CI/CD (deploys to preview / TestFlight)
       │
       ▼
  ┌──────────────────────────────────────┐
  │  MCP calls preview service (autotest) │
  │  or I pick up the TestFlight phone   │
  └──────────────────────────────────────┘
       │
       ▼
  Report back to issue → close or open next
       │
       ▼
  New session starts next task
       │
       └────────────► loop forever
```



**The human only touches two points in this loop:**

1. **The start** — writing the issue (defining intent)
2. **The end** — merging the PR or accepting the TestFlight build (confirming value)

Everything in between is automatic.

That's why I call it the **AI-Driven Perpetual Motion Machine**.

I can sip coffee and glance across the phones to check on each project. The Claude phones are typing. The TestFlight phone is about to receive a fresh build.

**Like watching a few conveyor belts, each with a finished product at the end.**

---

## And Then I Hit a Wall

This is what actually triggered this post.

Parallel development plus rapid iteration triggered **GitHub's rate limit**.

Not because of too many commits. Because **the entire API call pattern got flagged as abuse by GitHub's detection systems**.

The error message was brutally direct:

> `API rate limit exceeded. You have triggered an abuse detection mechanism.`

I stared at the screen for a second, then started laughing.

**GitHub is protecting itself from my AI.**

### GitHub's Rate Limits Were Drawn for Humans

GitHub's abuse detection was designed under 2008 assumptions:

- How many API requests per hour does one developer make? Has a ceiling.
- How many repos does one account operate on in parallel? Has a ceiling.
- Bursts of automated behavior? Trigger anti-abuse.

These ceilings were generous for humans. **For an agent, they break instantly.**

**The ceiling GitHub drew in 2008 was for "the most prolific developer in the world."**

**That ceiling, today, can be hit by a single Claude session running on a single phone, in a single morning.**

And here's the absurd part — there's no way to appeal to GitHub and say "this is my AI."

The system was never designed for that scenario.

It assumes a human that doesn't exist anymore.

### What This Actually Means

After hitting the wall, I kept asking myself:

Why did GitHub break first, and not Claude?

Claude didn't slow down. Didn't get dumber. Didn't error out.

**The thing that broke was the toolchain underneath it.**

Git was designed for humans.
GitHub was designed for humans.
CI/CD triggers were designed for humans.
Even abuse detection was designed for humans.

**The faster AI goes, the sooner it slams into assumptions from 2005 and 2008.**

This is what AI-Native Engineering is *actually* about — not "how to use AI to write code faster," but —

> **How does a toolchain designed for humans accommodate non-human collaborators?**

---

## How I Rebuilt the AI ↔ GitHub Interaction

After the wall, I codified a set of rules.

The core idea fits in one sentence:

> **Reducing API call frequency is 10x more important than reducing commit count.**

(Why 10x? GitHub's rate limits count API calls, not commits. One commit can mean 3-5 API calls behind the scenes. One automated PR check can be 20+ API calls. Reducing commits saves maybe 30%. Optimizing the API pattern saves 90%.)

Here's the skeleton of the rules I actually use today. The full spec ships in the next post.

### 1. Decouple Modification From Submission

Claude can modify, run, and test **as much as it wants** on a feature branch.

But **most of those operations don't touch the GitHub API**.

Only when a feature is complete does it do **one push + one PR**.

Practical implementation:

- Disable all auto-commit / auto-sync / auto-push tools
- Cloud Claude Code session maintains its own working tree, syncing remote only at milestones
- If you use a cloud agent, verify its default is "push when task is done"

### 2. A PR Is a "Product Feature," Not a "Task"

It's no longer one PR per task.

It's **one PR per product feature**.

Reverting PRs from "unit of work" back to "unit of collaboration."

The acceptance test: after this PR merges into main, **can the user perceive one complete value change**?

Yes → this is a reasonable PR.
No → still in intermediate state. Keep stacking on the feature branch.

### 3. CI Triggers on "Ready for Merge," Not Every Push

While a PR is open, **CI doesn't run**.

CI only fires when a human (or another agent with review permission) marks the PR as ready.

GitHub Actions config:


```yaml
on:
  pull_request:
    types: [ready_for_review]
  workflow_dispatch:
```



**Keep 99% of intermediate-state builds out of your billing.**

### 4. Production Deploys Must Be Human-Triggered

Merging to main doesn't deploy.

Production uses `workflow_dispatch`. **Someone has to press the button.**

Press it once a day. Bundle 100 deploys into 1.


```yaml
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy'
        required: true
```


Reasoning: **production stability cannot be a function of AI iteration speed.**

### 5. Issues Are AI's Memory Container

Issues are not todo lists.

Issues are the **persistent working-memory layer** of the agent.

Each issue should contain:

- **Intent** — why this matters (user value / business driver)
- **Acceptance criteria** — how do we know it's done (ideally MCP-verifiable ✓)
- **Solution alternatives** — paths Claude considered
- **Key decisions** — which one was chosen, and why
- **Failure replays** — what was tried, why it didn't work
- **Links** — PR / preview URL / TestFlight build

Written this way, **any new agent can pick up the issue and reconstruct full context from zero**.

That's what it means to use issues as a knowledge base.

---

## AI Agent Behavior Constraints

This is the checklist I use for cloud Claude Code sessions. The full version expands in post #2.

- [ ] **Agent cannot operate directly on `main`** (`git checkout main` / `git push origin main` forbidden)
- [ ] **All agent changes go through `ai/<feature-name>` feature branches**
- [ ] **Squash merge is enforced** (disable merge commits in repo settings)
- [ ] **Commit messages must follow Conventional Commits** (`feat:` / `fix:` / `refactor:`)
- [ ] **No garbage messages** (`update`, `fix`, `wip`, `asdf` are banned)
- [ ] **Agent must search for existing implementations** before creating new components / utils / schemas
- [ ] **No infinite-loop fixes** — cap retry attempts, surface failure reasons, escalate to human
- [ ] **No polling** — agent behavior must be event-driven / webhook-driven / queue-driven
- [ ] **Database migrations on direct connection, runtime on pooled connection** (Neon / Supabase)
- [ ] **No frequent migrations** — aggregate schema changes, run them in batches

Full 16-chapter spec coming in post #2.

---

## This Is Only a Compatibility Layer

Honest take: everything above is a **temporary fix**.

Git and GitHub fundamentally don't suit agents.

The real direction, from what I can observe:

### Semantic Diff

Don't diff the code. Diff the **intent**.

What actually changed between two versions — not "+12 -8 lines," but "added payment flow" or "fixed subscription validation."

### AST Diff

Diff structure, not text.

Refactoring `if (a) b()` into `a && b()` is a major textual diff and a zero AST diff.

AI tends to produce these semantically-equivalent rewrites all the time. **Text diff has terrible signal-to-noise in AI-generated code.**

### Intent-Driven Version Control

One version = one product intent. Not one code modification.

Version numbers, changelogs, rollback units — all organized by intent, not commits.

### Agent-Native Code Hosting

The default user is an agent fleet, not a human.

- Rate limits counted per "task," not per API call
- Review flow designed for agent collaboration
- PR descriptions structured by default, parseable by other agents
- The "throttling conversation" is "declare your agent," not "you're flagged as abuse"

### MCP-First Product Architecture

Products are **callable, testable, and evolvable by AI from day one**.

Soon, a competent SaaS will ship with API + MCP server by default — **the way REST + OpenAPI is the default today**.

---

**When agent-written code crosses 80% of all code, we won't need a better Git. We'll need a different paradigm of version control.**

That paradigm doesn't exist yet.

But **whoever builds it owns the next GitHub.**

---

## Closing

A lot of people are asking: will AI replace engineers?

I think it's the wrong question.

What's actually happening is:

> **AI doesn't replace engineers. AI replaces the tools designed for engineers.**

The moment GitHub flagged my Claude as abuse, I saw the future.

Next is CI/CD.
Then IDEs.
Then issue trackers.
Then docs.
Then cloud consoles.

**An entire generation of infrastructure has to be rewritten.**

And here in Singapore, with phones spread across my desk — some are Claude's cubicles, one is the product's window — **I'm standing right at the watershed.**

We're hitting walls because we're running at the front.

---

## Series Roadmap

This is post #1 of the **AI-Native Engineering** series.

What's coming:

- **#2** The full *AI Agent Git / GitHub Workflow Spec* — 16-chapter operational manual, with fork-ready GitHub config templates
- **#3** Why traditional software engineering doesn't fit AI agents — the paradigm leap from stateful to stateless, from request-driven to event-driven
- **#4** The future of software is not apps. It's intent systems
- **#5** AI-Native Engineering — the synthesizing manifesto

---

## About the Author

Max ([@maweis1981](https://github.com/maweis1981)) — independent developer, founder of [NGMOB](https://ngmob.com) (products include [Kolens](https://kolens.ai) and [GoGlow AI](https://goglowai.com)).

Based in Singapore. Builds AI products at NGMOB using the perpetual motion machine model, and researches the evolution of **AI-Native Engineering** in parallel.

- Site: [maweis.com](https://maweis.com)
- GitHub: [github.com/maweis1981](https://github.com/maweis1981)

> If this resonated, star the series repo and forward it to someone running into the same walls. The series is also published in Chinese on WeChat — [maweis.com](https://maweis.com) is the canonical version.

---

*Copyright © 2026 Ma Wei. Licensed under CC BY 4.0.*
*Quote, translate, reference freely — please link back.*
