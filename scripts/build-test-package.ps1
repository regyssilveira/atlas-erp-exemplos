param(
    [Parameter(Mandatory = $true)][string]$CompilerPath,
    [Parameter(Mandatory = $true)][string]$RunName
)

$ErrorActionPreference = 'Stop'
if ($RunName -notmatch '^[a-zA-Z0-9][a-zA-Z0-9-]{0,63}$') {
    throw 'RunName must be an alphanumeric identifier with optional hyphens.'
}
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$compiler = (Resolve-Path -LiteralPath $CompilerPath).Path
if ([IO.Path]::GetFileName($compiler) -ine 'dcc32.exe') {
    throw 'This example requires an explicitly selected dcc32.exe.'
}
$runRoot = Join-Path $repoRoot "build/$RunName"
if (Test-Path -LiteralPath $runRoot) {
    throw 'Use a new RunName; existing outputs are never reused or deleted.'
}
New-Item -ItemType Directory -Path $runRoot | Out-Null
$packageRoot = Join-Path $runRoot 'package'
$projects = @(
    'tests/Atlas.Domain.Tests/AtlasDomainTests.dpr',
    'tests/Atlas.Persistence.FireDAC.Tests/AtlasPersistenceFireDACTests.dpr',
    'tests/Atlas.Legacy.Tests/AtlasLegacyTests.dpr'
)
$results = @()
try {
    foreach ($project in $projects) {
        $projectPath = Join-Path $repoRoot $project
        $name = [IO.Path]::GetFileNameWithoutExtension($project)
        $projectOutput = Join-Path $runRoot $name
        New-Item -ItemType Directory -Path $projectOutput | Out-Null
        Push-Location ([IO.Path]::GetDirectoryName($projectPath))
        try {
            $buildLog = & $compiler '-B' "-E$projectOutput" "-N0$projectOutput" $projectPath 2>&1
            $buildExit = $LASTEXITCODE
            $buildLog | Set-Content -LiteralPath (Join-Path $projectOutput 'build.log') -Encoding UTF8
            $buildLog | Write-Output
            if ($buildExit -ne 0) { throw "Compilation failed: $project ($buildExit)" }
            $testExe = Join-Path $projectOutput "$name.exe"
            if (-not (Test-Path -LiteralPath $testExe)) { throw "Missing new executable: $name" }
            $testLog = & $testExe 2>&1
            $testExit = $LASTEXITCODE
            $testLog | Set-Content -LiteralPath (Join-Path $projectOutput 'tests.log') -Encoding UTF8
            $testLog | Write-Output
            if ($testExit -ne 0) { throw "Tests failed: $name ($testExit)" }
            $results += [ordered]@{ project = $project; buildExit = $buildExit; testExit = $testExit }
        } finally { Pop-Location }
    }
    # The package directory is created only after every required suite passes.
    New-Item -ItemType Directory -Path $packageRoot | Out-Null
    foreach ($project in $projects) {
        $name = [IO.Path]::GetFileNameWithoutExtension($project)
        Copy-Item -LiteralPath (Join-Path $runRoot "$name/$name.exe") -Destination $packageRoot
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination $packageRoot
    Copy-Item -LiteralPath (Join-Path $repoRoot 'NOTICE') -Destination $packageRoot
    $files = @(Get-ChildItem -LiteralPath $packageRoot -File | ForEach-Object {
        [ordered]@{ file = $_.Name; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
    $manifest = [ordered]@{
        run = $RunName
        compiler = $compiler
        compilerFileVersion = (Get-Item -LiteralPath $compiler).VersionInfo.FileVersion
        suites = $results
        files = $files
        scope = 'Didactic test executables; not a production ERP release, signature, SBOM or coverage report.'
    }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $packageRoot 'manifest.json') -Encoding UTF8
    Write-Output "APPROVED TEST PACKAGE: $packageRoot"
} catch {
    $_.Exception.Message | Set-Content -LiteralPath (Join-Path $runRoot 'failure.log') -Encoding UTF8
    Write-Error $_
    exit 1
}
