---
title: Estágios, jobs e passos
version: 1
---

**Uma definição do Azure Pipelines é um arquivo YAML no repositório**, em geral `azure-pipelines.yml` na
raiz, e o Azure DevOps o lê a partir do commit que executa. É esse o ponto: a esteira é revisada no mesmo
pull request do código que ela constrói, e um commit antigo é reconstruído com a esteira que tinha na
época. As esteiras "clássicas", mais antigas, desenhadas num editor web, ainda existem e não são
ensinadas aqui, porque uma esteira de que ninguém consegue tirar um diff é uma esteira que ninguém revisa.

Esta é a da loja. Ela **não foi executada**: executá-la exige uma organização do Azure DevOps, um projeto
e uma service connection para uma assinatura, e nada disso existe no laboratório.

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include: [main]

pool:
  vmImage: ubuntu-24.04

variables:
  image: crshop.azurecr.io/shop/api

stages:
  - stage: Build
    jobs:
      - job: test_and_push
        steps:
          - script: python -m pip install -r requirements.txt
            displayName: Install
          - script: python -m unittest discover -s tests
            displayName: Test
          - task: Docker@2
            displayName: Build and push
            inputs:
              containerRegistry: crshop
              repository: shop/api
              command: buildAndPush
              tags: $(Build.SourceVersion)

  - stage: Deploy
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: web
        environment: shop-production
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebAppContainer@1
                  inputs:
                    azureSubscription: shop-production
                    appName: app-shop-api
                    deployToSlotOrASE: true
                    resourceGroupName: rg-shop
                    slotName: staging
                    containers: $(image):$(Build.SourceVersion)
```

Leia como três níveis, um dentro do outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma esteira desenhada como árvore. A esteira contém dois estágios, Build e Deploy, com uma seta de Build para Deploy marcada dependsOn. Build contém um job, test_and_push, que contém três passos. Deploy contém um job de deployment, web, ligado ao ambiente shop-production. Cada job roda num agente novo.\"><defs><marker id=\"ah-tree\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"210\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"40\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">esteira: azure-pipelines.yml</text><rect x=\"40\" y=\"55\" width=\"300\" height=\"160\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">estágio Build</text><rect x=\"380\" y=\"55\" width=\"300\" height=\"160\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">estágio Deploy</text><path d=\"M340 72 L378 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-tree)\"></path><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">dependsOn</text><rect x=\"55\" y=\"88\" width=\"270\" height=\"115\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">job test_and_push</text><text x=\"190\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">passo: Install</text><text x=\"190\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">passo: Test</text><text x=\"190\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">passo: Build and push</text><text x=\"190\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um agente novo</text><rect x=\"395\" y=\"88\" width=\"270\" height=\"115\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">deployment web</text><text x=\"530\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ambiente: shop-production</text><text x=\"530\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">passo: AzureWebAppContainer</text><text x=\"530\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">outro agente novo</text></svg>", "caption": "Estágios rodam em ordem, jobs rodam em agentes, passos rodam dentro de um job. Só o job tem uma máquina."}
```

**Um estágio** é uma fase com nome: `Build`, `Deploy`. Os estágios rodam em ordem, a menos que `dependsOn`
diga outra coisa, e um estágio cuja `condition` é falsa é pulado em vez de falhar. O estágio `Deploy`
acima só roda depois que `Build` deu certo e só para a `main`; um pull request constrói e testa, e não faz
deploy de nada.

**Um job** é a unidade que ganha uma máquina. Cada job é enviado a um **agente** do `pool`: aqui,
`ubuntu-24.04`, uma das imagens hospedadas pela Microsoft, uma máquina virtual nova por job, jogada fora
depois. Dois jobs nunca dividem um disco, então um arquivo construído num job não está no próximo a menos
que tenha sido publicado como **artefato** e baixado de novo. Jobs dentro de um estágio rodam em paralelo
quando há agentes livres, o que depende de quantos jobs paralelos a organização paga.

**Um passo** roda dentro de um job, em ordem, no agente daquele job. `script` roda um comando de shell;
`task` roda um passo empacotado, como o `Docker@2`, com entradas. O número depois do `@` é a versão maior
da task, e fixá-la importa pelo mesmo motivo que fixar qualquer coisa importa.

## De onde vem a identidade

O passo de deploy cita `azureSubscription: shop-production`. Isso não é o id de uma assinatura: é o nome de
uma **service connection**, um objeto no projeto do Azure DevOps que guarda como entrar no Azure. Criada
com **federação de identidade de carga de trabalho**, ela não guarda segredo nenhum, e a lição 2 explica
como isso funciona no GitHub Actions, onde o mecanismo é o mesmo. O passo nunca vê uma senha; o agente pede
um token como a identidade da connection, e só recebe um para a esteira que foi autorizada a usá-la.

## Pagando pelos agentes

Agentes hospedados pela Microsoft são cobrados como **jobs paralelos**, não por minuto: uma organização
tem um número de jobs que podem rodar ao mesmo tempo, e uma faixa gratuita com um teto mensal de minutos
para projetos privados. Um agente auto-hospedado é a sua própria máquina rodando o programa de agente da
Microsoft, com a sua própria cota de jobs paralelos. Os valores mudam, e este curso não conseguiu lê-los na
lista de preços (a lição 1, seção 03, diz por quê); confira na página de preços do Azure DevOps antes de
planejar uma equipe em cima deles.
