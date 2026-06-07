# Hook: unique-persona (PowerShell companion) - block persona duplication
#       across agent files. Covers flat-file agents (agents/<name>.md) and
#       subdir-form agents (agents/<name>/AGENT.md). Exact-match fast path.
#       Runs PreToolUse on Edit|Write. Windows port of unique-persona.sh;
#       same normalization, same exit semantics (exit 2 blocks).
# Skill: /skill-builder
#
# Paraphrase / near-duplicate detection lives in
#   /skill-builder agents --deliberate
# rather than firing on every edit. This hook is the deterministic backstop
# for the user directive: "Each agent being created by this system always has
# to have an appropriate persona that is not being used anywhere else."
#
# Fail-open by design: any internal error exits 0. The ONLY blocking path is
# a confirmed exact normalized persona match.

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

    # Only inspect agent files (both forms live under an agents/ directory)
    $normPath = $filePath -replace '\\', '/'
    if ($normPath -notmatch '/agents/.*\.md$') { exit 0 }

    # Extract proposed persona from the tool input. For Write, look in content.
    # For Edit, look in new_string. If the change doesn't touch the persona
    # line, the existing on-disk value is unchanged and no check is needed.
    $changeText = ''
    if ($payload.tool_input.content) { $changeText = [string]$payload.tool_input.content }
    elseif ($payload.tool_input.new_string) { $changeText = [string]$payload.tool_input.new_string }
    if (-not $changeText) { exit 0 }

    $m = [regex]::Match($changeText, '(?m)^persona:\s*(.+?)\s*$')
    if (-not $m.Success) { exit 0 }
    $proposed = $m.Groups[1].Value.Trim()
    if ($proposed.Length -ge 2 -and $proposed[0] -eq $proposed[-1] -and ($proposed[0] -eq '"' -or $proposed[0] -eq "'")) {
        $proposed = $proposed.Substring(1, $proposed.Length - 2)
    }
    if (-not $proposed) { exit 0 }

    # Normalize for comparison: lowercase, collapse whitespace, strip ASCII
    # punctuation, trim (mirrors the bash original's tr/sed pipeline)
    function Get-NormalizedPersona([string]$text) {
        $t = $text.ToLowerInvariant()
        $t = [regex]::Replace($t, '\s+', ' ')
        $t = [regex]::Replace($t, '[!-/:-@\[-`{-~]', '')
        return $t.Trim()
    }

    $normProposed = Get-NormalizedPersona $proposed

    # Locate the project root (prefer CLAUDE_PROJECT_DIR, fall back to cwd)
    $root = $env:CLAUDE_PROJECT_DIR
    if (-not $root) { $root = (Get-Location).Path }

    function Resolve-RealPath([string]$p) {
        # Dereference symlinks where possible; fall back to the full path
        try {
            $item = Get-Item -LiteralPath $p -ErrorAction Stop
            if ($item.LinkType -and $item.Target) {
                $target = @($item.Target)[0]
                if (-not [System.IO.Path]::IsPathRooted($target)) {
                    $target = Join-Path (Split-Path $p -Parent) $target
                }
                return [System.IO.Path]::GetFullPath($target)
            }
            return $item.FullName
        } catch {
            return [System.IO.Path]::GetFullPath($p)
        }
    }

    $editReal = Resolve-RealPath $filePath

    # Collect candidate agent files in all three forms:
    #   - flat-file:   .claude/skills/<skill>/agents/<name>.md
    #   - subdir form: .claude/skills/<skill>/agents/<name>/AGENT.md
    #   - registered:  .claude/agents/<name>.md (often a symlink into a skill form)
    $candidates = @()
    $skillsDir = Join-Path $root '.claude/skills'
    if (Test-Path $skillsDir -PathType Container) {
        $candidates += Get-ChildItem -Path $skillsDir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
            Where-Object { ($_.FullName -replace '\\', '/') -match '/agents/' }
    }
    $registeredDir = Join-Path $root '.claude/agents'
    if (Test-Path $registeredDir -PathType Container) {
        $candidates += Get-ChildItem -Path $registeredDir -File -Filter '*.md' -ErrorAction SilentlyContinue
    }

    # Symlinks are dereferenced and deduped by resolved path so a registration
    # symlink never double-counts (or false-conflicts with) its own target.
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($f in $candidates) {
        $real = Resolve-RealPath $f.FullName
        if ($real -ieq $editReal) { continue }     # skip the file being edited
        if (-not $seen.Add($real)) { continue }    # dedupe resolved targets

        $existing = ''
        foreach ($line in (Get-Content -LiteralPath $real -ErrorAction SilentlyContinue)) {
            $pm = [regex]::Match($line, '^persona:\s*(.*)$')
            if ($pm.Success) {
                $existing = $pm.Groups[1].Value.Trim()
                if ($existing.Length -ge 2 -and $existing[0] -eq $existing[-1] -and ($existing[0] -eq '"' -or $existing[0] -eq "'")) {
                    $existing = $existing.Substring(1, $existing.Length - 2)
                }
                break
            }
        }
        if (-not $existing) { continue }

        if ($normProposed -eq (Get-NormalizedPersona $existing)) {
            [Console]::Error.WriteLine("BLOCKED: persona '$proposed' conflicts with $($f.FullName): '$existing'. Choose a different persona.")
            exit 2
        }
    }

    exit 0
} catch {
    # Fail-open: never block on an internal hook error
    try { Write-Output '{"systemMessage":"unique-persona.ps1 crashed (non-fatal)"}' } catch {}
    exit 0
}
