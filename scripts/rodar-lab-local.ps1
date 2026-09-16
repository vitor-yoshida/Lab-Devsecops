# =============================================================================
#  rodar-lab-local.ps1 - roda o pipeline DevSecOps INTEIRO no Windows.
#
#  Para que serve: e o plano B. Se a internet cair, se o GitHub ficar fora do
#  ar ou se os minutos do GitHub Actions acabarem, este script executa
#  exatamente as mesmas 4 ferramentas, usando Docker.
#
#  Voce NAO precisa ter Java, Maven, Python ou os scanners instalados.
#  Tudo roda dentro de containers.
#
#  Como usar (PowerShell, dentro da pasta do projeto):
#      .\scripts\rodar-lab-local.ps1
#
#  Para rodar so um estagio:
#      .\scripts\rodar-lab-local.ps1 sast
#      .\scripts\rodar-lab-local.ps1 sca
#      .\scripts\rodar-lab-local.ps1 k8s
#      .\scripts\rodar-lab-local.ps1 dast
#
#  Se o Windows reclamar que "a execucao de scripts foi desabilitada", rode:
#      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# =============================================================================

param(
    [ValidateSet("sast", "sca", "k8s", "dast", "tudo")]
    [string]$Estagio = "tudo"
)

# Vai para a pasta raiz do projeto (um nivel acima da pasta scripts)
$Raiz = Split-Path -Parent $PSScriptRoot
Set-Location $Raiz

function Escrever-Titulo($texto) {
    Write-Host ""
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host " $texto" -ForegroundColor Cyan
    Write-Host "=============================================================" -ForegroundColor Cyan
    Write-Host ""
}

if (-not (Test-Path "relatorios")) {
    New-Item -ItemType Directory -Path "relatorios" | Out-Null
}

# -----------------------------------------------------------------------------
# Antes de tudo: o Docker esta ligado?
# -----------------------------------------------------------------------------
docker info *> $null
if (-not $?) {
    Write-Host "O Docker nao esta rodando." -ForegroundColor Yellow
    Write-Host "Abra o Docker Desktop, espere a baleia ficar verde e rode de novo."
    exit 1
}

# =============================================================================
# ESTAGIO 1 - SAST: SpotBugs + FindSecBugs
# Le o nosso codigo Java procurando falhas que nos mesmos escrevemos.
# =============================================================================
function Rodar-Sast {
    Escrever-Titulo "ESTAGIO 1 de 4 - SAST - SpotBugs + FindSecBugs"
    Write-Host "Lendo o NOSSO codigo-fonte em busca de falhas de seguranca..."
    Write-Host "(na primeira vez o Maven baixa as bibliotecas; pode demorar)"
    Write-Host ""

    docker run --rm `
        -v "${Raiz}:/app" `
        -w /app `
        -v lab-devsecops-m2:/root/.m2 `
        maven:3.9-eclipse-temurin-17 `
        mvn -B clean compile spotbugs:spotbugs

    if (Test-Path "target\spotbugsXml.xml") {
        Copy-Item "target\spotbugsXml.xml" "relatorios\" -Force
        if (Test-Path "target\site\spotbugs.html") {
            Copy-Item "target\site\spotbugs.html" "relatorios\" -Force
        }

        Write-Host ""
        Write-Host "Falhas encontradas no nosso codigo:" -ForegroundColor Green

        Select-String -Path "target\spotbugsXml.xml" -Pattern "<BugInstance[^>]*type='([A-Z_0-9]+)'" -AllMatches |
            ForEach-Object { $_.Matches } |
            ForEach-Object { $_.Groups[1].Value } |
            Group-Object |
            Sort-Object Count -Descending |
            Format-Table @{ Label = "Quantidade"; Expression = { $_.Count } },
                         @{ Label = "Regra acionada"; Expression = { $_.Name } } -AutoSize

        Write-Host "Relatorio visual: relatorios\spotbugs.html (abra no navegador)"
    }
    else {
        Write-Host "O relatorio nao foi gerado. Veja as mensagens acima." -ForegroundColor Yellow
    }
}

# =============================================================================
# ESTAGIO 2 - SCA: Syft + Grype
# Syft lista TUDO que existe dentro da imagem; Grype confere quais itens
# dessa lista tem falhas de seguranca publicas (CVEs).
# =============================================================================
function Rodar-Sca {
    Escrever-Titulo "ESTAGIO 2 de 4 - SCA - Syft + Grype"
    Write-Host "Construindo a imagem Docker da aplicacao..."
    docker build -t app-vulneravel:latest .

    Write-Host ""
    Write-Host "Syft: montando a lista de ingredientes (SBOM)..."
    docker run --rm `
        -v "/var/run/docker.sock:/var/run/docker.sock" `
        -v "${Raiz}\relatorios:/relatorios" `
        anchore/syft:latest `
        app-vulneravel:latest -o cyclonedx-json=/relatorios/sbom.cyclonedx.json

    Write-Host ""
    Write-Host "Grype: procurando falhas conhecidas nessas bibliotecas..." -ForegroundColor Green
    docker run --rm `
        -v "${Raiz}\relatorios:/relatorios" `
        anchore/grype:latest `
        sbom:/relatorios/sbom.cyclonedx.json -o table |
        Tee-Object -FilePath "relatorios\grype-resultado.txt"

    Write-Host ""
    Write-Host "Resumo por gravidade:"
    foreach ($nivel in @("Critical", "High", "Medium", "Low")) {
        $qtd = (Select-String -Path "relatorios\grype-resultado.txt" -Pattern "$nivel").Count
        Write-Host "  $nivel : $qtd"
    }
}

# =============================================================================
# ESTAGIO 3 - Kubernetes: Kubescape
# Le os arquivos YAML da pasta k8s/ e compara com as boas praticas da NSA.
# =============================================================================
function Rodar-K8s {
    Escrever-Titulo "ESTAGIO 3 de 4 - KUBERNETES - Kubescape"
    Write-Host "Vistoriando os manifestos da pasta k8s\ ..."
    Write-Host ""

    docker run --rm `
        -v "${Raiz}\k8s:/k8s" `
        quay.io/kubescape/kubescape-cli:latest `
        scan framework nsa /k8s --format pretty-printer --verbose |
        Tee-Object -FilePath "relatorios\kubescape-resultado.txt"
}

# =============================================================================
# ESTAGIO 4 - DAST: Wapiti
# Sobe a aplicacao de verdade e ataca ela pelo navegador, sem ver o codigo.
# =============================================================================
function Rodar-Dast {
    Escrever-Titulo "ESTAGIO 4 de 4 - DAST - Wapiti"
    Write-Host "Subindo a aplicacao vulneravel..."
    docker compose up -d --build app-vulneravel

    Write-Host "Esperando a aplicacao responder em http://localhost:8080 ..."
    for ($tentativa = 1; $tentativa -le 60; $tentativa++) {
        try {
            Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 3 | Out-Null
            Write-Host "Aplicacao no ar!" -ForegroundColor Green
            break
        }
        catch {
            Start-Sleep -Seconds 2
        }
    }

    Write-Host ""
    Write-Host "Soltando o Wapiti contra a aplicacao (leva alguns minutos)..."
    docker compose --profile dast run --rm wapiti

    Write-Host ""
    Write-Host "Derrubando a aplicacao..."
    docker compose down

    Write-Host ""
    Write-Host "Relatorio do Wapiti: relatorios\wapiti\ (abra o arquivo .html)" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# Decide o que rodar
# -----------------------------------------------------------------------------
switch ($Estagio) {
    "sast" { Rodar-Sast }
    "sca"  { Rodar-Sca }
    "k8s"  { Rodar-K8s }
    "dast" { Rodar-Dast }
    "tudo" {
        Rodar-Sast
        Rodar-Sca
        Rodar-K8s
        Rodar-Dast
        Escrever-Titulo "PIPELINE COMPLETO - relatorios na pasta relatorios\"
        Get-ChildItem "relatorios" | Select-Object Name, Length
    }
}
