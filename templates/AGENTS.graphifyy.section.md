## Graphifyy

Use Graphifyy before broad repository exploration when `graphify-out/graph.json` exists. Request only the subgraph needed for the task, then verify inferred relationships directly in source files before changing code.

Treat graph relationships by provenance:

- `EXTRACTED`: derived from code or documentation and still requires source verification for risky changes.
- `INFERRED`: useful as a navigation hint, not as proof.
- `AMBIGUOUS`: inspect the code path manually before relying on it.

Do not use the graph as the only source of truth. Update it after structural changes such as new modules, renamed packages, dependency changes, architecture documentation updates, or new entry points.

Run the real project build, tests, Sonar, and security controls required for the change. Do not modify security configuration, exclusions, quality gates, SAST, SCA, secret scanning, or pipeline controls to make an implementation pass.

The default Graphifyy workflow is local-only. Do not send source code, documentation, generated graph data, secrets, or repository metadata to external model providers without explicit corporate authorization.

