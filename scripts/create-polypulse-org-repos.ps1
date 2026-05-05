# Run from repo root if you wish: .\scripts\create-polypulse-org-repos.ps1
# Prompts for a GitHub PAT with permission to CREATE repositories under TitanFlow-Systems (change `$Org` for other orgs).

param(
    [string]$Org = "TitanFlow-Systems",
    [SecureString]$GitHubToken = $(Read-Host -AsSecureString -Prompt "GitHub PAT (hidden)")
)

$BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken)
try {
    $Plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) | Out-Null
}

$hdr = @{
    Authorization = "Bearer $Plain"
    Accept          = "application/vnd.github+json"
}

function Set-RepoTopics([string]$Repo, [string[]]$Names) {
    if ($Names.Count -gt 20) { throw "GitHub allows at most 20 topics; got $($Names.Count)." }
    $body = @{ names = $Names } | ConvertTo-Json -Compress
    Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$Org/$Repo/topics" `
        -Method Put `
        -Headers ($hdr + @{ "X-GitHub-Api-Version" = "2022-11-28" }) `
        -Body $body `
        -ContentType "application/json"
}

$repos = @(
    @{
        Name        = "best-of-algorithmic-trading"
        Description = "Ranked best-of algorithmic trading list: quant bots, TA libs, backtesting, crypto APIs Freqtrade Hummingbot Python Node TS fintech education polymarket automation validation"
        Homepage    = "https://github.com/$Org/best-of-algorithmic-trading#readme"
        Topics      = @(
            "algorithmic-trading","trading-bot","quantitative-finance","cryptocurrency",
            "freqtrade","hummingbot","backtesting","technical-analysis","python","typescript",
            "nodejs","crypto-trading","open-source","fintech","algo-trading","best-of-list",
            "bitcoin","ethereum","machine-learning","defi"
        )
    },
    @{
        Name        = "polymarket-trading-bot-v2"
        Description = "Polymarket polygon ethereum USDC CLOB prediction-markets crypto trading-bot arbitrage copy-trading automated-trading javascript nodejs websocket DeFi blockchain quant algorithmic-trading API market-making conditional-tokens BTC merge redeem polymarket-api ethers crypto-bot liquidity systematic systematic-trading maker-taker depth spread gas signer gamma scalping volatility alpha npm opensource forecasting binary microstructure web3 on-chain proxy-wallet gamma-api traders"
        Homepage    = "https://github.com/$Org/polymarket-trading-bot-v2#readme"
        Topics      = @(
            "polymarket","prediction-markets","trading-bot","cryptocurrency","ethereum","polygon","defi","clob","arbitrage","copy-trading",
            "automated-trading","javascript","nodejs","websocket","blockchain","algorithmic-trading","market-making","crypto-bot","quantitative-trading","api"
        )
    }
)

foreach ($r in $repos) {
    Write-Host "Creating $($r.Name)..." -ForegroundColor Cyan
    $create = @{
        name        = $r.Name
        description = $r.Description
        homepage    = $r.Homepage
        private     = $false
    } | ConvertTo-Json -Compress
    try {
        Invoke-RestMethod -Uri "https://api.github.com/orgs/$Org/repos" -Method Post -Headers $hdr -Body $create -ContentType "application/json"
    }
    catch {
        $code = $null
        if ($_.Exception.Response) { $code = $_.Exception.Response.StatusCode.value__ }
        if ($code -eq 422) {
            Write-Host "  Repo may already exist (422)." -ForegroundColor Yellow
        }
        else {
            throw
        }
    }
    Set-RepoTopics -Repo $r.Name -Names $r.Topics
    Write-Host "  Topics set." -ForegroundColor Green
}

Write-Host "Done. Push: git remote add polypulse https://github.com/$Org/<repo>.git ; git push -u polypulse <branch>" -ForegroundColor Green
