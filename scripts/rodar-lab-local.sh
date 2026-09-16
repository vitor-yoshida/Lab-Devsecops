#!/usr/bin/env bash
# =============================================================================
#  rodar-lab-local.sh - roda o pipeline DevSecOps INTEIRO na sua maquina.
#
#  Para que serve: e o plano B. Se a internet cair, se o GitHub ficar fora do
#  ar ou se os minutos do GitHub Actions acabarem, este script executa
#  exatamente as mesmas 4 ferramentas, usando Docker.
#
#  Voce NAO precisa ter Java, Maven, Python ou os scanners instalados.
#  Tudo roda dentro de containers.
#
#  Como usar (Linux ou macOS):
#      chmod +x scripts/rodar-lab-local.sh
#      ./scripts/rodar-lab-local.sh
#
#  Para rodar so um estagio:
#      ./scripts/rodar-lab-local.sh sast
#      ./scripts/rodar-lab-local.sh sca
#      ./scripts/rodar-lab-local.sh k8s
#      ./scripts/rodar-lab-local.sh dast
# =============================================================================

set -u

# Vai para a pasta raiz do projeto (um nivel acima da pasta scripts)
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

# Cores para o texto ficar legivel no telao
VERDE="\033[1;32m"
AZUL="\033[1;36m"
AMARELO="\033[1;33m"
SEM_COR="\033[0m"

titulo() {
    echo ""
    echo -e "${AZUL}=============================================================${SEM_COR}"
    echo -e "${AZUL} $1${SEM_COR}"
    echo -e "${AZUL}=============================================================${SEM_COR}"
    echo ""
}

mkdir -p relatorios

# -----------------------------------------------------------------------------
# Antes de tudo: o Docker esta ligado?
# -----------------------------------------------------------------------------
if ! docker info > /dev/null 2>&1; then
    echo -e "${AMARELO}O Docker nao esta rodando.${SEM_COR}"
    echo "Abra o Docker Desktop, espere a baleia ficar verde e rode de novo."
    exit 1
fi

ESTAGIO="${1:-tudo}"

# =============================================================================
# ESTAGIO 1 - SAST: SpotBugs + FindSecBugs
# Le o nosso codigo Java procurando falhas que nos mesmos escrevemos.
# =============================================================================
rodar_sast() {
    titulo "ESTAGIO 1 de 4 - SAST - SpotBugs + FindSecBugs"
    echo "Lendo o NOSSO codigo-fonte em busca de falhas de seguranca..."
    echo "(na primeira vez o Maven baixa as bibliotecas; pode demorar)"
    echo ""

    docker run --rm \
        -v "$RAIZ":/app \
        -w /app \
        -v lab-devsecops-m2:/root/.m2 \
        maven:3.9-eclipse-temurin-17 \
        mvn -B clean compile spotbugs:spotbugs

    if [ -f target/spotbugsXml.xml ]; then
        cp target/spotbugsXml.xml relatorios/ 2>/dev/null || true
        cp target/site/spotbugs.html relatorios/ 2>/dev/null || true

        echo ""
        echo -e "${VERDE}Falhas encontradas no nosso codigo:${SEM_COR}"
        grep -oE "<BugInstance[^>]*type='[A-Z_0-9]+'" target/spotbugsXml.xml | grep -oE "type='[A-Z_0-9]+'" | tr -d "'" | sed 's/type=//' | sort | uniq -c | sort -rn
        echo ""
        echo "Relatorio visual: relatorios/spotbugs.html (abra no navegador)"
    else
        echo -e "${AMARELO}O relatorio nao foi gerado. Veja as mensagens acima.${SEM_COR}"
    fi
}

# =============================================================================
# ESTAGIO 2 - SCA: Syft + Grype
# Syft lista TUDO que existe dentro da imagem; Grype confere quais itens
# dessa lista tem falhas de seguranca publicas (CVEs).
# =============================================================================
rodar_sca() {
    titulo "ESTAGIO 2 de 4 - SCA - Syft + Grype"
    echo "Construindo a imagem Docker da aplicacao..."
    docker build -t app-vulneravel:latest .

    echo ""
    echo "Syft: montando a lista de ingredientes (SBOM)..."
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$RAIZ/relatorios":/relatorios \
        anchore/syft:latest \
        app-vulneravel:latest -o cyclonedx-json=/relatorios/sbom.cyclonedx.json

    echo ""
    echo -e "${VERDE}Grype: procurando falhas conhecidas nessas bibliotecas...${SEM_COR}"
    docker run --rm \
        -v "$RAIZ/relatorios":/relatorios \
        anchore/grype:latest \
        sbom:/relatorios/sbom.cyclonedx.json -o table \
        | tee relatorios/grype-resultado.txt

    echo ""
    echo "Resumo por gravidade:"
    for NIVEL in Critical High Medium Low; do
        QTD=$(awk -v n="$NIVEL" '{ for (i = 1; i <= NF; i++) if ($i == n) { total++; break } } END { print total + 0 }' relatorios/grype-resultado.txt)
        echo "  $NIVEL: $QTD"
    done
}

# =============================================================================
# ESTAGIO 3 - Kubernetes: Kubescape
# Le os arquivos YAML da pasta k8s/ e compara com as boas praticas da NSA.
# =============================================================================
rodar_k8s() {
    titulo "ESTAGIO 3 de 4 - KUBERNETES - Kubescape"
    echo "Vistoriando os manifestos da pasta k8s/ ..."
    echo ""

    docker run --rm \
        -v "$RAIZ/k8s":/k8s \
        quay.io/kubescape/kubescape-cli:latest \
        scan framework nsa /k8s --format pretty-printer --verbose \
        | tee relatorios/kubescape-resultado.txt
}

# =============================================================================
# ESTAGIO 4 - DAST: Wapiti
# Sobe a aplicacao de verdade e ataca ela pelo navegador, sem ver o codigo.
# =============================================================================
rodar_dast() {
    titulo "ESTAGIO 4 de 4 - DAST - Wapiti"
    echo "Subindo a aplicacao vulneravel..."
    docker compose up -d --build app-vulneravel

    echo "Esperando a aplicacao responder em http://localhost:8080 ..."
    for TENTATIVA in $(seq 1 60); do
        if curl -fsS http://localhost:8080/ > /dev/null 2>&1; then
            echo -e "${VERDE}Aplicacao no ar!${SEM_COR}"
            break
        fi
        sleep 2
    done

    echo ""
    echo "Soltando o Wapiti contra a aplicacao (leva alguns minutos)..."
    docker compose --profile dast run --rm wapiti

    echo ""
    echo "Derrubando a aplicacao..."
    docker compose down

    echo ""
    echo -e "${VERDE}Relatorio do Wapiti: relatorios/wapiti/ (abra o arquivo .html)${SEM_COR}"
}

# -----------------------------------------------------------------------------
# Decide o que rodar
# -----------------------------------------------------------------------------
case "$ESTAGIO" in
    sast) rodar_sast ;;
    sca)  rodar_sca  ;;
    k8s)  rodar_k8s  ;;
    dast) rodar_dast ;;
    tudo)
        rodar_sast
        rodar_sca
        rodar_k8s
        rodar_dast
        titulo "PIPELINE COMPLETO - todos os relatorios estao na pasta relatorios/"
        ls -1 relatorios/
        ;;
    *)
        echo "Uso: $0 [sast|sca|k8s|dast|tudo]"
        exit 1
        ;;
esac
