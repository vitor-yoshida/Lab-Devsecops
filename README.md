# Laboratório DevSecOps — Pipeline de Segurança do Zero

Este repositório é um **laboratório educacional**. Ele mostra, na prática, como colocar
quatro ferramentas de segurança dentro de uma esteira automatizada (pipeline) que roda
sozinha toda vez que o código muda.

A cobaia é uma aplicação Java **propositalmente cheia de falhas**. Cada ferramenta do
pipeline encontra um tipo diferente de problema.

---

## ⚠️ Aviso importante

> A aplicação deste repositório é **insegura de propósito**.
> Ela contém SQL Injection, XSS, Command Injection, Path Traversal, senha escrita no
> código e bibliotecas com falhas graves conhecidas.
>
> **Nunca** publique esta aplicação na internet, **nunca** a use como base para um projeto
> real e rode-a apenas na sua máquina ou em um ambiente isolado.
>
> Objetivo: ensinar a **encontrar** essas falhas, não a conviver com elas.

---

## O que é DevSecOps, em uma frase

É colocar a segurança **dentro** do processo de desenvolvimento, de forma automática,
em vez de deixar para testar tudo no final, quando corrigir custa caro.

---

## Os 4 estágios do pipeline

| # | Estágio | Ferramenta | O que ela examina | Analogia |
|---|---------|------------|-------------------|----------|
| 1 | **SAST** | SpotBugs + FindSecBugs | O código-fonte que **nós** escrevemos | O revisor que lê a receita antes de acender o forno |
| 2 | **SCA** | Syft + Grype | As bibliotecas de **terceiros** que usamos | A conferência dos ingredientes comprados prontos |
| 3 | **K8s** | Kubescape | Os arquivos de configuração do Kubernetes | A vistoria da cozinha onde o bolo será feito |
| 4 | **DAST** | Wapiti | A aplicação **rodando de verdade** | O inspetor que prova o bolo pronto |

Cada ferramenta enxerga uma camada diferente. Nenhuma sozinha resolve — é a soma delas
que dá uma visão completa.

### O que cada ferramenta faz

- **SpotBugs** lê o código Java já compilado e procura por erros de programação.
  O **FindSecBugs** é um pacote de regras que ensina o SpotBugs a reconhecer falhas de
  *segurança* especificamente (injeção de SQL, criptografia fraca, etc.).
- **Syft** monta o **SBOM** (*Software Bill of Materials*) — a lista completa de tudo que
  existe dentro da nossa imagem Docker, incluindo bibliotecas que vieram junto sem a gente
  perceber.
- **Grype** pega essa lista e compara com bancos públicos de vulnerabilidades (CVEs),
  respondendo: "quais dos meus ingredientes estão estragados?".
- **Kubescape** analisa os manifestos do Kubernetes e compara com frameworks de boas
  práticas (como o da NSA/CISA), apontando configurações perigosas.
- **Wapiti** é um scanner *caixa-preta*: ele não vê o código, apenas navega no site,
  preenche formulários e dispara ataques reais para ver como a aplicação reage.

---

## Vulnerabilidades plantadas de propósito

| Onde | Vulnerabilidade | Quem encontra |
|------|-----------------|---------------|
| `ControladorUsuario.java` | SQL Injection | SpotBugs e Wapiti |
| `ControladorBusca.java` | XSS Refletido | SpotBugs e Wapiti |
| `ControladorArquivo.java` | Path Traversal | SpotBugs e Wapiti |
| `ControladorSistema.java` | Command Injection | SpotBugs e Wapiti |
| `ServicoSenha.java` | MD5, senha no código, aleatório previsível | SpotBugs |
| `pom.xml` | Bibliotecas com CVEs (Log4Shell e outras) | Syft e Grype |
| `Dockerfile` | Imagem base antiga, container como root | Grype |
| `k8s/deployment.yaml` | Container privilegiado, sem limites, segredo exposto | Kubescape |

---

## Estrutura do repositório

```
.
├── .github/workflows/devsecops.yml   # o pipeline automatizado (5 etapas)
├── src/main/java/br/com/labdevsecops/
│   ├── AplicacaoVulneravel.java      # inicia o servidor web
│   ├── controlador/                  # uma vulnerabilidade por arquivo
│   └── servico/ServicoSenha.java     # falhas de criptografia
├── src/main/resources/               # configuração e banco de dados de exemplo
├── k8s/
│   ├── deployment.yaml               # más práticas de Kubernetes (comentadas)
│   └── service.yaml
├── scripts/
│   ├── rodar-lab-local.ps1           # roda tudo no Windows
│   └── rodar-lab-local.sh            # roda tudo no Linux/macOS
├── Dockerfile                        # empacota a aplicação em container
├── docker-compose.yml                # sobe a aplicação + o scanner Wapiti
└── pom.xml                           # dependências e configuração do SpotBugs
```

---

## Pré-requisitos

- **Git** — para baixar o repositório
- **Docker Desktop** (ou Docker Engine) — roda tudo; você **não** precisa instalar Java
- Uma **conta no GitHub** — para ver o pipeline rodando na nuvem

---

## Como rodar

### Opção A — No GitHub Actions (recomendado)

1. Faça um *fork* ou envie este repositório para a sua conta do GitHub.
2. Abra a aba **Actions** do repositório.
3. Escolha o workflow **Pipeline DevSecOps** e clique em **Run workflow**.
4. Acompanhe os 5 blocos executando em sequência.
5. Ao final, leia o **Summary** da execução e baixe os relatórios na seção **Artifacts**.

O pipeline também dispara sozinho a cada `push` na branch `main`.

### Opção B — Na sua máquina

**Windows (PowerShell):**

```powershell
.\scripts\rodar-lab-local.ps1
```

**Linux / macOS:**

```bash
chmod +x scripts/rodar-lab-local.sh
./scripts/rodar-lab-local.sh
```

Para rodar apenas um estágio, passe o nome dele: `sast`, `sca`, `k8s` ou `dast`.

Os resultados ficam na pasta `relatorios/`.

### Só quero ver a aplicação vulnerável no navegador

```bash
docker compose up --build app-vulneravel
```

Depois acesse **http://localhost:8080** e clique nos links da página inicial.
Para desligar: `docker compose down`.

---

## Modo relatório

Este pipeline está configurado para **nunca falhar**, mesmo encontrando vulnerabilidades
críticas. Isso é proposital: em um laboratório, queremos ver os quatro estágios rodando
até o fim em uma única execução.

Em um projeto real, você faria o contrário — achados de severidade alta ou crítica
deveriam **bloquear o deploy**. No workflow, isso é o comportamento padrão das
ferramentas quando se remove as linhas `continue-on-error: true`.

---

## Licença e uso

Material educacional, livre para uso em aulas, treinamentos e estudos.
Use com responsabilidade: teste segurança apenas em sistemas que você tem
autorização para testar.
