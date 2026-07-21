# Installer Design

This directory describes the future installer.

The first public version can be agent-driven with templates. A later version should provide a CLI that performs these phases:

1. `detect`
2. `plan`
3. `install`
4. `generate`
5. `verify`
6. `uninstall`

## Phase: detect

Collect target repository facts:

- OS and shell.
- Build system: Gradle, Maven, npm, Python, .NET, Cargo, Go, or mixed.
- Existing Docker and Compose files.
- Existing CI/CD provider.
- Existing Sonar configuration.
- Existing Fluid Attacks configuration.
- Existing agent instruction files.
- Existing ignore rules.
- Whether `make`, `docker compose`, and image scanners exist.

## Phase: plan

Produce a patch plan before editing:

- Files to create.
- Files to modify.
- Commands to run.
- Security assumptions.
- Validation limitations.

## Phase: install

Apply templates idempotently:

- Avoid overwriting existing sections.
- Use marker comments only where appropriate.
- Keep generated Graphifyy files grouped when the target repo allows it.
- Prefer native task systems when present.

## Phase: generate

Build the Docker image and generate the graph using local code-only mode by default.

If the official Graphifyy headless flow fails or hangs on a target repository, the installer may use the local runner template as a fallback. The fallback must still use Graphifyy's installed APIs and must report the limitation.

## Phase: verify

Run:

- Docker build.
- Compose config.
- Graph generation.
- Graph query.
- Project build/tests.
- Available local image and dependency scanners.
- Sonar if locally configured.
- Fluid Attacks if locally configured.

Never hide failures by changing security configuration.

## Phase: uninstall

Remove only files and sections installed by this kit. Never delete user-authored content.

