# Publication Checklist

Use this before publishing a release.

## Repository

- [ ] Move `graphifyy-portable-kit/` to its own repository.
- [ ] Keep repository name aligned with package intent, for example `graphifyy-portable-kit`.
- [ ] Add remote origin.
- [ ] Review all files for organization-specific paths or secrets.
- [ ] Run `python scripts/verify-kit.py`.
- [ ] On Windows, optionally also run `scripts/verify-kit.ps1`.
- [ ] On Linux/macOS, optionally also run `sh scripts/verify-kit.sh`.
- [ ] Tag the release as `v0.1.0`.

## README

- [ ] Confirm the status reflects the release maturity.
- [ ] Confirm quick-use instructions are accurate.
- [ ] Confirm Graphifyy version is current and pinned.
- [ ] Confirm Python base image digest is current and validated.

## Security

- [ ] Confirm Dockerfile does not use `latest`.
- [ ] Confirm Compose does not publish ports.
- [ ] Confirm Compose does not mount Docker socket.
- [ ] Confirm Compose drops all capabilities.
- [ ] Confirm Compose enables `no-new-privileges`.
- [ ] Confirm normal Graphifyy service uses `network_mode: none`.
- [ ] Confirm normal Graphifyy service mounts the repo read-only.
- [ ] Confirm only `graphify-out/` is writable.
- [ ] Confirm external model analysis is documented as disabled by default.

## Test In Target Repositories

- [ ] Test against a Gradle Java repo.
- [ ] Test against a Maven Java repo.
- [ ] Test against an npm/TypeScript repo.
- [ ] Test against a Python repo.
- [ ] Test against a repo with existing Compose files.
- [ ] Test against a repo with existing `AGENTS.md`.
- [ ] Test against a repo with Sonar configured.
- [ ] Test against a repo with Fluid Attacks configured.
