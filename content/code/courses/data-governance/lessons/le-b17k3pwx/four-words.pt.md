---
title: Quatro palavras que não são sinônimos
version: 1
---

As aulas 1 a 4 decidiram quem pode ler o dado e o protegeram no caminho. Esta aula muda o próprio
dado, para que menos dele seja perigoso de saída. Quatro técnicas fazem isso, e as palavras para
elas são usadas como sinônimos em reunião e querem dizer coisas diferentes na lei:

| técnica | o que faz | dá para recuperar o original? |
|---|---|---|
| **mascaramento** | esconde parte de um valor quando ele é mostrado: `***.874.168-**` | o valor está intacto por baixo; quem lê a tabela o lê |
| **tokenização** | troca um valor por um substituto, e guarda o mapeamento em outro lugar | sim, por quem controla o mapeamento |
| **pseudonimização** | troca quem alguém é por um código, para registros da mesma pessoa ainda se juntarem | sim, com informação guardada à parte |
| **anonimização** | muda o dado até ninguém nele poder ser destacado por meios razoáveis | não — essa é a definição |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l5-spectrum\" aria-label=\"Quatro técnicas numa linha, do valor original à esquerda até o dado em que ninguém pode ser achado à direita: mascaramento, tokenização, pseudonimização, anonimização. As três primeiras ainda são dado pessoal pela LGPD; só a quarta não é, e só enquanto se sustenta.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 70.0 L690.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-paper-dim)\"></path><text x=\"30.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o valor original</text><text x=\"690.0\" y=\"48.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ninguém pode ser achado</text><rect x=\"30.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mascaramento</text><text x=\"110.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">***.874.168-**</text><rect x=\"195.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tokenização</text><text x=\"275.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tok_bbc2f3fe…</text><rect x=\"360.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pseudonimização</text><text x=\"440.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">vault:v1:5Vv5…</text><rect x=\"525.0\" y=\"92.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">anonimização</text><text x=\"605.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">contagens, k ≥ 5</text><rect x=\"30.0\" y=\"170.0\" width=\"490.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"275.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dado pessoal: toda obrigação vale</text><rect x=\"525.0\" y=\"170.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">não é dado pessoal</text></svg>", "caption": "A lei traça a linha na ponta direita, não no meio."}
```

A diferença que importa é a última coluna, porque **a lei trata as duas pontas de forma
diferente.** A LGPD diz que dado anonimizado nem é dado pessoal (art. 12), com tudo o que decorre
disso: sem base legal, sem direitos do titular, sem limite de retenção. Dado mascarado, tokenizado
e pseudonimizado continua sendo dado pessoal, regido por inteiro. Um time que chama uma exportação
pseudonimizada de "anônima" não mudou o que a lei diz dela — só o que conta a si mesmo.

**Ofuscação** é a quinta palavra, e a mais fraca: tornar o dado mais difícil de ler sem segredo
nenhum, como o base64 ou um embaralhamento reversível fazem. Ela não protege de ninguém que olhe; a
aula 11 do curso `cryptography` trata de por que codificar não é cifrar. Esta aula a cita só para
dizer que ela não é uma das quatro.

## Para que serve cada técnica

A pergunta nunca é "qual é a melhor", e sim **quem precisa de quê do dado**:

- o suporte precisa reconhecer um cliente ao telefone, não copiar os documentos dele —
  **mascaramento**;
- desenvolvedores precisam de dados com a forma da produção, não das pessoas que estão nela — uma
  **cópia mascarada**;
- o site precisa achar um cliente pelo CPF sem o banco guardar CPFs — um **token**;
- analistas precisam contar e juntar os pedidos de um cliente, não saber quem ele é — um
  **pseudônimo**;
- um relatório para um regulador ou para o público precisa de números em que ninguém seja achado —
  **anonimização**, e um jeito de conferi-la.

As seções seguintes constroem cada uma sobre o dado da Ipê, e a última mede quão longe de anônimo
um dado de "aparência anônima" pode estar.
