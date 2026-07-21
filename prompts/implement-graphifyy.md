# Prompt: Implement Graphifyy Portable Integration

Implement Graphifyy in the target repository using `graphifyy-portable-kit`.

Target repository:

```text
<TARGET_REPOSITORY_PATH>
```

Requirements:

1. Inspect the repository before editing.
2. Detect the build system and CI/CD platform.
3. Preserve existing Sonar, Fluid Attacks, SAST, SCA, secret scanning, and quality gates.
4. Do not alter application logic.
5. Use Docker so developers do not need Python installed locally.
6. Pin Graphifyy and the Python base image.
7. Run the normal Graphifyy service with:
   - repository mounted read-only
   - only `graphify-out/` writable
   - read-only container filesystem
   - `/tmp` as tmpfs
   - all capabilities dropped
   - `no-new-privileges`
   - no published ports
   - no Docker socket mount
   - no network for code-only local analysis when supported
8. Install the official Graphifyy agent skill with a separate explicit setup command.
9. Add `.graphifyignore` and Git ignore rules for Graphifyy artifacts.
   - Adapt broad ignore rules to the target ecosystem.
   - Do not hide first-party source code or security-relevant configuration.
   - Preserve lockfiles or vendored code when the target organization requires them for analysis.
10. Persist reviewed outputs:
    - `graphify-out/graph.json`
    - `graphify-out/GRAPH_REPORT.md`
    - `graphify-out/manifest.json`
11. Do not version:
    - `graphify-out/cost.json`
    - caches
    - logs
    - temp files
    - secrets
    - `.env`
12. Add or update agent instructions.
13. Add documentation and third-party notices.
14. Run available build, tests, Graphifyy generation/query, and security checks.
15. Report what could not be run locally and what must be validated by the corporate pipeline.

Do not commit or push.
