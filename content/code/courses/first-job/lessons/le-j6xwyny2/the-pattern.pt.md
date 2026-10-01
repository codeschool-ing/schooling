---
title: Um padrão para a linha
version: 1
---

A maioria das boas linhas de projeto tem as mesmas três partes, e ajuda escrevê-las separadas primeiro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha de currículo em três partes. Fez: construí e implantei um registro de empréstimos para a sala de TI de uma escola. Para quê: para o banco recusar um segundo empréstimo do mesmo item. Prova: um teste que falha quando a regra é retirada, e um serviço que sobrevive a uma queda. Abaixo, em letra menor, as tecnologias: Python, SQLite, Podman, Caddy.\"><defs><marker id=\"bu04-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">fez</text><text x=\"130\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Construí e implantei um registro de empréstimos para a sala de TI</text><rect x=\"20\" y=\"70\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">para quê</text><text x=\"130\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">para o banco recusar um segundo empréstimo do mesmo item</text><rect x=\"20\" y=\"120\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">prova</text><text x=\"130\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um teste que falha se a regra sai; sobrevive a uma queda</text><text x=\"130\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Python · SQLite · Podman · Caddy</text></svg>", "caption": "O que foi feito, o que isso consegue, e como qualquer um confere. A tecnologia é a linha menor, porque é a que todo outro currículo também tem."}
```

1. **Fez**: um verbo no passado e a coisa, com para quem era. *Construí e implantei um registro de
   empréstimos para a sala de TI de uma escola.* *Documentei e reconstruí a rede de um pequeno escritório num
   laboratório.*
2. **Para quê**: o que é verdade agora e não era. *Para um segundo empréstimo ser recusado.* *Para um colega
   conseguir reconstruir só com o runbook.*
3. **Prova**: a evidência que qualquer um confere. *Um teste que falha quando a regra sai.* *Uma restauração
   que foi testada.* *Implantado num endereço.*

Depois junte numa ou duas linhas e corte toda palavra que não carrega uma das três.

O mesmo padrão vale para experiência fora de TI. *Atendi clientes numa loja de celulares* vira *Resolvia
cerca de trinta problemas de clientes por dia numa loja de celulares, a maioria no primeiro atendimento*,
**se isso for verdade**, que é a próxima seção.

Três verbos a evitar no começo de uma linha: *ajudei*, *participei* e *fui responsável por*. Eles escondem o
que você fez. Se fez parte de algo, diga qual parte.
