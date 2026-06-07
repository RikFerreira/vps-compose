param(
    [string]$Repo
)

$ErrorActionPreference = "Stop"

$requiredKeys = @(
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
    "POSTGRES_DB",
    "SERVER_NAME",
    "SERVER_NAME_WWW",
    "LETSENCRYPT_EMAIL"
)

function Resolve-Repo {
    param([string]$ExplicitRepo)

    if ($ExplicitRepo) {
        return $ExplicitRepo
    }

    $origin = git config --get remote.origin.url
    if (-not $origin) {
        throw "Could not determine the GitHub repository from git remote 'origin'. Pass -Repo owner/name."
    }

    if ($origin -match 'github\.com[:/](.+?)(?:\.git)?$') {
        return $matches[1]
    }

    throw "Unsupported origin URL '$origin'. Pass -Repo owner/name."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI 'gh' is not installed or not on PATH."
}

if (-not (Test-Path .env)) {
    throw "Missing .env in the current directory."
}

$envMap = @{}
foreach ($line in Get-Content .env) {
    if ($line -match '^\s*#') {
        continue
    }

    if ($line -match '^\s*$') {
        continue
    }

    if ($line -match '^\s*([^=\s]+)\s*=\s*(.*)\s*$') {
        $envMap[$matches[1]] = $matches[2]
    }
}

$missing = @($requiredKeys | Where-Object { -not $envMap.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($envMap[$_]) })
if ($missing.Count -gt 0) {
    throw "Missing required keys in .env: $($missing -join ', ')"
}

$repoName = Resolve-Repo -ExplicitRepo $Repo
$tmpFile = [System.IO.Path]::GetTempFileName()

try {
    $content = foreach ($key in $requiredKeys) {
        "$key=$($envMap[$key])"
    }

    Set-Content -LiteralPath $tmpFile -Value $content -Encoding ascii
    gh secret set --repo $repoName --env-file $tmpFile
}
finally {
    Remove-Item -LiteralPath $tmpFile -ErrorAction SilentlyContinue
}
