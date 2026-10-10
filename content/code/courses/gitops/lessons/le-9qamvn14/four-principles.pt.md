---
title: Os quatro princípios
version: 1
---

**"GitOps" foi cunhado em 2017 e passou anos querendo dizer o que cada fornecedor precisava que
dissesse.** Em 2021 um grupo de trabalho da CNCF, o OpenGitOps, escreveu quatro princípios com que
as ferramentas e as empresas por trás delas concordaram. São curtos, e cada um proíbe alguma coisa.

**1. Declarativo.** O estado desejado do sistema é expresso de forma declarativa. Um manifesto do
Kubernetes diz *duas réplicas desta imagem, atrás desta porta*, e não *rode estes comandos*. A
diferença importa porque uma descrição pode ser comparada com a realidade, e um script só pode ser
executado. Um script que parou no meio não deixa registro do que pretendia alcançar.

**2. Versionado e imutável.** O estado desejado é guardado de um jeito que preserva todas as
versões, e uma versão, depois de escrita, não muda. O Git faz as duas coisas: um commit tem um hash
calculado do conteúdo e dos pais dele, então o commit `ab88607` quer dizer exatamente uma árvore de
arquivos, para sempre. "Voltar atrás" vira "apontar para uma versão anterior", e "o que mudou na
terça" tem uma resposta exata.

**3. Puxado automaticamente.** Agentes de software puxam o estado desejado da fonte. Ninguém roda um
comando de deploy, e nada fora do cluster precisa de credenciais para entrar nele. A seção anterior
argumentou por quê.

**4. Reconciliado continuamente.** Agentes observam o estado real o tempo todo e tentam aplicar o
estado desejado. Não uma vez por deploy: sempre. O laço nunca termina, porque o trabalho não é
fazer uma mudança, e sim manter uma diferença em zero.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"O laço de reconciliação: observar o estado real, comparar com o estado desejado vindo do Git, agir sobre a diferença e esperar, sem parar.\"><rect x=\"0\" y=\"0\" width=\"640\" height=\"300\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"118\" width=\"130\" height=\"64\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"85\" y=\"145\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">estado desejado</text><text x=\"85\" y=\"165\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">no Git</text><rect x=\"490\" y=\"118\" width=\"130\" height=\"64\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"555\" y=\"145\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">estado real</text><text x=\"555\" y=\"165\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">no cluster</text><circle cx=\"320\" cy=\"150\" r=\"95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 5\"/><rect x=\"265\" y=\"40\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"320\" y=\"62\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">observar</text><rect x=\"355\" y=\"133\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"410\" y=\"155\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">comparar</text><rect x=\"265\" y=\"226\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"320\" y=\"248\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">agir</text><rect x=\"175\" y=\"133\" width=\"110\" height=\"34\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"230\" y=\"155\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">esperar</text><line x1=\"150\" y1=\"150\" x2=\"171\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"/><line x1=\"469\" y1=\"150\" x2=\"486\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"/><text x=\"320\" y=\"290\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">nunca termina: o trabalho é manter a diferença em zero</text></svg>", "caption": "O laço de reconciliação. Todo agente de GitOps é esse laço, rodando num intervalo, a cada mudança no Git ou a cada mudança no cluster."}
```

## O que cada princípio proíbe

| princípio | o que ele proíbe |
|---|---|
| declarativo | um deploy que é uma sequência de comandos que ninguém consegue comparar com o cluster |
| versionado e imutável | um "latest" que amanhã quer dizer outra coisa, e um histórico que pode ser reescrito |
| puxado automaticamente | um pipeline fora do cluster com as chaves dele |
| reconciliado continuamente | uma mudança que dura até alguém notar, feita à mão e nunca escrita |

**O Git não está nos princípios**, e isso surpreende. A palavra é "versionado", e um registry OCI com
manifestos, ou um bucket S3 com versionamento, também atendem; o Flux lê estado desejado dos dois,
e a aula 7 usa o primeiro. O Git venceu porque as pessoas já revisam mudanças nele, e a revisão é
onde a aula 2 começa.

**O Kubernetes também não está neles.** Os princípios descrevem qualquer sistema com uma API que
aceita um estado declarado e um agente para conduzi-lo. O Kubernetes é onde as ferramentas
cresceram, porque os controladores dele já funcionam assim: um Deployment é ele próprio um laço de
reconciliação, comparando réplicas desejadas com réplicas rodando. O GitOps estende o mesmo laço um
passo para fora, do banco de dados do próprio cluster até um repositório.
