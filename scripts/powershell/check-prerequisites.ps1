#!/usr/bin/env pwsh

# Consolidated prerequisite checking script (PowerShell)
#
# This script provides unified prerequisite checking for MiniSpec workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: ./check-prerequisites.ps1 [OPTIONS]
#
# OPTIONS:
#   -Json               Output in JSON format
#   -RequireTasks       Require tasks.md to exist (for implementation phase)
#   -RequireDesign      Require design.md to exist (for task creation phase)
#   -PathsOnly          Only output path variables (no validation)
#   -Help, -h           Show help message

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$RequireTasks,
    [switch]$RequireDesign,
    [switch]$PathsOnly,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: check-prerequisites.ps1 [OPTIONS]

Consolidated prerequisite checking for MiniSpec workflow.

OPTIONS:
  -Json               Output in JSON format
  -RequireTasks       Require tasks.md to exist (for implementation phase)
  -RequireDesign      Require design.md to exist (for task creation phase)
  -PathsOnly          Only output path variables (no prerequisite validation)
  -Help, -h           Show this help message

EXAMPLES:
  # Check task prerequisites (design.md required)
  .\check-prerequisites.ps1 -Json -RequireDesign

  # Check implementation prerequisites (design.md + tasks.md required)
  .\check-prerequisites.ps1 -Json -RequireDesign -RequireTasks

  # Get feature paths only (no validation)
  .\check-prerequisites.ps1 -PathsOnly

"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# Get feature paths and validate branch
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) {
    exit 1
}

# If paths-only mode, output paths and exit (support combined -Json -PathsOnly)
if ($PathsOnly) {
    if ($Json) {
        [PSCustomObject]@{
            REPO_ROOT     = $paths.REPO_ROOT
            BRANCH        = $paths.CURRENT_BRANCH
            FEATURE_DIR   = $paths.FEATURE_DIR
            DESIGN        = $paths.DESIGN
            TASKS         = $paths.TASKS
            KNOWLEDGE_DIR = $paths.KNOWLEDGE_DIR
        } | ConvertTo-Json -Compress
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "DESIGN: $($paths.DESIGN)"
        Write-Output "TASKS: $($paths.TASKS)"
        Write-Output "KNOWLEDGE_DIR: $($paths.KNOWLEDGE_DIR)"
    }
    exit 0
}

# Validate required directories and files
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $($paths.FEATURE_DIR)"
    Write-Output "Run /minispec.design first to create the feature structure."
    exit 1
}

# Check for design.md if required
if ($RequireDesign -and -not (Test-Path $paths.DESIGN -PathType Leaf)) {
    Write-Output "ERROR: design.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /minispec.design first to create the feature design."
    exit 1
}

# Check for tasks.md if required
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "ERROR: tasks.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /minispec.tasks first to create the task list."
    exit 1
}

# Build list of available documents
$docs = @()

# Check design and tasks
if (Test-Path $paths.DESIGN) { $docs += 'design.md' }
if (Test-Path $paths.TASKS) { $docs += 'tasks.md' }

# Check checklists directory (only if it exists and has files)
if ((Test-Path $paths.CHECKLISTS_DIR) -and (Get-ChildItem -Path $paths.CHECKLISTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    $docs += 'checklists/'
}

# Check knowledge base
if (Test-Path $paths.KNOWLEDGE_DIR) { $docs += 'knowledge/' }

# Output results
if ($Json) {
    # JSON output
    [PSCustomObject]@{
        FEATURE_DIR = $paths.FEATURE_DIR
        AVAILABLE_DOCS = $docs
    } | ConvertTo-Json -Compress
} else {
    # Text output
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"

    # Show status of each potential document
    Test-FileExists -Path $paths.DESIGN -Description 'design.md' | Out-Null
    Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    Test-DirHasFiles -Path $paths.CHECKLISTS_DIR -Description 'checklists/' | Out-Null
    Test-DirHasFiles -Path $paths.KNOWLEDGE_DIR -Description 'knowledge/' | Out-Null
}
