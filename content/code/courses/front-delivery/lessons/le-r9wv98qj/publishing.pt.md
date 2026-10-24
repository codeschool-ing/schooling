---
title: Publicando a primeira versão
version: 1
---

**O `npm publish` envia o arquivo que o `npm pack` mostrou para o registry para onde o escopo do pacote
aponta.** Qual registry é esse mora no `.npmrc` de um projeto, uma linha, commitada com o código porque é
um endereço e não um segredo:

```
ana@dev:~/planner-ui$ echo '@planner:registry=http://127.0.0.1:4873/' > .npmrc
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"O npm install no planner lê o .npmrc do projeto. Um pacote do escopo @planner é buscado no registry privado em 127.0.0.1:4873, que exige o token de login guardado em ~/.npmrc. Todo outro pacote, como o vite, é buscado no registry público em registry.npmjs.org.\"><rect x=\"20\" y=\"70\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">npm install</text><text x=\"105\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no planner</text><rect x=\"220\" y=\"30\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"232\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@planner/*</text><text x=\"440\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">127.0.0.1:4873</text><rect x=\"220\" y=\"136\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todo o resto</text><text x=\"440\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">registry.npmjs.org</text><line x1=\"190\" y1=\"95\" x2=\"218\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"218.0,60.0 215.8,67.7 211.0,63.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"190\" y1=\"115\" x2=\"218\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"218.0,150.0 211.0,146.2 215.8,142.3\" fill=\"var(--paper-dim)\"></polygon><text x=\"470\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do .npmrc do projeto</text><text x=\"470\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">exige o token em ~/.npmrc</text><text x=\"470\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">público, sem token</text></svg>", "caption": "Uma linha no .npmrc do projeto manda um escopo para um registry privado; o token que o abre fica na pasta pessoal."}
```

A linha diz: tudo o que se chama `@planner/…` mora neste endereço. Todo outro pacote continua vindo do
registry público. **É isso que impede um pacote interno de ser publicado no npm público por engano**, e que
impede o `npm install` de perguntar ao registry público por um nome que ele nunca deveria procurar lá, uma
confusão que atacantes já usaram contra empresas cujos nomes internos vazaram.

Construa, e publique:

```
ana@dev:~/planner-ui$ npm run build > /dev/null
ana@dev:~/planner-ui$ npm publish 2>&1 | tail -1
+ @planner/ui@0.1.0
ana@dev:~/planner-ui$ npm view @planner/ui versions
0.1.0
ana@dev:~/planner-ui$ npm publish 2>&1 | grep -m1 'npm error'
npm error code E409
```

`+ @planner/ui@0.1.0` é o jeito do npm de dizer que a versão está agora no registry. O `npm view` pergunta
ao registry o que ele tem, que é a conferência de que a publicação foi para onde você queria.

## Uma versão publicada é definitiva

Rode o `npm publish` de novo e ele falha, como o último comando mostrou, com `E409`, o código HTTP para um conflito: a versão já existe. **Uma versão, uma vez publicada, nunca é
substituída**; o registry público proíbe reusar um número de versão mesmo depois de um unpublish. Essa regra
é o motivo de uma versão querer dizer alguma coisa: quem instalou `0.1.0` hoje recebe os mesmos arquivos de
quem instalar daqui a um ano. Um erro na `0.1.0` se conserta publicando a `0.1.1`.

Faça o commit do que a biblioteca tem até aqui:

```
ana@dev:~/planner-ui$ git add . && git commit -qm "The planner's UI library, 0.1.0"
```
