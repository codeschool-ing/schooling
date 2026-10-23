---
title: Antes de escrever um
version: 1
---

**Um plugin seu é código nativo que você passa a manter em duas plataformas**, por cada versão do
Capacitor e cada versão de Android e iOS depois dela. É um custo real, e na maioria das vezes dá para
evitá-lo. O planner precisa de uma coisa que os plugins oficiais não dão: durante uma sessão de estudo,
**a tela deve ficar ligada**, como um app de receitas ou de navegação a mantém ligada. Antes de escrever
isso, as perguntas vêm nesta ordem:

1. **A web já faz isso?** Muita coisa que um celular faz é uma API web hoje, e algumas funcionam na
   WebView sem plugin nenhum, a área de transferência por exemplo. Confira se a WebView a suporta, nos
   dois sistemas, e não só o seu navegador de desktop: uma WebView não é o navegador de que ela é feita,
   e uma API que um navegador tem pode faltar ou ser limitada na WebView. A Screen Wake Lock API é o
   exemplo que esta aula encontra: o Chromium a tem, o Safari a ganhou anos depois, e num app ela tem
   condições próprias.
2. **Existe um plugin oficial?** Os plugins do próprio Capacitor, `@capacitor/…`, são mantidos junto com
   o Capacitor e passam para cada versão maior nova com ele.
3. **Existe um da comunidade?** A organização Capacitor Community no GitHub mantém plugins sob
   `@capacitor-community/…`, e pessoas publicam muitos outros. Leia a data do último lançamento, os
   problemas abertos e as plataformas que ele diz suportar antes de instalar um: um plugin parado numa
   versão maior antiga do Capacitor segura o app inteiro com ele.
4. **Aí escreva um**, tão pequeno quanto o trabalho permite.

Para manter a tela ligada, a resposta à terceira pergunta é sim: existem plugins da comunidade. Esta aula
escreve um mesmo assim, porque é o menor caso real que existe, três métodos curtos, e porque todas as
partes de um plugin aparecem nele. **O motivo do seu próprio app para escrever um será outro**: um
aparelho que a empresa fabrica, um SDK nativo que um parceiro entrega, um recurso do sistema que ninguém
embrulhou.

## O que é um plugin, visto de fora

Do lado do planner, nada muda em relação à aula 4: um pacote npm com uma interface, importado e chamado.
Por dentro, são as três implementações dessa interface, e um nome que as liga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l05-plugin\" aria-label=\"Um plugin por dentro. O planner importa a interface KeepAwake de src/definitions.ts. O registerPlugin('KeepAwake') em src/index.ts a liga, por esse nome, a três implementações: src/web.ts para o navegador, que usa a Screen Wake Lock API; KeepAwakePlugin.kt para o Android, que liga a FLAG_KEEP_SCREEN_ON na janela; e KeepAwakePlugin.swift para o iOS, que liga o isIdleTimerDisabled. O Capacitor chama a da plataforma onde o app roda.\"><defs><marker id=\"l05-plugin-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"56.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o planner chama</text><text x=\"105.0\" y=\"69.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">KeepAwake.keepAwake()</text><rect x=\"220\" y=\"40\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"56.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">src/definitions.ts:</text><text x=\"300.0\" y=\"69.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a interface</text><rect x=\"410\" y=\"40\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"495.0\" y=\"56.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">registerPlugin(\"KeepAwake\")</text><text x=\"495.0\" y=\"69.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">em src/index.ts</text><path d=\"M190 63 L220 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><path d=\"M380 63 L410 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><rect x=\"60\" y=\"140\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web: src/web.ts</text><text x=\"150.0\" y=\"169.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Screen Wake Lock API</text><rect x=\"270\" y=\"140\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Android: Kotlin</text><text x=\"360.0\" y=\"169.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">FLAG_KEEP_SCREEN_ON</text><rect x=\"480\" y=\"140\" width=\"180\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">iOS: Swift</text><text x=\"570.0\" y=\"169.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">isIdleTimerDisabled</text><path d=\"M495 86 L150 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><path d=\"M495 86 L360 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><path d=\"M495 86 L570 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-plugin-ah-paper-dim)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">o mesmo nome, e os mesmos nomes de método, nos três lados</text></svg>", "caption": "O planner vê uma interface. Atrás dela estão três programas em três linguagens, e só o nome os liga.", "same": ["src/definitions.ts:", "KeepAwake.keepAwake()", "registerPlugin(\"KeepAwake\")", "Screen Wake Lock API", "FLAG_KEEP_SCREEN_ON", "isIdleTimerDisabled", "web: src/web.ts", "Android: Kotlin", "iOS: Swift"]}
```

**O nome é a ligação.** `registerPlugin("KeepAwake")` em TypeScript, `@CapacitorPlugin(name =
"KeepAwake")` em Kotlin e `jsName = "KeepAwake"` em Swift têm que ser o mesmo texto, e os nomes dos
métodos também, nos três lados. Nada confere isso antes de o app rodar: um método escrito diferente num
lado é um erro na primeira vez que é chamado, só naquela plataforma.
