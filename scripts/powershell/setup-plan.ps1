#!/usr/bin/env pwsh
# Setup tasks for a MiniSpec feature

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output "Usage: ./setup-plan.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Load common functions
. "$PSScriptRoot/common.ps1"

# Get all paths and variables from common functions
$paths = Get-FeaturePathsEnv

# Check if we're on a proper feature branch (only for git repos)
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

# Ensure the feature directory exists
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# Copy tasks template if it exists, otherwise note it or create empty file
$template = Join-Path $paths.REPO_ROOT '.minispec/templates/tasks-template.md'
if (Test-Path $template) {
    Copy-Item $template $paths.TASKS -Force
    Write-Output "Copied tasks template to $($paths.TASKS)"
} else {
    Write-Warning "Tasks template not found at $template"
    # Create a basic tasks file if template doesn't exist
    New-Item -ItemType File -Path $paths.TASKS -Force | Out-Null
}

# Output results
if ($Json) {
    $result = [PSCustomObject]@{
        DESIGN = $paths.DESIGN
        TASKS = $paths.TASKS
        FEATURE_DIR = $paths.FEATURE_DIR
        BRANCH = $paths.CURRENT_BRANCH
        HAS_GIT = $paths.HAS_GIT
    }
    $result | ConvertTo-Json -Compress
} else {
    Write-Output "DESIGN: $($paths.DESIGN)"
    Write-Output "TASKS: $($paths.TASKS)"
    Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
}
