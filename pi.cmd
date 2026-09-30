@echo off
rem pi - run upstream pi from source (pi-space local launcher)
rem Pure cmd: resolves the local checkout itself and starts node directly.
rem Keep this file ASCII-only and CRLF (see .gitattributes).
setlocal

set "PI_SRC=%~dp0.agents\scratch\pi"
set "CLI=%PI_SRC%\packages\coding-agent\src\cli.ts"
set "CACHE=%~dp0.agents\scratch\node-compile-cache"

if not exist "%CLI%" (
	echo pi: local checkout not found: %CLI% 1>&2
	echo pi: provision it first - see "Local pi command" in README.md 1>&2
	exit /b 1
)

rem --import takes a module specifier, so pass the resolver as a file URL
rem (a bare Windows path is not a valid specifier).
set "RESOLVER=file:///%PI_SRC:\=/%/packages/coding-agent/src/experimental/source-resolver.ts"

rem V8 compile cache for the module closure: saves about 160 ms per start.
if not exist "%CACHE%" mkdir "%CACHE%"
set "NODE_COMPILE_CACHE=%CACHE%"

node --import "%RESOLVER%" "%CLI%" %*
exit /b %ERRORLEVEL%
