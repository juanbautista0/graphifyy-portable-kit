# Security Policy

Graphifyy Portable Kit is designed to install Graphifyy into existing repositories without weakening local or corporate security controls.

## Supported Version

| Version | Supported |
| --- | --- |
| 0.1.x | Yes |

## Reporting A Vulnerability

Do not publish exploit details in an issue. Report vulnerabilities through the private channel used by your organization or repository maintainers.

Include:

- Affected kit version.
- Target repository type if relevant.
- Files or templates involved.
- Reproduction steps.
- Impact and suggested mitigation if known.

## Security Invariants

The kit must preserve these invariants:

- No secrets, tokens, API keys, or `.env` values are committed.
- Graphifyy runs through Docker; developers do not need local Python.
- Normal Graphifyy analysis mounts the repository read-only.
- Only `graphify-out/` is writable during normal analysis.
- No Docker socket mount is used.
- No privileged containers are used.
- No ports are exposed for Graphifyy.
- No Linux capabilities are retained.
- `no-new-privileges` is enabled.
- External semantic/model analysis is disabled by default.
- Sonar, Fluid Attacks, SAST, SCA, secret scanning, and quality gates are not weakened.

