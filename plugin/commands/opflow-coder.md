---
description: Re-orient inside the opflow workflow. Loads handover, active plan, project metadata, and bootstrap doc; then routes the rest of the session to the right spoke skill (handover/plan/issue/docs/bootstrap/op-indexer).
---

Use the `opflow-coder` skill: run the session-start ritual (`handover-latest`, `plan-active`, `project-get`, `docs-get('bootstrap.md')` in parallel), then follow the intent→skill routing table for whatever the user asks next.
