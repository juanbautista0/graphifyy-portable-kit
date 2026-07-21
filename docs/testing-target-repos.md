# Testing In Target Repositories

Use this guide after publishing or moving the kit.

## Agent-Driven Smoke Test

Before testing against target repositories, verify the kit itself:

```bash
python scripts/verify-kit.py
```

The verifier uses only Python's standard library. On Windows, `scripts/verify-kit.ps1` is also available. On Linux/macOS, `sh scripts/verify-kit.sh` is also available.

In a target repository, ask the agent:

```text
Use graphifyy-portable-kit to implement Graphifyy in this repository.
Do not commit or push.
Inspect first, show files to create or modify, preserve security controls, and run available validations.
```

Expected result:

- Docker image builds.
- Compose config is valid.
- Normal Graphifyy service uses read-only repository mount and writable `graphify-out/` only.
- Official Graphifyy skill is installed when supported.
- `graphify-out/graph.json`, `graphify-out/GRAPH_REPORT.md`, and `graphify-out/manifest.json` are generated.
- A basic graph query succeeds.
- Project build/tests still pass.
- Sonar and Fluid Attacks are run when locally available, otherwise listed as pipeline validations.

## Manual Template Smoke Test

For a manual test, copy these templates into a disposable repository:

- `templates/docker/graphify.Dockerfile` -> `docker/graphify.Dockerfile`
- `templates/docker/graphify-requirements.txt` -> `docker/graphify-requirements.txt`
- `templates/compose.graphifyy.yml` -> `compose.graphifyy.yml`
- `templates/.graphifyignore` -> `.graphifyignore`
- `templates/scripts/graphifyy_local_build.py` -> `scripts/graphifyy_local_build.py`

Then run:

```bash
docker compose -f compose.graphifyy.yml config
docker compose -f compose.graphifyy.yml build graphify
docker compose -f compose.graphifyy.yml run --rm graphify --help
```

If the target repo has code files:

```bash
docker compose -f compose.graphifyy.yml run --rm --entrypoint python graphify scripts/graphifyy_local_build.py .
docker compose -f compose.graphifyy.yml run --rm graphify query "main flow" --graph graphify-out/graph.json
```
