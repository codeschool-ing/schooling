---
title: Uma versão nova
version: 1
---

**Um service worker é atualizado do jeito que foi instalado, e espera.** Esta é a parte dos service workers que
surpreende todo mundo uma vez, então vale percorrê-la antes de acontecer.

1. **O navegador confere.** A cada navegação para uma página no escopo dele, e pelo menos uma vez por dia, o
   navegador busca o `/sw.js` de novo, passando por cima do cache HTTP. Se um byte for diferente, é uma versão
   nova.
2. **A versão nova instala** ao lado da antiga, rodando o próprio `install`: com o `CACHE` mudado para
   `planner-v2`, abrindo esse cache e buscando a página offline para dentro dele.
3. **Ela espera.** A versão antiga ainda controla toda aba aberta do site, e a nova não assume enquanto qualquer
   uma delas estiver aberta. Um visitante que mantém uma aba aberta por uma semana roda o worker antigo por uma
   semana.
4. **Ela ativa** quando a última dessas abas fecha, e o `activate` dela apaga o `planner-v1`. A próxima página
   aberta é controlada pela versão nova.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas versões do worker ao longo do tempo. A versão 1 controla as abas abertas. A versão 2 é achada, instala, e espera enquanto houver alguma aba controlada pela versão 1 aberta. Quando a última fecha, a versão 2 ativa, apaga o cache da versão 1, e controla as páginas abertas depois.\"><text x=\"108\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão 1</text><rect x=\"120\" y=\"50\" width=\"380\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">controla as abas abertas</text><text x=\"108\" y=\"112\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão 2</text><rect x=\"240\" y=\"100\" width=\"80\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">install</text><rect x=\"320\" y=\"100\" width=\"300\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">esperando</text><rect x=\"620\" y=\"100\" width=\"90\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"665.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">activate</text><line x1=\"240\" y1=\"40\" x2=\"240\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"240\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o /sw.js mudou</text><line x1=\"620\" y1=\"40\" x2=\"620\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"620\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a última aba fecha</text><text x=\"665\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planner-v1 apagado</text></svg>", "caption": "Um worker novo espera as páginas do antigo irem embora."}
```

## Por que ela espera

**Duas versões nunca podem servir a mesma página ao mesmo tempo.** Uma página carregada pelo worker antigo espera
os arquivos que o worker antigo guarda; se o novo assumisse no meio, a próxima requisição dela poderia receber um
arquivo de outro build, que são os chunks com hash da aula 8 misturados entre deploys. Esperar é o padrão seguro.

O `self.skipWaiting()` no `install` pula a espera, e o `clients.claim()` no `activate` assume as páginas abertas
na hora. Os dois são certos para um worker cujos caches não podem discordar das páginas já abertas, e arriscados
para um que pode; um meio-termo comum é a página mostrar *há uma versão nova pronta*, e chamar `skipWaiting` no
worker quando a pessoa concordar, recarregando a página depois.

## O que isso quer dizer para o planner

**Mudar o worker quer dizer mudar o `CACHE`.** O arquivo precisa diferir em pelo menos um byte para ser visto
como novo, e um nome de cache novo é o que faz a versão nova começar limpa enquanto o `activate` limpa a antiga.
Mudar uma página ou um script não precisa de worker novo: as páginas são network first, e os scripts de um build
novo têm nomes novos.
