# =============================================================================
#  Dockerfile - a "receita" para empacotar a aplicacao em um container.
#
#  Este arquivo tem DUAS ETAPAS (multi-stage build):
#    Etapa 1 (construtor): usa o Maven para transformar o codigo em um .jar
#    Etapa 2 (final): copia so o .jar para uma imagem menor, que vai rodar
#
#  ATENCAO: esta imagem tem mas praticas DE PROPOSITO (imagem base antiga,
#  processo rodando como root). Elas viram achados no estagio 2 (Syft/Grype).
#  Os comentarios "CERTO SERIA" mostram como corrigir.
# =============================================================================

# ------------------------- ETAPA 1: CONSTRUIR O .JAR -------------------------
FROM maven:3.9-eclipse-temurin-17 AS construtor

WORKDIR /construcao

# Copia primeiro so o pom.xml e baixa as bibliotecas.
# Assim o Docker reaproveita o cache quando so o codigo muda.
COPY pom.xml .
RUN mvn -B dependency:go-offline

# Agora copia o codigo-fonte e gera o pacote .jar
COPY src ./src
RUN mvn -B clean package -DskipTests

# --------------------- ETAPA 2: IMAGEM QUE VAI RODAR -------------------------
# RUIM: imagem base antiga (focal = Ubuntu 20.04), cheia de pacotes de sistema
#       desatualizados. O Grype vai listar dezenas de CVEs por causa disso.
# CERTO SERIA: usar uma base atual e enxuta, ex.: eclipse-temurin:17-jre-alpine
FROM eclipse-temurin:17-jre-focal

WORKDIR /app

# Cria a pasta usada pela rota /arquivo (demonstracao de Path Traversal)
RUN mkdir -p /app/arquivos \
 && echo "Este e um arquivo publico, pode ser lido por qualquer pessoa." > /app/arquivos/publico.txt \
 && echo "SEGREDO=nao_deveria_ser_lido_por_estranhos" > /app/arquivos/segredo.txt

# Copia o .jar pronto da etapa anterior
COPY --from=construtor /construcao/target/app-vulneravel.jar /app/app-vulneravel.jar

# RUIM: nao existe a instrucao USER, entao o container roda como root.
#       Se alguem explorar a Command Injection, vira root dentro do container.
# CERTO SERIA:
#   RUN useradd -r -u 1001 appuser && chown -R appuser /app
#   USER appuser

# Porta onde a aplicacao escuta
EXPOSE 8080

# Comando executado quando o container sobe
ENTRYPOINT ["java", "-jar", "/app/app-vulneravel.jar"]
