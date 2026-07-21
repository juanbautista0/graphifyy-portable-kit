#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
EXPECTED_VERSION="$(cat "$ROOT/VERSION" | tr -d '\r\n')"
EXPECTED_GRAPHIFYY="0.9.22"
EXPECTED_BASE="python:3.12.13-slim-trixie@sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de"

fail() {
  printf '%s\n' "Graphifyy Portable Kit verification failed: $*" >&2
  exit 1
}

assert_file() {
  [ -f "$ROOT/$1" ] || fail "Missing required file: $1"
}

assert_contains() {
  file="$1"
  pattern="$2"
  message="$3"
  grep -Eq "$pattern" "$ROOT/$file" || fail "$message ($file)"
}

assert_not_contains() {
  file="$1"
  pattern="$2"
  message="$3"
  if grep -Eq "$pattern" "$ROOT/$file"; then
    fail "$message ($file)"
  fi
}

for file in \
  README.md \
  AGENTS.md \
  VERSION \
  requirements.txt \
  LICENSE \
  SECURITY.md \
  CHANGELOG.md \
  PUBLICATION_CHECKLIST.md \
  prompts/implement-graphifyy.md \
  installer/README.md \
  docs/testing-target-repos.md \
  scripts/verify-kit.ps1 \
  scripts/verify-kit.py \
  scripts/verify-kit.sh \
  templates/docker/graphify.Dockerfile \
  templates/docker/graphify-requirements.txt \
  templates/compose.graphifyy.yml \
  templates/.graphifyignore \
  templates/gitignore.graphifyy.append \
  templates/dockerignore.graphifyy.append \
  templates/AGENTS.graphifyy.section.md \
  templates/docs/graphifyy.md \
  templates/THIRD_PARTY_NOTICES.graphifyy.md \
  templates/scripts/graphifyy_local_build.py \
  templates/graphify-out/.gitkeep
do
  assert_file "$file"
done

assert_contains "README.md" "Kit version: \`$EXPECTED_VERSION\`|0\\.1\\.0" "README should expose the kit version"
assert_contains "templates/docker/graphify-requirements.txt" "^graphifyy==$EXPECTED_GRAPHIFYY[[:space:]]*$" "Graphifyy dependency must be pinned"
grep -Fq "$EXPECTED_BASE" "$ROOT/templates/docker/graphify.Dockerfile" || fail "Dockerfile must use the pinned base image digest"
assert_contains "templates/docker/graphify.Dockerfile" "USER 10001:10001" "Dockerfile must use an unprivileged user"
assert_contains "templates/docker/graphify.Dockerfile" 'ENTRYPOINT \["graphify"\]' "Dockerfile must use graphify entrypoint"
assert_not_contains "templates/docker/graphify.Dockerfile" ":latest" "Dockerfile must not use latest tags"
assert_not_contains "templates/docker/graphify.Dockerfile" "sudo" "Dockerfile must not use sudo"

assert_contains "templates/compose.graphifyy.yml" "read_only: true" "Compose must use read-only filesystem for normal service"
assert_contains "templates/compose.graphifyy.yml" "network_mode: none" "Compose must disable network by default"
assert_contains "templates/compose.graphifyy.yml" "no-new-privileges:true" "Compose must enable no-new-privileges"
assert_contains "templates/compose.graphifyy.yml" "cap_drop:" "Compose must declare cap_drop"
assert_contains "templates/compose.graphifyy.yml" "- ALL" "Compose must drop all capabilities"
assert_contains "templates/compose.graphifyy.yml" "target: /workspace" "Compose must mount repository"
assert_contains "templates/compose.graphifyy.yml" "target: /workspace/graphify-out" "Compose must mount graphify-out"
assert_not_contains "templates/compose.graphifyy.yml" "ports:" "Compose must not publish ports"
assert_not_contains "templates/compose.graphifyy.yml" "docker\\.sock" "Compose must not mount Docker socket"
assert_not_contains "templates/compose.graphifyy.yml" "privileged:[[:space:]]*true" "Compose must not use privileged mode"

assert_contains "templates/.graphifyignore" "graphify-out/" ".graphifyignore must exclude graphify-out"
assert_contains "templates/gitignore.graphifyy.append" "!graphify-out/graph\\.json" "Git ignore append must allow graph.json"
assert_contains "templates/gitignore.graphifyy.append" "!graphify-out/GRAPH_REPORT\\.md" "Git ignore append must allow GRAPH_REPORT.md"
assert_contains "templates/gitignore.graphifyy.append" "!graphify-out/manifest\\.json" "Git ignore append must allow manifest.json"
assert_contains "templates/gitignore.graphifyy.append" "graphify-out/\\*\\*/cache/" "Git ignore append must ignore caches"

assert_contains "prompts/implement-graphifyy.md" "Do not commit or push" "Prompt must prohibit commits and pushes"
assert_contains "prompts/implement-graphifyy.md" "Preserve existing Sonar, Fluid Attacks" "Prompt must preserve security controls"
assert_contains "templates/docs/graphifyy.md" "External semantic analysis.*disabled by default" "Docs must keep external analysis disabled by default"
assert_contains "SECURITY.md" "No Docker socket mount" "Security policy must mention Docker socket invariant"

if grep -REn "AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|PRIVATE)|api[_-]?key[[:space:]]*=[[:space:]]*['\"][^'\"]+|token[[:space:]]*=[[:space:]]*['\"][^'\"]+" "$ROOT" >/dev/null 2>&1; then
  fail "Potential secret pattern detected in kit files."
fi

printf '%s\n' "Graphifyy Portable Kit verification passed."
printf '%s\n' "Kit version: $EXPECTED_VERSION"
printf '%s\n' "Graphifyy version: $EXPECTED_GRAPHIFYY"
