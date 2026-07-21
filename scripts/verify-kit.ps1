$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$expectedVersion = (Get-Content -LiteralPath (Join-Path $root "VERSION") -Raw).Trim()
$expectedGraphify = "0.9.22"
$expectedBase = "python:3.12.13-slim-trixie@sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de"

function Assert-File {
    param([string] $RelativePath)
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required file: $RelativePath"
    }
}

function Assert-Contains {
    param(
        [string] $RelativePath,
        [string] $Pattern,
        [string] $Message
    )
    $path = Join-Path $root $RelativePath
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -notmatch $Pattern) {
        throw "$Message ($RelativePath)"
    }
}

function Assert-NotContains {
    param(
        [string] $RelativePath,
        [string] $Pattern,
        [string] $Message
    )
    $path = Join-Path $root $RelativePath
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -match $Pattern) {
        throw "$Message ($RelativePath)"
    }
}

$requiredFiles = @(
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
    "scripts/verify-kit.sh",
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
    "templates/graphify-out/.gitkeep"
)

foreach ($file in $requiredFiles) {
    Assert-File $file
}

Assert-Contains -RelativePath "README.md" -Pattern "Kit version: ``$expectedVersion``|0\.1\.0" -Message "README should expose the kit version"
Assert-Contains -RelativePath "templates/docker/graphify-requirements.txt" -Pattern "^graphifyy==$expectedGraphify\s*$" -Message "Graphifyy dependency must be pinned"
Assert-Contains -RelativePath "templates/docker/graphify.Dockerfile" -Pattern ([regex]::Escape($expectedBase)) -Message "Dockerfile must use the pinned base image digest"
Assert-Contains "templates/docker/graphify.Dockerfile" "USER 10001:10001" "Dockerfile must use an unprivileged user"
Assert-Contains "templates/docker/graphify.Dockerfile" 'ENTRYPOINT \["graphify"\]' "Dockerfile must use graphify entrypoint"
Assert-NotContains "templates/docker/graphify.Dockerfile" ":latest" "Dockerfile must not use latest tags"
Assert-NotContains "templates/docker/graphify.Dockerfile" "sudo" "Dockerfile must not use sudo"

Assert-Contains "templates/compose.graphifyy.yml" "read_only: true" "Compose must use read-only filesystem for normal service"
Assert-Contains "templates/compose.graphifyy.yml" "network_mode: none" "Compose must disable network by default"
Assert-Contains "templates/compose.graphifyy.yml" "no-new-privileges:true" "Compose must enable no-new-privileges"
Assert-Contains "templates/compose.graphifyy.yml" "cap_drop:\s*\r?\n\s*- ALL" "Compose must drop all capabilities"
Assert-Contains "templates/compose.graphifyy.yml" "target: /workspace\r?\n\s*read_only: true" "Normal service must mount repository read-only"
Assert-Contains "templates/compose.graphifyy.yml" "target: /workspace/graphify-out" "Compose must mount graphify-out"
Assert-NotContains "templates/compose.graphifyy.yml" "ports:" "Compose must not publish ports"
Assert-NotContains "templates/compose.graphifyy.yml" "docker\.sock" "Compose must not mount Docker socket"
Assert-NotContains "templates/compose.graphifyy.yml" "privileged:\s*true" "Compose must not use privileged mode"

Assert-Contains "templates/.graphifyignore" "graphify-out/" ".graphifyignore must exclude graphify-out"
Assert-Contains "templates/gitignore.graphifyy.append" "!graphify-out/graph\.json" "Git ignore append must allow graph.json"
Assert-Contains "templates/gitignore.graphifyy.append" "!graphify-out/GRAPH_REPORT\.md" "Git ignore append must allow GRAPH_REPORT.md"
Assert-Contains "templates/gitignore.graphifyy.append" "!graphify-out/manifest\.json" "Git ignore append must allow manifest.json"
Assert-Contains "templates/gitignore.graphifyy.append" "graphify-out/\*\*/cache/" "Git ignore append must ignore caches"

Assert-Contains "prompts/implement-graphifyy.md" "Do not commit or push" "Prompt must prohibit commits and pushes"
Assert-Contains "prompts/implement-graphifyy.md" "Preserve existing Sonar, Fluid Attacks" "Prompt must preserve security controls"
Assert-Contains "templates/docs/graphifyy.md" "External semantic analysis.*disabled by default" "Docs must keep external analysis disabled by default"
Assert-Contains "SECURITY.md" "No Docker socket mount" "Security policy must mention Docker socket invariant"

$kitFiles = Get-ChildItem -LiteralPath $root -Recurse -File
$badSecretMatches = $kitFiles | Select-String -Pattern "AKIA[0-9A-Z]{16}|BEGIN (RSA|OPENSSH|PRIVATE)|api[_-]?key\s*=\s*['""][^'""]+|token\s*=\s*['""][^'""]+" -CaseSensitive -ErrorAction SilentlyContinue
if ($badSecretMatches) {
    throw "Potential secret pattern detected in kit files."
}

Write-Host "Graphifyy Portable Kit verification passed."
Write-Host "Kit version: $expectedVersion"
Write-Host "Graphifyy version: $expectedGraphify"
