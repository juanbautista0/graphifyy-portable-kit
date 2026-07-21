# Graphifyy

Graphifyy converts project code and documentation into a local knowledge graph that helps developers and AI agents understand architecture, dependencies, and flows without requiring Python on the host machine.

## Architecture

Graphifyy runs through Docker. The image installs a pinned `graphifyy` package, runs as an unprivileged user, exposes no ports, drops Linux capabilities, enables `no-new-privileges`, uses a read-only container filesystem, and disables networking for normal local code analysis.

Normal operation mounts the repository at `/workspace` as read-only and mounts only `graphify-out/` as writable. A separate setup service may mount the repository writable only to install official project agent skills.

The Compose template can create `graphify-out/` automatically when Docker Compose supports `bind.create_host_path`. Creating the directory explicitly before the first run is also safe.

## Commands

Adapt these commands to the target repository task system:

```bash
docker compose -f compose.graphifyy.yml build graphify
docker compose -f compose.graphifyy.yml run --rm graphify update .
docker compose -f compose.graphifyy.yml run --rm graphify query "how does auth work" --graph graphify-out/graph.json
docker compose -f compose.graphifyy.yml run --rm graphify explain "ComponentName" --graph graphify-out/graph.json
docker compose -f compose.graphifyy.yml run --rm graphify path "ComponentA" "ComponentB" --graph graphify-out/graph.json
docker compose -f compose.graphifyy.yml run --rm graphify-setup install --project --platform agents
```

If the target repository uses Make, Gradle, npm, Taskfile, or another task runner, expose equivalent commands there.

## Privacy

Local code extraction must be the default. External semantic analysis with model providers is disabled by default and requires explicit corporate approval. Do not store model API keys in the repository.

## Security

Do not relax Sonar, Fluid Attacks, SAST, SCA, secret scanning, or CI quality gates for Graphifyy. If a finding appears in Docker, Compose, scripts, dependencies, permissions, or generated files, fix the cause.

## Persistence

Version only reviewed graph artifacts:

- `graphify-out/graph.json`
- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/manifest.json`

Do not version cost files, caches, logs, temporary files, `.env` files, tokens, API keys, or generated artifacts containing sensitive data.

## Safe Updates

1. Validate the target `graphifyy` version exists on PyPI.
2. Update the pinned requirement, Docker label, Compose image tag, and third-party notices.
3. Rebuild the image.
4. Run build, tests, Sonar, Fluid Attacks, SCA, secret scanning, image scanning, graph generation, and graph query.

## Rollback

Remove the files and sections installed for Graphifyy, then run the project build and security controls again.
