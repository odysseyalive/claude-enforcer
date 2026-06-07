# Claude Enforcer Installer (Windows PowerShell)
# Installs the skill-builder skill to your Claude Code project
#
# Usage (PowerShell 5.1+):
#   irm https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install.ps1 | iex
#
# Linux / macOS users: use the bash installer instead:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
#
# The list of shipped files lives in manifest.txt (shared with the bash installer).

function Install-ClaudeEnforcer {
    $ErrorActionPreference = 'Stop'

    $RepoUrl = 'https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main'
    $SkillDir = '.claude/skills/skill-builder'

    Write-Host 'Claude Enforcer Installer'
    Write-Host '========================='
    Write-Host ''

    # Check for CLAUDE.md in current directory
    if (-not (Test-Path 'CLAUDE.md' -PathType Leaf)) {
        Write-Host 'Error: CLAUDE.md not found in current directory.'
        Write-Host ''
        Write-Host 'This installer must be run from a Claude Code project root.'
        Write-Host "If you haven't initialized Claude Code yet, run:"
        Write-Host ''
        Write-Host '    claude /init'
        Write-Host ''
        Write-Host 'Then run this installer again.'
        return
    }

    Write-Host "Found CLAUDE.md in $(Get-Location)"

    # Remove legacy files from prior installer versions
    # (older installs shipped these; they've since been removed from the skill)
    $legacyFiles = @(
        "$SkillDir/reference.md",
        "$SkillDir/references/procedures.md",
        "$SkillDir/references/self-heal-templates.md",
        "$SkillDir/references/procedures/self-heal.md",
        # Legacy older-named hook scripts from prior installs
        "$SkillDir/hooks/verify-directive-integrity.sh",
        "$SkillDir/hooks/check-persona-uniqueness.sh"
    )
    foreach ($legacy in $legacyFiles) {
        if (Test-Path $legacy -PathType Leaf) {
            Write-Host "Removing legacy $(Split-Path $legacy -Leaf)..."
            Remove-Item $legacy -Force
        }
    }

    # Remove legacy standalone shell-safety skill (now absorbed into skill-builder)
    if (Test-Path '.claude/skills/shell-safety' -PathType Container) {
        Write-Host 'Removing legacy shell-safety skill (now a skill-builder subcommand)...'
        Remove-Item '.claude/skills/shell-safety' -Recurse -Force
    }

    # Download the shared manifest, then every file it lists.
    # Manifest format: optional flag ("keep" = fetch only if absent,
    # "hook" = executable bit on unix; no-op on Windows) followed by the
    # repo-relative path.
    Write-Host 'Downloading skill-builder...'
    $manifest = (Invoke-WebRequest -UseBasicParsing -Uri "$RepoUrl/manifest.txt").Content -split "`n"

    $hookCount = 0
    foreach ($rawLine in $manifest) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }

        $flag = ''
        $path = $line
        if ($line.StartsWith('keep ')) { $flag = 'keep'; $path = $line.Substring(5).Trim() }
        elseif ($line.StartsWith('hook ')) { $flag = 'hook'; $path = $line.Substring(5).Trim() }

        $dest = Join-Path $SkillDir ($path -replace '^skill-builder/', '')

        if ($flag -eq 'keep' -and (Test-Path $dest -PathType Leaf)) {
            Write-Host "Keeping existing $(Split-Path $dest -Leaf) (preserving your edits)..."
            continue
        }

        $destDir = Split-Path $dest -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }

        Invoke-WebRequest -UseBasicParsing -Uri "$RepoUrl/$path" -OutFile $dest
        if ($flag -eq 'hook') { $hookCount++ }
    }

    if ($hookCount -gt 0) {
        Write-Host ''
        Write-Host 'Note: the shipped enforcement hooks come in two variants: bash'
        Write-Host '(protect-directives.sh, unique-persona.sh) and PowerShell companions'
        Write-Host 'for Windows (protect-directives.ps1, unique-persona.ps1). They stay'
        Write-Host 'dormant until wired. To wire the OS-appropriate variant into'
        Write-Host '.claude/settings.local.json, run inside a Claude Code session:'
        Write-Host ''
        Write-Host '    /skill-builder hooks dev skill-builder --execute'
        Write-Host ''
    }

    # Enable agent teams and auto-approve research tools
    $settingsFile = '.claude/settings.local.json'
    Write-Host 'Configuring project settings...'

    if (Test-Path $settingsFile -PathType Leaf) {
        $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
    } else {
        $settings = New-Object PSObject
    }
    $changed = $false

    # Enable agent teams
    if (-not $settings.PSObject.Properties['env']) {
        $settings | Add-Member -NotePropertyName 'env' -NotePropertyValue (New-Object PSObject)
    }
    if ($settings.env.PSObject.Properties['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] -and
        $settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS -eq '1') {
        Write-Host '  Agent teams already enabled'
    } else {
        if ($settings.env.PSObject.Properties['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS']) {
            $settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = '1'
        } else {
            $settings.env | Add-Member -NotePropertyName 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' -NotePropertyValue '1'
        }
        $changed = $true
        Write-Host '  Agent teams enabled'
    }

    # Auto-approve web research tools (belt: permissions layer)
    # The suspenders (PreToolUse hook) are generated per-system by /skill-builder hooks
    $researchTools = @(
        'WebSearch',
        'WebFetch',
        'mcp__jina__read_url',
        'mcp__jina__search_web',
        'mcp__jina__parallel_read_url',
        'mcp__jina__parallel_search_web'
    )
    if (-not $settings.PSObject.Properties['permissions']) {
        $settings | Add-Member -NotePropertyName 'permissions' -NotePropertyValue (New-Object PSObject)
    }
    if (-not $settings.permissions.PSObject.Properties['allow']) {
        $settings.permissions | Add-Member -NotePropertyName 'allow' -NotePropertyValue @()
    }
    $allow = [System.Collections.ArrayList]@($settings.permissions.allow)
    foreach ($tool in $researchTools) {
        if ($allow -notcontains $tool) {
            [void]$allow.Add($tool)
            $changed = $true
            Write-Host "  Added $tool to permissions.allow"
        } else {
            Write-Host "  $tool already in permissions.allow"
        }
    }
    $settings.permissions.allow = $allow.ToArray()

    if ($changed) {
        $settingsDir = Split-Path $settingsFile -Parent
        if ($settingsDir -and -not (Test-Path $settingsDir)) {
            New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
        }
        $json = $settings | ConvertTo-Json -Depth 16
        # BOM-less UTF-8 so every JSON consumer reads it cleanly
        $fullPath = Join-Path (Get-Location) $settingsFile
        [System.IO.File]::WriteAllText($fullPath, $json, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  Settings saved to $settingsFile"
    }

    Write-Host ''
    Write-Host 'Installation complete.'
    Write-Host ''
    Write-Host 'Usage:'
    Write-Host '    /skill-builder                    Full audit (display mode)'
    Write-Host '    /skill-builder optimize [skill]   Show optimization plan (--execute to apply)'
    Write-Host '    /skill-builder agents [skill]     Show agent opportunities (--execute to create)'
    Write-Host '    /skill-builder hooks [skill]      Show hooks inventory (--execute to create)'
    Write-Host '    /skill-builder shell-safety lint [file]  Check shell or settings.json for pitfalls'
    Write-Host '    /skill-builder shell-safety audit [path] Scan and patch fragility (--execute to fix)'
    Write-Host '    /skill-builder route index               Build /route skill index (auto-runs at audit end)'
    Write-Host '    /skill-builder route embed               Plan route consultation gates (--execute to apply)'
    Write-Host ''
}

Install-ClaudeEnforcer
