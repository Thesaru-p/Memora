param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $envFile)) {
    throw "Missing .env at $envFile"
}

Get-Content -LiteralPath $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
        $name = $matches[1]
        $value = $matches[2].Trim().Trim('"').Trim("'")
        Set-Item -Path "Env:$name" -Value $value
    }
}

$jacPath = (Get-Command jac.exe -ErrorAction SilentlyContinue).Source
if (-not $jacPath) {
    $pythonScripts = Join-Path $env:APPDATA 'Python'
    $jacPath = Get-ChildItem -Path $pythonScripts -Filter 'jac.exe' -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $jacPath) {
    throw 'Jac was not found. Install jaclang and ensure jac.exe is available.'
}

& $jacPath $Command @Arguments
exit $LASTEXITCODE
