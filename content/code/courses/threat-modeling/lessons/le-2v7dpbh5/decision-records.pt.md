---
title: Registros de decisão
version: 1
---

O formato para registrar decisões que equipes de software já usam é o **registro de decisão de
arquitetura (ADR)**: um arquivo curto por decisão, com o contexto, a decisão e as consequências,
guardado no repositório e nunca editado depois. Uma decisão nova que muda uma antiga é um registro
novo que diz qual ele substitui. O curso `architecture-modeling` (aula 5) ensina ADRs para decisões
de projeto; decisões de segurança cabem no mesmo formato com três acréscimos.

| um ADR tem | um registro de decisão de segurança acrescenta |
|---|---|
| um título e um id | a ameaça ou o risco que ele decide, pelo id |
| o contexto | a estimativa, e a decisão: mitigar, eliminar, transferir ou aceitar |
| a decisão | o dono, com nome |
| as consequências | uma data de revisão, e os gatilhos que a antecipam |

A Vereda mantém dois tipos, com dois prefixos para distinguir numa lista: **RA** para um aceite de
risco, **DR** para qualquer outra decisão. O prefixo é para quem lê a pasta; nada no programa que os
lê depende dele.

### Front matter para a máquina, prosa para as pessoas

Cada registro começa com algumas linhas de **front matter**, os campos de que um programa precisa,
entre duas linhas de `---`. O resto é prosa para quem ler em seguida:

```
---
id: RA-001
threat: T14
decision: accept
owner: daniel
decided: 2026-10-01
review by: 2027-04-01
---
```

O front matter torna o registro consultável: um programa consegue listar cada aceite, cada decisão do
daniel, cada revisão deste mês, sem ninguém manter uma lista separada em dia. A prosa é o que torna
a decisão compreensível daqui a um ano, para alguém que não estava na sala.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-two-readers\" aria-label=\"Um registro de decisão tem dois leitores. O front matter, as linhas entre os dois marcadores --- com id, threat, decision, owner, decided e review by, é lido por um programa, o acceptances.py, que lista o que está vencendo. A prosa, o risco, por que é aceito, o que está no lugar e quando vai ser revisto, é lida por uma pessoa um ano depois que não estava na sala.\"><defs><marker id=\"l12-two-readers-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-two-readers-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"240.0\" y=\"20.0\" width=\"240.0\" height=\"220.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RA-001-crafted-pdf.md</text><text x=\"256.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">---</text><text x=\"256.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">id: RA-001</text><text x=\"256.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">threat: T14</text><text x=\"256.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">decision: accept</text><text x=\"256.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">owner: daniel</text><text x=\"256.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">review by: 2027-04-01</text><text x=\"256.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">---</text><text x=\"256.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## O risco</text><text x=\"256.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## Por que é aceito</text><text x=\"256.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## O que está no lugar</text><text x=\"256.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## Quando é revisto</text><rect x=\"20.0\" y=\"60.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">acceptances.py</text><text x=\"105.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que vence, e quando</text><path d=\"M240.0 85.0 L190.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-readers-tm-ah-phosphor)\"></path><rect x=\"530.0\" y=\"160.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uma pessoa, um ano depois</text><text x=\"615.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que não estava na sala</text><path d=\"M480.0 185.0 L530.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-readers-tm-ah-paper-dim)\"></path></svg>", "caption": "A máquina lê as datas para ninguém precisar lembrá-las; a pessoa lê os motivos para ninguém precisar reconstruí-los."}
```

### Nunca editado, só substituído

Um registro de decisão descreve o que foi decidido numa data, com o que se sabia então. **Editá-lo
depois reescreve a história**: o registro deixa de dizer o que o daniel assinou. Então uma decisão
mudada é um registro novo, com uma linha dizendo *substitui RA-001*, e o antigo fica. O único campo
que pode mudar no lugar é uma situação, se a equipe mantiver uma, porque ela descreve o presente e não
a decisão.

O git torna isso barato de conferir: `git log` num arquivo de decisão mostra se ele foi editado depois
do primeiro commit, e por quem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l12-supersede\" aria-label=\"Uma decisão que muda é um registro novo. O registro antigo, digamos o RA-001 como o daniel assinou, fica exatamente como era. O registro novo diz, no front matter, que substitui o RA-001, e traz a decisão, o dono e a data de revisão novos. O único campo que uma equipe pode mudar no lugar é uma situação, porque ela descreve o presente.\"><defs><marker id=\"l12-supersede-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40.0\" y=\"50.0\" width=\"240.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RA-001</text><text x=\"160.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">como assinado, nunca editado</text><text x=\"160.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">situação: substituído</text><rect x=\"440.0\" y=\"50.0\" width=\"240.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o registro novo</text><text x=\"560.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">supersedes: RA-001</text><text x=\"560.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decisão, dono, data novos</text><path d=\"M440.0 95.0 L280.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-supersede-tm-ah-phosphor)\"></path><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o git log mostra que o arquivo antigo nunca foi tocado depois do commit</text></svg>", "caption": "A história continua verdadeira: qualquer um ainda lê o que foi decidido em outubro, e com o que se sabia então."}
```
