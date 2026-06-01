param(
    [string]$Root = "C:\Users\wepie\My project\Assets\unity-shadertoy-validation"
)

$ErrorActionPreference = "Stop"

Write-Host "[check-porting] root: $Root"

$shaderFiles = Get-ChildItem -Path $Root -Recurse -File -Filter *.shader
$scriptFiles = Get-ChildItem -Path $Root -Recurse -File -Filter *Bootstrap.cs

$issues = @()

foreach ($f in $shaderFiles) {
    $txt = Get-Content -Raw $f.FullName
    if ($txt -match "AutoScaffold") {
        $issues += "[AUTO_SCAFFOLD] $($f.FullName)"
    }
    if ($txt -match "\batan2\s*\(" -and $txt -notmatch "AtanGLSL") {
        $issues += "[ATAN2_DIRECT] $($f.FullName)"
    }
    if ($txt -match "\bfmod\s*\(" -and $txt -notmatch "ModGLSL") {
        $issues += "[FMOD_DIRECT] $($f.FullName)"
    }
    if ($txt -match "\basin\s*\(" -and $txt -notmatch "SafeAsin") {
        $issues += "[ASIN_DIRECT] $($f.FullName)"
    }
}

foreach ($f in $scriptFiles) {
    $txt = Get-Content -Raw $f.FullName
    if ($txt -match "TargetShaderName\s*=>\s*`"Shadertoy/.+AutoScaffold") {
        $issues += "[BOOTSTRAP_AUTO_SCAFFOLD] $($f.FullName)"
    }
}

if ($issues.Count -eq 0) {
    Write-Host "[check-porting] OK: no high-risk pattern found."
    exit 0
}

Write-Host "[check-porting] FOUND $($issues.Count) issue(s):"
$issues | ForEach-Object { Write-Host " - $_" }
exit 1

