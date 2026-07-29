# Hook: protect-directives (PowerShell companion) - advisory drift check on
#       SKILL.md directive blocks via the .directives.sha sidecar.
#       Runs PostToolUse on Edit|Write. Windows port of protect-directives.sh;
#       same normalization, same sidecar format, same advisory output.
# Skill: /skill-builder
#
# Detects byte-level drift in <!-- origin: user | immutable: true --> blocks.
#
# Reports FIVE classes, none of which is ever a silent skip:
#   DRIFT              row parses, hash differs from the recomputed block
#   MISSING BLOCK      sidecar names a directive:N the file no longer has
#   MALFORMED ROW      a data line the canonical row regex cannot parse
#   UNPROTECTED BLOCK  a block in the file with no sidecar row (coverage gap)
#   SIDECAR UNREADABLE the sidecar has data lines but zero of them parse
#
# Fail-open but never fail-silent: any internal error exits 0 so a hook bug can
# never block the user's work, but an empty parse result must NEVER produce an
# empty report. That combination is what let a sidecar this reader could not
# read present as clean.
#
# Regenerate the sidecar after intentional directive changes:
#   /skill-builder checksums [skill] --execute

$script:tail = "`nSacred-block content is verified against its .directives.sha sidecar. " +
               "If a change was intentional, regenerate via /skill-builder checksums --execute. " +
               "If not, revert the change."

function Write-Advisory([string]$message) {
    @{ additionalContext = $message } | ConvertTo-Json -Compress
}

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

    try {
        $content = Get-Content $filePath -Raw
    } catch {
        Write-Advisory ("DIRECTIVE CHECK COULD NOT RUN for $filePath : the file could not be read. " +
                        "Directive protection was NOT verified for this edit.")
        exit 0
    }

    # Strip YAML frontmatter (first --- ... --- block only)
    $stripped = [regex]::new('^---\n.*?\n---\n', 'Singleline').Replace(($content -replace "`r`n", "`n"), '', 1)

    # Extract sacred blocks in order
    $blockMatches = [regex]::Matches($stripped,
        '<!-- origin: user[^>]*immutable: true[^>]*-->\n(.*?)\n<!-- /origin -->',
        'Singleline')
    $blockCount = $blockMatches.Count

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

    # Canonical sidecar row regex (checksums.md § Canonical Sidecar Parse Regex).
    # The preview group is greedy to the final quote and does NOT require the
    # trailing "..." - legacy rows written before that suffix became mandatory
    # must still verify their hashes rather than being skipped.
    $rowRe = [regex]'^sha256:([0-9a-f]{64})\s+directive:(\d+)\s+"(.*)"\s*$'

    $expected = @{}
    $previews = @{}
    $malformed = New-Object System.Collections.Generic.List[string]
    $dataLines = 0
    $lineNo = 0

    try {
        $sidecarLines = Get-Content $sidecar
    } catch {
        Write-Advisory ("DIRECTIVE CHECK COULD NOT RUN for $filePath : the sidecar $sidecar could not " +
                        "be read. Directive protection was NOT verified for this edit.")
        exit 0
    }

    foreach ($rawLine in $sidecarLines) {
        $lineNo++
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }
        $dataLines++
        $m = $rowRe.Match($line)
        if (-not $m.Success) {
            $snippet = if ($line.Length -gt 70) { $line.Substring(0, 70) } else { $line }
            $malformed.Add("line ${lineNo}: $snippet")
            continue
        }
        $n = [int]$m.Groups[2].Value
        $preview = $m.Groups[3].Value
        if ($preview.EndsWith('...')) { $preview = $preview.Substring(0, $preview.Length - 3) }
        $expected[$n] = $m.Groups[1].Value
        $previews[$n] = $preview
    }

    # A sidecar with data lines but nothing parseable is a protection outage,
    # not a clean run. Report it as one finding instead of a per-row list.
    if ($dataLines -gt 0 -and $expected.Count -eq 0) {
        Write-Advisory ("SIDECAR UNREADABLE: $sidecar`n  - $dataLines data line(s) present, 0 parsed by " +
                        "the canonical row regex.`n  - NONE of the $blockCount immutable block(s) in " +
                        "$filePath were verified. This is an UNPROTECTED state, not a pass.`n  - " +
                        "Regenerate the sidecar: /skill-builder checksums --execute" + $script:tail)
        exit 0
    }

    $drift = New-Object System.Collections.Generic.List[string]
    foreach ($n in ($expected.Keys | Sort-Object)) {
        $expectedSha = $expected[$n]
        $preview = $previews[$n]
        if ($n -gt $blockCount) {
            $drift.Add("directive:$n (preview: `"$preview...`") - block no longer present in file")
            continue
        }
        $actualSha = Get-NormalizedHash $blockMatches[$n - 1].Groups[1].Value
        if ($actualSha -ne $expectedSha) {
            $drift.Add("directive:$n (preview: `"$preview...`") - sidecar expected sha256:$($expectedSha.Substring(0,12))..., current sha256:$($actualSha.Substring(0,12))...")
        }
    }

    # Coverage: blocks present in the file that no sidecar row covers are never
    # examined by the loop above. Without this check the hook prints nothing
    # about them and reads as clean.
    $unprotected = New-Object System.Collections.Generic.List[int]
    for ($i = 1; $i -le $blockCount; $i++) {
        if (-not $expected.ContainsKey($i)) { $unprotected.Add($i) }
    }

    $sections = New-Object System.Collections.Generic.List[string]
    if ($drift.Count -gt 0) {
        $sections.Add("DIRECTIVE DRIFT DETECTED in ${filePath}:`n  - " + ($drift -join "`n  - "))
    }
    if ($malformed.Count -gt 0) {
        $sections.Add("MALFORMED SIDECAR ROW(S) in $sidecar - these directives were NOT verified:`n  - " +
                      ($malformed -join "`n  - "))
    }
    if ($unprotected.Count -gt 0) {
        $sections.Add("UNPROTECTED DIRECTIVE BLOCK(S) in $filePath - present in the file, absent from " +
                      "$sidecar, therefore never checked: directive:" +
                      ($unprotected -join ", directive:") +
                      "`n  - Regenerate the sidecar to bring them under protection: " +
                      "/skill-builder checksums --execute")
    }

    if ($sections.Count -gt 0) {
        Write-Advisory (($sections -join "`n`n") + $script:tail)
    }

    exit 0
} catch {
    # Fail-open, but say so: an unreported failure is indistinguishable from a
    # clean pass, which is the bug class this hook was hardened against.
    try {
        Write-Output '{"systemMessage":"protect-directives.ps1 crashed (non-fatal) - directive protection was NOT verified for this edit"}'
    } catch {}
    exit 0
}
