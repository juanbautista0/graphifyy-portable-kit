# Agent Instructions For Graphifyy Portable Kit

You are helping install Graphifyy into an existing repository.

Before changing the target repository:

1. Inspect the target architecture.
2. Identify the build system.
3. Inspect Dockerfiles, Compose files, CI/CD, `.gitignore`, `.dockerignore`, and agent instructions.
4. Identify Sonar and Fluid Attacks configuration.
5. Identify existing security policies.
6. List the files you intend to create or modify.
7. Preserve all existing user changes.

Do not:

- Modify application logic.
- Disable quality gates, SAST, SCA, secret scanning, Sonar, or Fluid Attacks controls.
- Add broad security exclusions, suppressions, or `NOSONAR`.
- Add credentials, tokens, API keys, or `.env` content.
- Mount `/var/run/docker.sock`.
- Run privileged containers.
- Expose ports for Graphifyy.
- Use `latest` image tags.
- Install `graphifyy[all]`.
- Commit or push.

Default integration requirements:

- Docker-based Graphifyy execution.
- Pinned `graphifyy` version.
- Unprivileged container user.
- Read-only repository mount for normal analysis.
- Only `graphify-out/` writable during normal analysis.
- No network for code-only local analysis when Docker supports it.
- Separate setup service for installing official agent skills.
- External LLM/semantic analysis disabled by default.
- Clear documentation and rollback instructions.

Use the templates in this kit as starting points, but adapt paths and command surfaces to the target repository.

The ignore templates cover many ecosystems. Review them against the target repository before applying. Do not exclude first-party source code, security-relevant configuration, or files required by the organization's analysis tools. If a broad rule would hide important project-owned content, narrow it and explain the exception.
