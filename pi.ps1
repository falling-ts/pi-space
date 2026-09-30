# pi - run upstream pi from source (pi-space local launcher)
#
# Lives at the repo root. The pi checkout itself is a local working copy at
# .agents/scratch/pi (a copy of the read-only submodule refs/pi), so this file
# never touches refs/pi.
#
# Mirrors upstream pi-test.ps1: node --import <source-resolver> <cli.ts>
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$piRoot = Join-Path $repoRoot ".agents\scratch\pi"
$resolver = Join-Path $piRoot "packages\coding-agent\src\experimental\source-resolver.ts"
$cli = Join-Path $piRoot "packages\coding-agent\src\cli.ts"

if (-not (Test-Path -LiteralPath $cli)) {
	[Console]::Error.WriteLine("pi: local checkout not found: $cli")
	[Console]::Error.WriteLine('pi: provision it first - see "Local pi command" in README.md')
	exit 1
}

# --import takes a module specifier, so pass the resolver as a file URL
# (a bare Windows path is not a valid specifier).
$resolverUrl = ([System.Uri]$resolver).AbsoluteUri

& node --import $resolverUrl $cli @args
exit $LASTEXITCODE
