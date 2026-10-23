---
title: Métodos mais leves para uma tarde
version: 1
---

**A maioria das revisões não precisa de um ATAM completo, e uma revisão leve feita vale mais que uma
pesada adiada.** Dois métodos mais leves levam as ideias centrais do ATAM, cenários, riscos e
trade-offs, para algo que um time consegue fazer numa tarde.

## Risk storming

O **risk storming**, descrito por Simon Brown, é um jeito colaborativo de achar riscos nos diagramas
que o time já tem:

1. **Desenhe a arquitetura** no nível que importa, em geral o diagrama de containers da aula 3,
   grande, numa parede ou num quadro compartilhado.
2. **Cada um identifica riscos sozinho**, em silêncio, por dez minutos, cada risco num post-it com
   sua probabilidade e seu impacto, baixo, médio ou alto.
3. **Cada um cola seus post-its** na parte do diagrama de que o risco trata.
4. **O grupo olha onde os post-its se agrupam** e discute os agrupamentos, começando pelo maior
   produto de probabilidade e impacto.
5. **O grupo decide o que fazer** com os riscos do topo: mitigar, aceitar ou investigar mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l13-risk-storm\" aria-label=\"Um quadro de risk storming: os containers da Carcará desenhados grandes, com post-its colocados pelos revisores. As notas são coloridas por probabilidade vezes impacto. Uma nota fica na API de passagens, duas no banco de reservas, e um grupo de quatro no serviço de sincronização do embarque, todas dizendo dois celulares, uma passagem. Duas notas ficam na ligação entre uma rodoviária e a nuvem.\"><defs><marker id=\"l13-risk-storm-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"45.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Guichê</text><text x=\"110.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"280.0\" y=\"45.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">API de passagens</text><text x=\"360.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"530.0\" y=\"45.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><text x=\"610.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><rect x=\"280.0\" y=\"185.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Sincronização</text><text x=\"360.0\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"30.0\" y=\"185.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"203.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">App de embarque</text><text x=\"110.0\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">[Android]</text><path d=\"M190.0 70.0 L280.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><path d=\"M440.0 70.0 L530.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><path d=\"M190.0 210.0 L280.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><path d=\"M360.0 185.0 L360.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-storm-am-fill-paper-dim)\"></path><rect x=\"200.0\" y=\"16.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"233.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">link cai</text><rect x=\"200.0\" y=\"100.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"233.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">link cai</text><rect x=\"420.0\" y=\"112.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">pool</text><rect x=\"570.0\" y=\"112.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"603.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">failover?</text><rect x=\"640.0\" y=\"112.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"673.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">disco cheio</text><rect x=\"450.0\" y=\"170.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"483.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 celulares</text><rect x=\"520.0\" y=\"170.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 celulares</text><rect x=\"450.0\" y=\"248.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"483.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 celulares</text><rect x=\"520.0\" y=\"248.0\" width=\"66.0\" height=\"30.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"553.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--ink)\">2 celulares</text><text x=\"560.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">quatro notas, escritas sozinhas, num serviço</text></svg>", "caption": "O agrupamento é o achado. Quatro pessoas escreveram o mesmo risco sem conversar entre si, e é por isso que o passo em silêncio vem antes da discussão.", "same": ["[Android]", "[Container]", "[PostgreSQL]", "failover?"]}
```

O passo individual em silêncio é o importante. Ele impede que a voz mais sênior defina a pauta e
recolhe riscos que as pessoas não levantariam numa discussão aberta. Na Carcará, o agrupamento em
volta do serviço de sincronização do embarque surpreendeu os arquitetos: quatro pessoas, cada uma por
conta própria, tinham escrito que ninguém sabia o que acontecia quando dois celulares enviavam
leituras da mesma passagem.

## Uma revisão centrada em decisões

Um segundo método leve revisa **as decisões** em vez dos diagramas, e serve para times que mantêm o
log de decisões da aula 5:

1. Escolha os cinco a dez **registros que mais importam** para os cenários em jogo.
2. Para cada um, faça a **pergunta das forças**: as forças do contexto dele ainda são verdadeiras? A
   aula 5 pôs números e datas nos contextos exatamente para isso.
3. Faça a **pergunta das consequências**: as consequências que ele previu se confirmaram, as boas e
   as ruins?
4. Marque cada registro como **ainda sólido**, **a revisitar** ou **a substituir**.

A Carcará fez isso com o registro do bloqueio de assento, o ADR-0009: as forças ainda valiam, a queda
de CPU prevista tinha acontecido, e a consequência negativa prevista, bloqueios perdidos quando o
Redis reinicia, tinha acontecido duas vezes. Ainda sólido, com uma ação nova: os reinícios do Redis
passam para as horas calmas.

## Como escolher

| situação | método |
| --- | --- |
| um compromisso de alto risco, difícil de desfazer, com tempo | ATAM, ou uma versão encurtada dele |
| antes de um estresse conhecido, com um diagrama de containers | risk storming |
| um sistema maduro com log de decisões | revisão centrada em decisões |
| um documento de design novo | as três passadas da aula 11 de `architecture-role` |
