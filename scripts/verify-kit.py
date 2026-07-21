#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPECTED_VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
EXPECTED_GRAPHIFYY = "0.9.22"
EXPECTED_BASE = (
    "python:3.12.13-slim-trixie@"
    "sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de"
)


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def assert_file(relative_path: str) -> None:
    if not (ROOT / relative_path).is_file():
        raise AssertionError(f"Missing required file: {relative_path}")


def assert_contains(relative_path: str, pattern: str, message: str) -> None:
    content = read(relative_path)
    if not re.search(pattern, content, flags=re.MULTILINE):
        raise AssertionError(f"{message} ({relative_path})")


def assert_not_contains(relative_path: str, pattern: str, message: str) -> None:
    content = read(relative_path)
    if re.search(pattern, content, flags=re.MULTILINE):
        raise AssertionError(f"{message} ({relative_path})")


def verify_required_files() -> None:
    required_files = [
        "README.md",
        "AGENTS.md",
        "VERSION",
        "requirements.txt",
        "LICENSE",
        "SECURITY.md",
        "CHANGELOG.md",
        "PUBLICATION_CHECKLIST.md",
        "prompts/implement-graphifyy.md",
        "installer/README.md",
        "docs/testing-target-repos.md",
        "scripts/verify-kit.ps1",
        "scripts/verify-kit.py",
        "templates/docker/graphify.Dockerfile",
        "templates/docker/graphify-requirements.txt",
        "templates/compose.graphifyy.yml",
        "templates/.graphifyignore",
        "templates/gitignore.graphifyy.append",
        "templates/dockerignore.graphifyy.append",
        "templates/AGENTS.graphifyy.section.md",
        "templates/docs/graphifyy.md",
        "templates/THIRD_PARTY_NOTICES.graphifyy.md",
        "templates/scripts/graphifyy_local_build.py",
        "templates/graphify-out/.gitkeep",
    ]
    for relative_path in required_files:
        assert_file(relative_path)


def verify_versions_and_templates() -> None:
    assert_contains(
        "README.md",
        rf"Kit version: `{re.escape(EXPECTED_VERSION)}`|0\.1\.0",
        "README should expose the kit version",
    )
    assert_contains(
        "templates/docker/graphify-requirements.txt",
        rf"^graphifyy=={re.escape(EXPECTED_GRAPHIFYY)}\s*$",
        "Graphifyy dependency must be pinned",
    )
    assert_contains(
        "templates/docker/graphify.Dockerfile",
        re.escape(EXPECTED_BASE),
        "Dockerfile must use the pinned base image digest",
    )
    assert_contains(
        "templates/docker/graphify.Dockerfile",
        r"USER 10001:10001",
        "Dockerfile must use an unprivileged user",
    )
    assert_contains(
        "templates/docker/graphify.Dockerfile",
        r'ENTRYPOINT \["graphify"\]',
        "Dockerfile must use graphify entrypoint",
    )
    assert_not_contains(
        "templates/docker/graphify.Dockerfile",
        r":latest",
        "Dockerfile must not use latest tags",
    )
    assert_not_contains(
        "templates/docker/graphify.Dockerfile",
        r"sudo",
        "Dockerfile must not use sudo",
    )


def verify_compose() -> None:
    assert_contains(
        "templates/compose.graphifyy.yml",
        r"read_only: true",
        "Compose must use read-only filesystem for normal service",
    )
    assert_contains(
        "templates/compose.graphifyy.yml",
        r"network_mode: none",
        "Compose must disable network by default",
    )
    assert_contains(
        "templates/compose.graphifyy.yml",
        r"no-new-privileges:true",
        "Compose must enable no-new-privileges",
    )
    assert_contains(
        "templates/compose.graphifyy.yml",
        r"cap_drop:\s*\n\s*- ALL",
        "Compose must drop all capabilities",
    )
    assert_contains(
        "templates/compose.graphifyy.yml",
        r"target: /workspace\s*\n\s*read_only: true",
        "Normal service must mount repository read-only",
    )
    assert_contains(
        "templates/compose.graphifyy.yml",
        r"target: /workspace/graphify-out",
        "Compose must mount graphify-out",
    )
    assert_not_contains(
        "templates/compose.graphifyy.yml",
        r"ports:",
        "Compose must not publish ports",
    )
    assert_not_contains(
        "templates/compose.graphifyy.yml",
        r"docker\.sock",
        "Compose must not mount Docker socket",
    )
    assert_not_contains(
        "templates/compose.graphifyy.yml",
        r"privileged:\s*true",
        "Compose must not use privileged mode",
    )


def verify_ignores_and_docs() -> None:
    assert_contains(
        "templates/.graphifyignore",
        r"graphify-out/",
        ".graphifyignore must exclude graphify-out",
    )
    assert_contains(
        "templates/gitignore.graphifyy.append",
        r"!graphify-out/graph\.json",
        "Git ignore append must allow graph.json",
    )
    assert_contains(
        "templates/gitignore.graphifyy.append",
        r"!graphify-out/GRAPH_REPORT\.md",
        "Git ignore append must allow GRAPH_REPORT.md",
    )
    assert_contains(
        "templates/gitignore.graphifyy.append",
        r"!graphify-out/manifest\.json",
        "Git ignore append must allow manifest.json",
    )
    assert_contains(
        "templates/gitignore.graphifyy.append",
        r"graphify-out/\*\*/cache/",
        "Git ignore append must ignore caches",
    )
    assert_contains(
        "prompts/implement-graphifyy.md",
        r"Do not commit or push",
        "Prompt must prohibit commits and pushes",
    )
    assert_contains(
        "prompts/implement-graphifyy.md",
        r"Preserve existing Sonar, Fluid Attacks",
        "Prompt must preserve security controls",
    )
    assert_contains(
        "templates/docs/graphifyy.md",
        r"External semantic analysis.*disabled by default",
        "Docs must keep external analysis disabled by default",
    )
    assert_contains(
        "SECURITY.md",
        r"No Docker socket mount",
        "Security policy must mention Docker socket invariant",
    )


def verify_no_obvious_secrets() -> None:
    secret_pattern = re.compile(
        r"AKIA[0-9A-Z]{16}|"
        r"BEGIN (RSA|OPENSSH|PRIVATE)|"
        r"api[_-]?key\s*=\s*['\"][^'\"]+|"
        r"token\s*=\s*['\"][^'\"]+",
        flags=re.MULTILINE,
    )
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if secret_pattern.search(content):
            raise AssertionError(f"Potential secret pattern detected: {path.relative_to(ROOT)}")


def main() -> int:
    try:
        verify_required_files()
        verify_versions_and_templates()
        verify_compose()
        verify_ignores_and_docs()
        verify_no_obvious_secrets()
    except AssertionError as exc:
        print(f"Graphifyy Portable Kit verification failed: {exc}", file=sys.stderr)
        return 1

    print("Graphifyy Portable Kit verification passed.")
    print(f"Kit version: {EXPECTED_VERSION}")
    print(f"Graphifyy version: {EXPECTED_GRAPHIFYY}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
