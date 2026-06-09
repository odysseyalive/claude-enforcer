# Hook: protect-directives (PowerShell companion) - advisory drift check on
#       SKILL.md directive blocks via the .directives.sha sidecar.
#       Runs PostToolUse on Edit|Write. Windows port of protect-directives.sh;
#       same normalization, same sidecar format, same advisory output.
# Skill: /skill-builder
#
# Detects byte-level drift in <!-- origin: user | immutable: true --> blocks.
# Fail-open by design: any internal error exits 0 so a hook bug can never
# block the user's work.
#
# Regenerate the sidecar after intentional directive changes:
#   /skill-builder checksums [skill] --execute

try {
    $ErrorActionPreference = 'Stop'

    $inputJson = [Console]::In.ReadToEnd()
    if (-not $inputJson) { exit 0 }

    try { $payload = $inputJson | ConvertFrom-Json } catch { exit 0 }

    $filePath = ''
    if ($payload.tool_input -and $payload.tool_input.file_path) {
        $filePath = [string]$payload.tool_input.file_path
    }
    if (-not $filePath) { exit 0 }

    # Only inspect SKILL.md files (normalize separators before matching)
    $normPath = $filePath -replace '\\', '/'
    if ($normPath -notmatch '/SKILL\.md$') { exit 0 }

    # Sidecar sits next to the SKILL.md
    $skillDir = Split-Path $filePath -Parent
    $sidecar = Join-Path $skillDir '.directives.sha'

    if (-not (Test-Path $sidecar -PathType Leaf)) { exit 0 }   # no protection configured
    if (-not (Test-Path $filePath -PathType Leaf)) { exit 0 }  # file missing post-tool-use

    $content = Get-Content $filePath -Raw

    # Strip YAML frontmatter (first --- ... --- block only)
    $stripped = [regex]::new('^---\n.*?\n---\n', 'Singleline').Replace(($content -replace "`r`n", "`n"), '', 1)

    # Extract sacred blocks in order
    $blockMatches = [regex]::Matches($stripped,
        '<!-- origin: user[^>]*immutable: true[^>]*-->\n(.*?)\n<!-- /origin -->',
        'Singleline')

    function Get-NormalizedHash([string]$text) {
        # Same normalization as the bash/python original: rstrip each line,
        # collapse runs of blank lines to at most 2
        $lines = $text -split "`n" | ForEach-Object { $_.TrimEnd() }
        $out = New-Object System.Collections.Generic.List[string]
        $blanks = 0
        foreach ($ln in $lines) {
            if ($ln -eq '') {
                $blanks++
                if ($blanks -le 2) { $out.Add($ln) }
            } else {
                $blanks = 0
                $out.Add($ln)
            }
        }
        $normalized = $out -join "`n"
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
            return ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLower()
        } finally {
            $sha.Dispose()
        }
    }

    # Parse sidecar entries: sha256:<hash>  directive:<N>  "<preview>..."
    $violations = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Get-Content $sidecar)) {
        $m = [regex]::Match($line, 'sha256:([0-9a-f]{64})\s+directive:(\d+)\s+"(.*?)\.\.\."')
        if (-not $m.Success) { continue }
        $expectedSha = $m.Groups[1].Value
        $n = [int]$m.Groups[2].Value
        $preview = $m.Groups[3].Value

        if ($n -gt $blockMatches.Count) {
            $violations.Add("directive:$n (preview: `"$preview...`") - block no longer present in file")
            continue
        }
        $actualSha = Get-NormalizedHash $blockMatches[$n - 1].Groups[1].Value
        if ($actualSha -ne $expectedSha) {
            $violations.Add("directive:$n (preview: `"$preview...`") - sidecar expected sha256:$($expectedSha.Substring(0,12))..., current sha256:$($actualSha.Substring(0,12))...")
        }
    }

    if ($violations.Count -gt 0) {
        $msg = "DIRECTIVE DRIFT DETECTED in " + $filePath + ":`n  - " + ($violations -join "`n  - ") +
               "`nSacred-block content has changed against its .directives.sha sidecar. If this was intentional, regenerate the sidecar via /skill-builder checksums --execute. If not, revert the change."
        # Surface advisory via additionalContext so Claude sees the drift notice
        @{ additionalContext = $msg } | ConvertTo-Json -Compress
    }

    exit 0
} catch {
    # Fail-open: never block on an internal hook error
    try { Write-Output '{"systemMessage":"protect-directives.ps1 crashed (non-fatal)"}' } catch {}
    exit 0
}
