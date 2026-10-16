---
title: Uma restauração que nunca para
version: 1
---

A lição 8 terminou onde as restaurações chegam ao fim da linha: quando a promessa é de minutos, nenhuma
restauração, por mais ensaiada que seja, cabe nela. O que cabe é um servidor que já está **restaurado**
e é mantido atualizado segundo a segundo, de modo que assumir o lugar do primário seja só questão de
mandá-lo parar de seguir. Esse servidor é um **standby**, e mantê-lo atualizado é a **replicação por
streaming**.

O mecanismo é o mesmo que este curso usa desde a lição 4, só que contínuo. Um standby é um base backup
que nunca termina de se recuperar: em vez de buscar segmentos arquivados e parar num alvo, ele se
conecta ao primário, recebe o write-ahead log **à medida que ele é escrito** e o reaplica, enquanto
estiver rodando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois servidores. No primário, um commit é escrito no pg_wal e um WAL sender manda o log novo na hora. No standby, um WAL receiver escreve e grava em disco no pg_wal do próprio standby, e o processo de startup reaplica nos arquivos de dados, onde as consultas no standby podem vê-lo. Os quatro passos estão numerados.\"><defs><marker id=\"l11s-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"l11s-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">primário</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 commit, escrito no pg_wal</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 WAL sender</text><path d=\"M150 100 L150 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11s-pa)\"></path><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby</text><rect x=\"460\" y=\"60\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 WAL receiver:</text><text x=\"570\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">write, depois flush</text><rect x=\"460\" y=\"130\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 replay nos dados</text><text x=\"570\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as consultas veem aqui</text><path d=\"M570 106 L570 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11s-pa)\"></path><path d=\"M282 150 L360 150 L360 83 L438 83\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11s-am)\"></path><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o log, à medida que é escrito</text></svg>", "caption": "Replicação por streaming em quatro passos. Cada um pode ficar atrás do anterior, e a visão que o primário tem do standby informa uma posição para cada um.", "same": ["2 WAL sender", "3 WAL receiver:", "standby"]}
```

Quatro passos para cada mudança, cada um deles um ponto em que o standby pode ficar para trás, e cada
um com sua própria coluna na view que as próximas seções leem:

1. O primário escreve a mudança no próprio log, e faz o commit.
2. Um processo **WAL sender** no primário manda o log novo para o standby assim que ele existe.
3. Um **WAL receiver** no standby **escreve** esse log no `pg_wal` do próprio standby e depois faz o
   **flush** dele para o disco.
4. O processo de startup do standby **reaplica** o log nos arquivos de dados, e só então uma consulta
   no standby consegue enxergar a mudança.

O standby é **somente leitura**: ele aplica a história do primário e não cria nenhuma própria. Ele pode
responder a consultas (no PostgreSQL isso se chama **hot standby**), e pode ser **promovido** a
primário em segundos, o que a lição 15 faz.

## O que um standby não é

Um standby é uma cópia do banco **como ele está agora**, não como ele estava. A lição 8 disse isso com
todas as letras: um `DELETE` com o `WHERE` errado chega ao standby uma fração de segundo depois do
primário, e aí os dois perderam as linhas. **Replicação protege contra perder um servidor; backups
protegem contra perder dados.** Uma configuração com um standby e sem backups tem a segunda metade
deste curso e não a primeira.
