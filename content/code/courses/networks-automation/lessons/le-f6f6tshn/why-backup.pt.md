---
title: Para que serve um backup
version: 1
---

Um backup de configuração parece um seguro contra um roteador que morre, e isso é o de menos no
que ele faz. Um roteador morre raramente. **As perguntas que um backup responde toda semana são
sobre mudança**: o que está diferente no edge1 desde terça, quem acrescentou aquela rota, como
estava este roteador antes da janela de manutenção de ontem à noite. Uma cópia única não responde
a nenhuma delas. Um histórico responde.

Então o job desta aula faz três coisas, toda noite, para todo roteador: lê a configuração em
execução, guarda num repositório Git e faz commit só quando algo mudou. O histórico vira uma lista
de mudanças com datas, e um `git diff` entre quaisquer duas delas é uma pergunta respondida.

A aula 10 acrescentou uma segunda fonte: os dados e o template dizem o que a rede **deveria**
rodar. Com um backup que diz o que ela **de fato** roda, a diferença entre os dois é a deriva, e
achá-la é um script:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro scripts em volta de três lugares. À esquerda, os roteadores. O backup.py lê a configuração em execução deles toda noite para backups, um repositório Git no alto à direita, que guarda um commit por mudança. O render.py transforma os dados e o template em configs, embaixo à direita: o que a rede deveria ser. O compare.py lê backups e configs e diz o que falta e o que sobra. O restore.py pega uma configuração do histórico e a devolve a um roteador.\"><defs><marker id=\"lp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"170\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os roteadores</text><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">core1, edge1, edge2</text><text x=\"105.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que está rodando</text><rect x=\"470\" y=\"20\" width=\"230\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">backups/</text><text x=\"585.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Git: um commit por mudança</text><text x=\"585.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que rodava, e quando</text><rect x=\"470\" y=\"190\" width=\"230\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">configs/</text><text x=\"585.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">renderizado de data/ e frr.j2</text><text x=\"585.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que deveria rodar</text><path d=\"M192 120 L466 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"300\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">backup.py</text><path d=\"M466 85 L192 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#lp-ah)\"></path><text x=\"360\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">restore.py</text><path d=\"M585 186 L585 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-ah)\"></path><text x=\"640\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">compare.py</text></svg>", "caption": "Um backup registra o que estava rodando; os dados dizem o que deveria. Comparar os dois é como se acha o drift.", "same": ["backups/", "configs/", "core1, edge1, edge2"]}
```

Duas coisas tornam um job de backup digno de confiança, e as duas estão nesta aula. **Ele tem que
dizer quando falhou**, porque um roteador que parou de responder deixa no repositório um arquivo
antigo que parece exatamente um novo. E **um backup é tão sensível quanto o roteador**:
configurações carregam senhas, chaves e o formato da rede, então a lista de acesso do repositório
é a lista de acesso dos roteadores, e a cópia num notebook conta.
