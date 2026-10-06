---
title: GitHub Actions e GitLab CI, termo a termo
version: 1
---

A maior parte do que se aprende num serviço vale no outro, e no Jenkins, CircleCI, Azure Pipelines ou
Bitbucket Pipelines. Os nomes mudam; o ciclo da aula 5 não. Este é o dicionário dos dois que o curso
usou:

| ideia | GitHub Actions | GitLab CI |
|---|---|---|
| o arquivo do pipeline | `.github/workflows/*.yml`, um workflow por arquivo | `.gitlab-ci.yml`, um por repositório, com `include` para mais |
| o que dispara | `on:` | `workflow: rules:` e `rules:` por job |
| uma unidade de trabalho numa máquina | job | job |
| ordem | `needs:` entre jobs | `stages:` em ordem, ou `needs:` para um grafo |
| um comando | um passo com `run:` | uma linha de `script:` |
| um passo empacotado reutilizável | uma action, `uses: dono/repo@sha` | um componente de CI/CD, ou `include:` de um modelo |
| onde roda | `runs-on:` um runner hospedado ou próprio | um runner, escolhido por `tags:`, em geral dentro de `image:` |
| matriz | `strategy: matrix:` | `parallel: matrix:` |
| rodar depois de falha | `if: always()` | `when: always` |
| arquivos entre jobs | actions de envio e download de artefato | `artifacts:`, passados aos estágios seguintes |
| cache | `actions/cache`, ou o `cache:` de uma action de preparação | `cache:` com uma `key:` |
| relatório de teste na página | enviado como artefato, ou por uma action que anota | `artifacts: reports: junit:` |
| segredos | `${{ secrets.NOME }}`, por repositório ou ambiente | variáveis de CI/CD, mascaradas e protegidas |
| reaproveitar um pipeline | `workflow_call` | `include:` e `trigger:` |
| uma execução por vez | `concurrency:` | `resource_group:`, e jobs interrompíveis |

## Diferenças que mudam o jeito de escrever

Três diferenças são mais que vocabulário.

**Contêineres por padrão.** Um job do GitLab em geral roda dentro da imagem que nomeia, então o
ambiente dele é a imagem; um job hospedado no GitHub roda numa máquina virtual completa e instala o
que precisa com actions de preparação. O arquivo do GitLab escolheu a versão do Python pela imagem; o
do GitHub, pelo `setup-python`.

**Estágios contra um grafo.** Os estágios do GitLab são uma linha simples: tudo num estágio espera o
estágio anterior inteiro. O GitHub só tem o grafo de `needs`. O GitLab também oferece `needs` para
quando a linha é rígida demais.

**Artefatos fluem por padrão no GitLab.** Um estágio seguinte recebe os artefatos anteriores sem pedir;
no GitHub toda entrega é um envio e um download explícitos.

O que não muda é a substância deste curso. Os dois rodam cada job a partir de um checkout limpo, os
dois decidem sucesso pelo código de saída, os dois guardam relatórios e liberam um merge por uma
verificação. **Aprenda o ciclo uma vez; consulte a sintaxe.**
