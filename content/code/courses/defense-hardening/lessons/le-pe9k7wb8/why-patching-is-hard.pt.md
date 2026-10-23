---
title: Por que corrigir é difícil
version: 1
---

**Instalar uma atualização leva um minuto. Aplicar patches é tudo em volta desse minuto.** A imagem
comum é que aplicar patches é uma tarefa técnica que alguém vive adiando. Na prática, o minuto é a
parte fácil; o que toma tempo é decidir quando a atualização pode entrar, descobrir se ela quebra
alguma coisa, colocá-la nas máquinas numa ordem que limite o estrago se quebrar, e lidar com as
máquinas em que ela ainda não pode entrar.

Dois deveres puxam um contra o outro. A aula 16 dá a cada achado uma data limite, porque uma falha sem
correção é um risco que cresce a cada dia. Os clientes do escritório esperam que o portal responda,
porque um patch que o derruba é uma indisponibilidade causada pelo próprio escritório. **Um processo
de patches é o arranjo que deixa as duas coisas serem verdade**: as atualizações entram rápido e,
quando uma é ruim, poucas máquinas a recebem e ela sai de novo depressa.

## A janela

Uma **janela de manutenção** é um horário combinado antes em que mudanças podem causar interrupções:
terça à noite para o portal, digamos, quando os clientes da Jatobá não estão enviando nada. Uma janela
torna os patches previsíveis para quem depende do serviço e dá a quem aplica um horário sobre o qual
ninguém discute. Ela também cria a tensão que as próximas seções resolvem: uma falha na lista de
exploradas não pode esperar seis dias pela terça, então o processo precisa de uma regra para quando a
janela é ignorada, e essa regra é o P1 da aula 16.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l17-timeline\" aria-label=\"Uma linha do tempo de uma atualização em trinta dias. Dia 0, a correção é publicada e entra no repositório do escritório. Dia 1, o anel um, as primeiras poucas máquinas, recebe. Dia 8, depois de uma semana sem problema, o anel dois, todo o resto, recebe na janela de manutenção de terça. O dia 30 é a data limite da política de vulnerabilidades, com folga. Uma linha tracejada marca o caminho mais rápido para uma falha sendo explorada: os dois anéis dentro dos sete dias de um P1.\"><defs><marker id=\"l17-timeline-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M60.0 120.0 L680.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M60.0 116.0 L60.0 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 0</text><path d=\"M204.7 116.0 L204.7 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"204.7\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 7</text><path d=\"M349.3 116.0 L349.3 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"349.3\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 14</text><path d=\"M494.0 116.0 L494.0 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"494.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 21</text><path d=\"M680.0 116.0 L680.0 124.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia 30</text><circle cx=\"60.0\" cy=\"120.0\" r=\"5\" fill=\"var(--paper)\"></circle><path d=\"M60.0 114.0 L60.0 50.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"66.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">correção publicada,</text><text x=\"66.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no repositório</text><circle cx=\"80.7\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M80.7 114.0 L80.7 98.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"86.7\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">anel um</text><text x=\"86.7\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">poucas máquinas</text><circle cx=\"225.3\" cy=\"120.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M225.3 114.0 L225.3 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"231.3\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">anel dois, terça</text><text x=\"231.3\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">janela, todo o resto</text><circle cx=\"680.0\" cy=\"120.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M680.0 114.0 L680.0 74.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"674.0\" y=\"54.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">data limite</text><text x=\"674.0\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">política P2</text><path d=\"M60.0 175 L204.7 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l17-timeline-dh-ah-amber)\"></path><text x=\"212.7\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falha explorada (P1): os dois anéis dentro de sete dias</text></svg>", "caption": "Os anéis cabem dentro do prazo. Para uma falha explorada, encolhem para horas, não para nada."}
```

## O que esta aula monta

A maior parte do que um escritório corrige vem da distribuição, e este laboratório não alcança o
repositório do Ubuntu. Então a aula corrige um software que o próprio escritório faz: um pacote
pequeno, `jatoba-health`, que confere se o portal responde. Ele é montado no `admin` em duas versões,
servido a partir de um repositório próprio do escritório e distribuído para o `desk` e o `web` em dois
anéis, segurado numa máquina e revertido em outra. **A mecânica é a mesma para o nginx do Ubuntu e para
um pacote seu**, e é por isso que esta é uma substituição justa: o apt não sabe quem escreveu o que ele
instala.

Suba o laboratório desta aula:

```sh
sudo bash hostlab.sh up admin desk web
```
