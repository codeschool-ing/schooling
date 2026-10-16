---
title: O pull request é o pedido de mudança
version: 1
---

**Num arranjo GitOps o pull request é o pedido de mudança.** Ele diz o que muda, quem quer, por quê e
quem concordou. Não há um chamado separado para manter em dia com o código, porque o diff é a
própria mudança. Esta seção abre um e vê a regra da seção anterior pará-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"O caminho de uma mudança de um branch até o cluster: um branch, um pull request, a checagem validate e uma revisão em paralelo, o merge na main e o reconciliador aplicando a main.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"250\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"100\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"75.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">branch</text><text x=\"75.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">banner-v2</text><rect x=\"160\" y=\"100\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"220.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pull request</text><text x=\"220.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">#1</text><rect x=\"320\" y=\"40\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"380.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">checagem</text><text x=\"380.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">validate</text><rect x=\"320\" y=\"160\" width=\"120\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"380.0\" y=\"180.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">revisão</text><text x=\"380.0\" y=\"198.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Bruno</text><rect x=\"470\" y=\"100\" width=\"100\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"520.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">merge</text><text x=\"520.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">main</text><rect x=\"600\" y=\"100\" width=\"100\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"650.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><text x=\"650.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">reconciliador</text><line x1=\"130\" y1=\"125\" x2=\"148.0\" y2=\"125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"156,125 148.0,120.5 148.0,129.5\" fill=\"var(--paper-dim)\"/><line x1=\"280\" y1=\"115\" x2=\"311.0\" y2=\"76.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"316,70 307.5,73.4 314.5,79.1\" fill=\"var(--paper-dim)\"/><line x1=\"280\" y1=\"135\" x2=\"311.0\" y2=\"173.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"316,180 314.5,170.9 307.5,176.6\" fill=\"var(--paper-dim)\"/><line x1=\"440\" y1=\"65\" x2=\"462.1\" y2=\"105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"466,112 466.1,102.8 458.2,107.2\" fill=\"var(--paper-dim)\"/><line x1=\"440\" y1=\"185\" x2=\"462.1\" y2=\"145.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"466,138 458.2,142.8 466.1,147.2\" fill=\"var(--paper-dim)\"/><line x1=\"570\" y1=\"125\" x2=\"588.0\" y2=\"125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"596,125 588.0,120.5 588.0,129.5\" fill=\"var(--phosphor)\"/><text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">a regra espera as duas</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">Ninguém faz push na main: toda mudança passa por aqui</text></svg>", "caption": "O caminho que toda mudança faz nesta aula. A regra de proteção da main segura o merge até a checagem ficar verde e alguém que não é o autor aprovar.", "same": ["branch", "pull request", "merge", "cluster", "Bruno", "banner-v2", "validate", "main"]}
```

## Abrindo

O branch vai para o servidor, e o pull request pede que ele entre na `main`:

```
ana@laptop:~/fleet$ git push --quiet -u origin banner-v2
remote: 
remote: Create a new pull request for 'banner-v2':        
remote:   http://localhost:3000/ana/fleet/pulls/new/banner-v2        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "banner-v2", "base": "main", "title": "staging: ready for review", "body": "QA starts on staging on Monday, and the banner tells them it is ready."}' $API/pulls | jq '{number, title, state, mergeable}'
{
  "number": 1,
  "title": "staging: ready for review",
  "state": "open",
  "mergeable": true
}
```

O corpo não é enfeite. **Ele é o registro do porquê**, a parte que um `git log` daqui a um ano não
explica sozinho, e a aula 12 volta a lê-lo.

## A regra em ação

A Ana está com pressa e tenta fazer o merge da própria mudança:

```
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/1/merge
{"message":"Does not have enough approvals","url":"http://localhost:3000/api/swagger"} 405
```

`Does not have enough approvals`. Ser administradora não ajuda, porque a regra disse ninguém. Ela
tenta o atalho óbvio e aprova sozinha:

```
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"event": "APPROVED", "body": "Looks fine to me."}' $API/pulls/1/reviews
{"message":"approve your own pull is not allowed","url":"http://localhost:3000/api/swagger"} 422
```

O Gitea também recusa: **uma aprovação só conta se vier de alguém que não é o autor**. A mudança
espera pelo Bruno, que é todo o sentido da regra, e a próxima seção é o que o Bruno faz com ela.
