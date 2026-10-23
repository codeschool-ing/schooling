---
title: Como funciona a chamada a um plugin
version: 1
---

**Um plugin do Capacitor é um pacote npm com três implementações de uma interface TypeScript**: uma em
Java ou Kotlin para o Android, uma em Swift para o iOS e uma em JavaScript para a web. O seu código
importa a interface e a chama; o Capacitor escolhe a implementação da plataforma onde o app está
rodando. Esta aula acrescenta cinco plugins oficiais ao planner, cada um para uma coisa que um
celular dá a um app e uma página não tem, ou tem só em parte.

| plugin | o que o planner faz com ele |
|---|---|
| `@capacitor/preferences` | guarda o plano, para um recarregamento não o perder mais |
| `@capacitor/filesystem` | escreve o plano num arquivo |
| `@capacitor/local-notifications` | lembra você na manhã de uma sessão |
| `@capacitor/geolocation` | diz onde você está estudando |
| `@capacitor/camera` | tira uma foto das suas anotações |

Eles se instalam como qualquer pacote, cada um fixado na versão que este curso usou, e o `npx cap
sync` põe as metades nativas deles nos dois projetos:

```
ana@dev:~/planner$ npm install -E @capacitor/preferences@8.0.1 @capacitor/filesystem@8.1.5 @capacitor/local-notifications@8.3.1 @capacitor/geolocation@8.2.4 @capacitor/camera@8.2.6

added 6 packages, and audited 126 packages in 813ms

3 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npx cap sync
✔ Copying web assets from dist to android/app/src/main/assets/public in 7.32ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 2.87ms
✔ copy android in 24.23ms
✔ Updating Android plugins in 2.04ms
[info] Found 5 Capacitor plugins for android:
       @capacitor/camera@8.2.6
       @capacitor/filesystem@8.1.5
       @capacitor/geolocation@8.2.4
       @capacitor/local-notifications@8.3.1
       @capacitor/preferences@8.0.1
✔ update android in 46.23ms
✔ Copying web assets from dist to ios/App/App/public in 6.59ms
✔ Creating capacitor.config.json in ios/App/App in 370.51μs
✔ copy ios in 23.03ms
✔ Updating iOS plugins in 1.71ms
[info] All Capacitor plugins have a Package.swift file and will be included in Package.swift
[info] Writing Package.swift
[info] Found 5 Capacitor plugins for ios:
       @capacitor/camera@8.2.6
       @capacitor/filesystem@8.1.5
       @capacitor/geolocation@8.2.4
       @capacitor/local-notifications@8.3.1
       @capacitor/preferences@8.0.1
✔ update ios in 20.40ms
✔ copy web in 5.40ms
✔ update web in 6.02ms
[info] Sync finished in 0.162s
```

Essa última parte é o `cap update` trabalhando: **os cinco plugins agora estão nos projetos Android e
iOS**, listados no `capacitor.plugins.json` e nos arquivos de pacote do Gradle e do Swift que são do
sync. Nada mais precisa ser feito para o lado nativo encontrá-los.

## Perguntando antes

Um celular pergunta à pessoa antes de um app poder usar a câmera, a localização ou as notificações, e
um navegador também. Todo plugin que precisa disso tem as mesmas duas chamadas, `checkPermissions()` e
`requestPermissions()`, e a resposta é uma de três palavras: **`granted`**, **`denied`** ou
**`prompt`**, que quer dizer que ninguém foi perguntado ainda. Alguns plugins perguntam sozinhos na
primeira vez que são chamados, como o de geolocalização.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l04-permission\" aria-label=\"O que acontece na primeira vez que o planner pede a localização. A chamada vai ao plugin, que confere a permissão. Se ela nunca foi pedida, o sistema mostra o diálogo dele, com a frase do Info.plist ou o texto do próprio sistema no Android. Um sim fica guardado e a posição volta; um não também fica guardado, e as chamadas seguintes falham na hora sem perguntar de novo, até a pessoa mudar isso nas configurações do sistema.\"><defs><marker id=\"l04-permission-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"88.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o seu código chama</text><text x=\"95.0\" y=\"101.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">getCurrentPosition()</text><rect x=\"200\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"88.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o plugin confere</text><text x=\"275.0\" y=\"101.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a permissão</text><rect x=\"380\" y=\"70\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"88.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nunca pedida:</text><text x=\"450.0\" y=\"101.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o sistema pergunta</text><rect x=\"550\" y=\"20\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"38.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">concedida: a posição</text><text x=\"625.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">volta</text><rect x=\"550\" y=\"120\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"138.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">negada: a chamada falha,</text><text x=\"625.0\" y=\"151.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e falha de novo depois</text><path d=\"M170 95 L200 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><path d=\"M350 95 L380 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><path d=\"M520 85 L550 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><path d=\"M520 105 L550 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-permission-ah-paper-dim)\"></path><text x=\"625\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">só as configurações do sistema desfazem um não</text></svg>", "caption": "O diálogo é do sistema, mostrado uma vez. O que o seu app controla é quando pergunta, e o que faz com um não.", "same": ["getCurrentPosition()"]}
```

**O diálogo é do sistema, e é mostrado uma vez.** Depois de um não, um pedido seguinte falha na hora
sem perguntar de novo, no Android depois do segundo não e no iOS depois do primeiro. Então o que se
projeta é quando o app pergunta, que deve ser no momento em que a pessoa entende o porquê, e o que ele
faz com uma recusa, que deve ser continuar funcionando sem aquele recurso.

## A implementação web, e o que ela não é

Na web, cada plugin chama a interface do próprio navegador: `localStorage`, a Notifications API,
`navigator.geolocation`, um seletor de arquivo. É por isso que o resto desta aula roda no Chromium com
o `look.mjs`, e cada transcrição é uma execução real. **É também onde esta aula deixa de ser evidência
do que um celular faz.** O Filesystem da web guarda os arquivos no IndexedDB do navegador, não numa
pasta; uma notificação web precisa da aba aberta; uma câmera web é um seletor de arquivo. As regras de
permissão, os limites de armazenamento e o comportamento em segundo plano num celular são do sistema,
e a aula 6 é sobre a distância entre os dois.
