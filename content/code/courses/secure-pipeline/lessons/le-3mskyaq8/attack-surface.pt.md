---
title: O pipeline é um alvo, porque guarda as chaves
version: 1
---

Quinze aulas trataram o pipeline como quem confere: ele varre o código, as dependências, os segredos
e a imagem, e a aula 14 o tornou a única parte que assina. **Cada um desses trabalhos faz o pipeline
valer um ataque.** Um job de CI guarda o que o laptop de quem desenvolve não deveria guardar: um token
que escreve no repositório, credenciais do registry, a chave que assina releases e, muitas vezes, um
caminho até produção. Quem consegue fazer o job rodar uma linha escolhida por si leva tudo isso,
durante o tempo do job, sem tocar numa única máquina de produção.

### O que um job guarda, e quem consegue dirigi-lo

A imagem comum é que um pipeline roda "o nosso código". Ele roda o que o evento que o iniciou mandar
rodar, e na maioria das plataformas vários eventos podem ser iniciados por gente de fora do time:

| o que o job guarda | de onde vem | quem pode influenciar o que roda |
|---|---|---|
| um token do repositório | a plataforma de CI, para cada job | quem escreveu o arquivo de workflow, e de quem é o código que o job baixa |
| credenciais do registry | o cofre de segredos da plataforma | os mesmos, mais toda action que o job usa |
| uma chave de assinatura | os arquivos do próprio servidor de CI, como na aula 14 | todo script que o build roda, já que o `ci/sign.sh` vem do commit |
| alcance de rede | o lugar do runner na rede | qualquer coisa que o job execute |

**A coluna da direita é a superfície de ataque**, e ela é mais longa do que parece: um pull request de
um estranho, o título que alguém digitou nesse pull request, o autor de uma action que o workflow
nomeia por tag, e a pessoa que controla a máquina em que o runner está.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"sp-l16-surface\" aria-label=\"Um job de CI no meio, segurando um token do repositório, credenciais do registry, uma chave de assinatura e alcance de rede. Quatro partes podem influenciar o que ele roda: o autor de um pull request, quem digitou texto no pull request, o autor de uma action nomeada por tag e quem controla a máquina do runner.\"><defs><marker id=\"sp-l16-surface-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l16-surface-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">autor do pull request</text><text x=\"110.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o código que ele baixa</text><path d=\"M210 42 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"10\" y=\"80\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">texto do pull request</text><text x=\"110.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">título, branch, descrição</text><path d=\"M210 102 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"10\" y=\"140\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">autor da action</text><text x=\"110.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma tag que ele move</text><path d=\"M210 162 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"10\" y=\"200\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dono do runner</text><text x=\"110.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a própria máquina</text><path d=\"M210 222 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"270\" y=\"95\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um job de CI</text><text x=\"350.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ci/pipeline.sh</text><text x=\"600\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que ele segura</text><rect x=\"500\" y=\"25\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">token do repositório</text><path d=\"M430 130 L498 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path><rect x=\"500\" y=\"80\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">credenciais do registry</text><path d=\"M430 130 L498 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path><rect x=\"500\" y=\"135\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de assinatura</text><path d=\"M430 130 L498 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path><rect x=\"500\" y=\"190\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alcance de rede</text><path d=\"M430 130 L498 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path></svg>", "caption": "Tudo à esquerda pode mudar o que o job roda, e o job segura tudo à direita enquanto roda."}
```

### Incidentes que passaram pelo pipeline

A aula 12 colocou incidentes reais na cadeia de suprimentos. Dois deles passaram exatamente por esta
porta, e vale relê-los do ponto de vista do pipeline.

- **Codecov, 2021.** O uploader em Bash que milhares de pipelines baixavam e rodavam a cada job foi
  alterado na origem para mandar as variáveis de ambiente do job para outro lugar. Todo pipeline que o
  rodou entregou as credenciais que os jobs guardavam. Nada mudou nesses repositórios.
- **tj-actions/changed-files, 2025.** Uma GitHub Action muito usada teve as tags de versão movidas
  para um commit que imprimia os segredos do runner no log do job. Todo workflow que nomeava a action
  por tag rodou o commit novo na execução seguinte; os que a nomeavam por commit, não.

Nenhum dos dois incidentes precisou de uma falha no código das vítimas. **Os dois dependeram do que um
job confiava sem conferir**: um script buscado na hora da execução, e uma tag que outra pessoa podia
mover.

### O que esta aula faz a respeito

Quatro controles, cada um de poucas linhas, e cada um mostrado no linkbox:

1. **Privilégio mínimo para o token do job**: declarar as permissões de que o job precisa, e nada
   mais.
2. **Entrada não confiável continua sendo dado**: o que o autor de um pull request escreveu chega a um
   shell por uma variável de ambiente, nunca colado no script.
3. **Código de terceiros por commit**: toda action fixada num hash completo de commit, com a versão num
   comentário para quem lê.
4. **O runner faz parte da confiança**: uma máquina nova por job sempre que possível, e um relato claro
   do que a própria máquina deixa um job fazer.

Os três primeiros são propriedades de um arquivo de workflow, e por isso a próxima seção escreve o
pipeline do linkbox para o GitHub Actions e deixa um scanner lê-lo. O quarto é sobre máquinas, e a
própria CI deste curso é o exemplo. **Os runners hospedados do GitHub não são usados em lugar nenhum
desta aula**: a máquina de gravação não consegue rodá-los, então todo workflow aqui é lido e auditado,
nunca executado, e o que o GitHub faz com um vem da documentação do GitHub.
