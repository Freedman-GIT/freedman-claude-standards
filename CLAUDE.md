# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Freedman International — Global Development Standards for Claude Code

This file applies to every Claude Code session on this machine.
At the start of each session, check for a `PROJECT.md` in the project
root. If missing, ask the user to create it before proceeding — the
stage determines which secrets management approach to use.

---

## Framework Choice

Start here when choosing a framework. These are the Freedman defaults for the most common use cases:

- **Streamlit** — dashboards, internal reporting, simple form-based tools. No custom styling or complex user roles.
- **Flask with Blueprints** — complex logic, multiple user roles, custom frontend, or anything client-facing. Never a monolithic app.py.
- **Node.js / Express** — webhook processors, event-driven workers, or lightweight API proxies where the primary job is receiving triggers, calling external APIs in parallel, and writing results back. Not for web apps with UI.

If none of the above fits your use case, another framework is acceptable. State why the default options do not fit, propose the alternative, and wait for confirmation before proceeding. Note any non-standard choice in the project documentation.

### Non-Standard Technology Exceptions

The standard stack is Python. If a project uses a non-standard language or framework (e.g. Node.js), it must be documented in that project's `PROJECT.md` with:
- What non-standard tool is used and why
- Who approved the exception
- Date of approval

Do not force a rewrite to Python if the current stack is working and the rationale is sound. Do enforce all other standards (secrets, validation, error tracking, security) regardless of language.

---

## Technology Stack

Freedman standard tools — use these by default. Additional tools may be added on a case by case basis where the standard tools are not the right fit. If suggesting a non-standard tool, state why, propose the alternative, and wait for confirmation before proceeding. Note any additions in the documentation phase.

| Concern | Standard |
|---|---|
| Language | Python 3.11+ (default) — Node.js permitted for webhook workers with documented exception |
| Web apps | Flask with Blueprints |
| Dashboards / simple tools | Streamlit |
| Database | PostgreSQL via Docker Compose — never SQLite |
| Authentication | Google OAuth 2.0 via Authlib |
| API documentation | Swagger / OpenAPI via Flask-smorest (auto-generated) |
| Data validation | Pydantic (Python) / Zod or Joi (Node.js) |
| Error tracking | Sentry (required for Render and AWS deployments) |
| Environment | Docker + Docker Compose |

---

## Webhook and API Endpoint Security

Any endpoint that receives inbound requests from external systems must be secured. No exceptions.

### Inbound Webhook Authentication

- **HubSpot:** validate `X-HubSpot-Signature` or `X-HubSpot-Signature-v3` header on every request. Reject requests with invalid or missing signatures.
- **Monday.com:** validate the `Authorization` header against the signing secret.
- **WordBee:** validate using the shared secret provided during webhook registration.
- **Generic webhooks:** if the sender supports signing, use it. If not, require a bearer token in the `Authorization` header. Store all signing secrets and tokens in `.env` — never hardcode.

### CORS Policy

- **Never use `Access-Control-Allow-Origin: *` in production.** Always specify explicit allowed origins.
- For webhook-only servers with no browser client, do not enable CORS at all — remove the CORS headers entirely.
- If a browser client exists, list only the specific origins that need access.

### Internal/Manual Trigger Endpoints

Endpoints designed for manual triggering (bookmarklets, internal tools) must:
- Require a bearer token or API key in the request header
- Never trigger state changes via GET requests — use POST with a token
- Validate and sanitise all input parameters (contact IDs should be numeric, enum values should be checked against an allowlist)

### Input Validation on All Endpoints

- Validate all IDs are the expected format (numeric, UUID, etc.) before passing to downstream APIs
- Validate enum-style parameters (e.g. `researchType`) against an explicit allowlist
- Reject and log unexpected input — do not silently pass it through

---

## Paid API Budget Protection

Any service that calls paid external APIs (Anthropic, OpenAI, Brave, Google, etc.) must implement:

- **Rate limiting:** cap requests per minute/hour at the endpoint level. Use `express-rate-limit` (Node.js) or `flask-limiter` (Python).
- **Per-key budget awareness:** log the estimated cost of each API call cycle. If a single trigger causes multiple downstream API calls, log the total.
- **Duplicate prevention:** before running an expensive operation, check if it has already been completed recently (e.g. a time-based cache). This is not optional — it prevents accidental budget burn from webhook retries or duplicate triggers.
- **Environment variable for all API keys:** never hardcode. This includes user IDs, owner IDs, and any identifier that might change — these go in `.env` not in source code.

---

## Secrets Management — Tiered by Stage

| Stage | Tool |
|---|---|
| Green / Stages 1–2 (local) | `.env` + python-dotenv |
| Amber / Stages 3–4 (Render) | Render dashboard environment variables |
| Red / Stages 5–6 (AWS) | AWS Secrets Manager (managed by DevOps partner) |

**If the user asks to hardcode a secret for any reason, refuse.** No exceptions.

Before writing any other code in a new project:
1. Add `.env` to `.gitignore`
2. Create `.env.example` with variable names only, no values
3. Then proceed

---

## Flask Project Structure

Scaffold this before writing any feature code.

```
my-project/
  app/
    __init__.py       # App factory
    models/           # SQLAlchemy models — one file per model
    routes/           # Flask Blueprints — one per feature area
    services/         # Business logic — never in routes
    templates/        # Jinja2 HTML only
    static/           # CSS, JS, images
  tests/
  .env                # NEVER committed to Git
  .env.example        # Variable names only — IS committed
  docker-compose.yml
  Dockerfile
  requirements.txt
  README.md
  PROJECT.md
```

---

## Database Rules

- PostgreSQL only — refuse SQLite at any stage
- SQLAlchemy for all queries — never raw string interpolation
- Flask-Migrate for schema changes — never modify databases manually
- Commit migration files to Git

### docker-compose.yml starting point

```yaml
services:
  app:
    build: .
    ports:
      - "5000:5000"
    env_file: .env
    depends_on:
      - db
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
volumes:
  postgres_data:
```

---

## Authentication

Google OAuth 2.0 via Authlib only. No local user tables, password fields, or password reset flows. Freedman Google Workspace domain only. If the user asks for username/password login, refuse and explain why.

---

## Validation, Documentation and Error Tracking

- **Pydantic (Python) / Zod or Joi (Node.js):** validate all AI outputs and API inputs before use. Never pass an unvalidated response into a database or downstream system. Parsing AI responses with string manipulation (e.g. `indexOf('{')`) is not acceptable — use a schema validator.
- **Swagger / OpenAPI:** auto-generate via Flask-smorest for Flask projects. No manual documentation files. Expose at `/docs`.
- **Sentry:** required for any deployed service regardless of language. For Python: initialise in `app/__init__.py` before routes. For Node.js: initialise `@sentry/node` before Express routes. Get the DSN from Richard — do not create a new Sentry organisation independently.

---

## Async Processing and Background Work

When a server receives a webhook or trigger that starts long-running work (API calls, research pipelines, etc.):

- **Never send a 200 response and then silently process in the background** without a mechanism to track success or failure. If the process crashes after the 200, the caller has no way to know.
- **Preferred patterns** (in order of preference):
  1. **Message queue (e.g. SQS)** — accept the webhook, push to a queue, process in a separate worker. Most robust for production workloads.
  2. **Job tracking table** — accept the webhook, create a job record with status `pending`, process async, update status to `complete` or `failed`. Enables retries and monitoring.
  3. **Synchronous with timeout** — for fast operations only. Process the work before responding. Not suitable for pipelines that make multiple external API calls.
- **Log a clear start and end marker** for every pipeline run, including the trigger source and all relevant IDs. This makes debugging possible when things fail silently.

---

## Data Handling Rules

These rules apply to every project, regardless of tier or audience. Freedman works with enterprise clients under demanding contractual terms. Data handling errors carry commercial and legal consequences.

## Testing

Use red/green TDD for all new functions and features.

Write the tests first. Confirm they fail before writing the implementation.
Then implement until the tests pass.

- Python: use `pytest` — add to `requirements.txt`, tests in `tests/` directory
- Node.js: use `jest`
- Tests must run with a single command: `pytest` or `npm test`

If a `tests/` directory already exists in the project, run the test suite
before making any changes and confirm it passes. If tests are failing on
arrival, flag it before proceeding.

Do not introduce other test frameworks without approval.


### The Core Rule

**Client data may be accessed and processed within Freedman's ecosystem. Client data must never be sent outside Freedman's ecosystem.**

The risk is directional. The question is not who accesses the data — it is where the data goes.

### Consuming External APIs

Pulling data into a tool from an external API is acceptable without approval. Fetching reference data, public information, or any inbound data feed from an external source does not require sign-off.

### Sending Data to External APIs

Sending Freedman or client data outbound to an external API requires approval before the tool can be used or shared, with one exception:

**Approved for outbound use without additional sign-off:**
- **Claude API (Anthropic)** — pre-approved across all tiers

**All other outbound API use:**
- Requires approval from Richard before use
- Raise the request with Josh, who will pass it to Richard
- Do not proceed until written approval is confirmed
- This applies regardless of how innocuous the data appears

### API Keys

Claude API keys are issued by Josh or Ryan. You cannot obtain one independently on the Freedman Teams plan. Request a key from Josh or Ryan and state which project it is for.

If the user asks you to connect to any external API other than the Claude API and Freedman or client data would be sent outbound, stop and flag this:

```
Data Handling Check
-------------------
This task would send Freedman or client data to an external API: [name the API]
This requires approval before proceeding.
Action: Raise this with Josh, who will escalate to Richard for sign-off.
Do not proceed until approval is confirmed.
```

### Making Tools Public

If a tool handles Freedman or client data and is to be deployed as a publicly accessible web application, this requires tech team sign-off before going live. Flag this during planning if it applies.

---

## GitHub Rules

- All repos in the Freedman International GitHub org — never personal GitHub accounts
- Freedman email accounts only
- Naming: `[department]-[type]-[description]`
  - Departments: `ops`, `finance`, `cat`, `brand`, `tech`, `marketing`
  - Types: `tool-`, `poc-`, `prod-`, `it-`, `int-`
- Every repo needs a README.md: what it does, who uses it, how to run it, required env vars, who owns it
- Repos are tiered: Tier 1 (personal/private), Tier 2 (shared with named colleagues), Tier 3 (org-wide). Contact Josh or Ryan to promote a repo between tiers.

---

## Commit Messages

Start with a verb: Add, Fix, Update, Remove, Refactor. Under 72 characters.

---

## Planning Phase — Required Before Every Coding Task

Produce this plan and wait for APPROVED before writing any code. If asked to skip, offer a shorter plan but do not omit it.

```
Plan
----
Task:      [What the user has asked for, in plain English]
Files:     [Files to be created and files to be modified]
Steps:     [Total number]
  Step 1:  [What will be done]
  Step 2:  [What will be done]
  ...
Risks:     [Concerns, unknowns, or decisions needed]
Questions: [Anything needing clarification before starting]

Type APPROVED to begin, or give feedback to revise.
```

After approval: complete one step at a time, confirm it is working, state the next step, and wait for confirmation before proceeding.

---

## Documentation Phase — Required After Every Coding Task

```
Documentation Complete
----------------------
README.md:          [updated / no changes needed]
PROJECT.md:         [updated / no changes needed]
.env.example:       [updated / no changes needed]
Documentation/:     [files saved — list them, or "none this session"]
Commit:             [suggested commit message]
```

Update README.md for new features or changed setup, PROJECT.md if scope changed, .env.example for any new variables (with comments). Do not end the session without producing this summary.

### Documentation Folder

Every project must have a `Documentation/` folder in the project root. This is a permanent record of everything planned and tested.

- Save the plan produced before each coding task as `Documentation/plan-[YYYY-MM-DD]-[short-description].md`.
- Save all test output (test run results, pytest output, manual test logs) as `Documentation/test-output-[YYYY-MM-DD]-[short-description].md`.
- Both files must be created whether or not the task succeeded. A failed run is as important to record as a successful one.
- Do not delete or overwrite existing files in `Documentation/` — append or create new dated files.
- Add `Documentation/` to the project README under a "Project Records" section so it is discoverable.

### Changes Subfolder

Any deviation from the original plan — scope change, technical decision reversal, architecture change, tool substitution, or schedule change — must be recorded in `Documentation/changes/`.

- The file for each change is `Documentation/changes/change-[YYYY-MM-DD]-[short-description].md`.
- Each file must contain: what the original plan said, what changed, why it changed, and who approved it.
- If no one explicitly approved it (e.g. a pragmatic decision made during a session), record "Decision made during session by [user]" as the approver.
- Flag the change to the user at the end of the session using the format below:

```
Change Recorded
---------------
File:      Documentation/changes/change-[YYYY-MM-DD]-[short-description].md
Original:  [what the plan said]
Changed:   [what actually happened]
Reason:    [why]
Approved:  [who]
```

Do not proceed past a significant deviation without creating this record.

---

## Learning From Mistakes

CLAUDE.md is managed centrally by the IT Team (Josh and Ryan) and rolled out across the company. Individual users should not edit it directly.

If the user corrects you or a session reveals a gap in the standards, apply the correction to the current task immediately, then propose a standards update:

```
CLAUDE.md Change Request
------------------------
Section:  [which section — or "New Section" if one is needed]
Change:   [what to add, remove, or amend]
Reason:   [why this prevents the mistake recurring]
```

Then create a file called `claude-md-change-request-[YYYY-MM-DD]-[short-description].md` in the project root containing the change request above, plus the exact text that would be added or changed.

Tell the user:

```
A CLAUDE.md change request has been saved to:
  [filename]

Next step: Send this file to Josh or Ryan on the IT Team for review.
If accepted, they will update the central CLAUDE.md and roll it out.
```

Do not modify CLAUDE.md directly — only the IT Team can do this.

---

## The Safety Valve

After 3 failed attempts at a bug, stop and produce:

```
Tech Team Summary
-----------------
Error:         [exact message]
Tried:         1. [attempt and outcome]
               2. [attempt and outcome]
               3. [attempt and outcome]
Current state: [what works, what does not]
Next step:     Share this with Richard before trying anything else.
```

---

## Start of Every Session

### Step 0 — Auto-update check (runs before everything else)

Run the following silently before any other session step:

```bash
curl -s https://raw.githubusercontent.com/Freedman-GIT/freedman-claude-standards/main/CLAUDE.md -o /tmp/claude-md-latest.md
```

If the curl fails (no network, timeout, etc.) — skip silently and continue.

If it succeeds:
1. Extract the version line from `/tmp/claude-md-latest.md` (the line starting with `*Freedman International Development Standards`)
2. Compare it to the version line in the currently loaded CLAUDE.md
3. If the versions are the same — continue silently, no message
4. If the repo version is newer — silently update all local copies:
   - If a `CLAUDE.md` exists in the current working directory → overwrite it with `/tmp/claude-md-latest.md`
   - If `~/.claude/CLAUDE.md` exists → overwrite it with `/tmp/claude-md-latest.md`
   - Then tell the user: "CLAUDE.md has been updated to [new version]. This session uses the new standard."
5. Continue the session using the updated standard

Do not ask the user for confirmation. Do not interrupt the session. Update silently and continue.

### Session checklist

1. Check for `PROJECT.md` — if missing, ask the user to create it
2. Confirm framework choice matches the project type
3. Confirm `.env` is in `.gitignore` — add it if not, before anything else
4. Confirm `.env.example` exists — create it if not
5. Confirm database is PostgreSQL — flag if SQLite found
6. Confirm no hardcoded credentials
7. For Render or AWS projects, confirm Sentry is configured
8. Produce a plan and wait for APPROVED before writing any code
9. Complete the task one step at a time, checking in after each step
10. Complete the documentation phase before ending the session

---

## Always Stop and Ask Before

- Adding a new package (Python or Node.js)
- Changing the database schema
- Modifying authentication or access controls
- Connecting to a new external service (Monday.com, WordBee, any API)
- Adding a new paid API integration or changing how an existing one is called
- Sending Freedman or client data to any external API — check Data Handling Rules first
- Changes that touch more than one feature area

---

## Freedman Context

- **Monday.com** — primary operations platform. Handle API keys with care.
- **WordBee** — translation management. Discuss integrations with tech team first.
- **Operations team** — primary users of most internal tools. Keep interfaces simple.
- **Client T&Cs** — demanding. Anything client-facing needs tech team review before deployment.

---

*Freedman International Development Standards v2.1 — April 2026*
*Owned by Richard (Fractional CTO) — questions to Richard*
