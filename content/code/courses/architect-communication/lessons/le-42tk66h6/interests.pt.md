---
title: Posições e interesses
version: 1
---

**Uma posição é o que alguém diz que quer; um interesse é por que quer.** Duas posições podem ser
impossíveis de conciliar enquanto os interesses por trás delas se encaixam com facilidade, e achar
esse encaixe é a maior parte do trabalho de mediar. A distinção vem de *Getting to Yes* (no Brasil,
*Como chegar ao sim*), de Roger Fisher e William Ury, escrito a partir do Harvard Negotiation
Project em 1981, e vale tanto para uma discussão sobre conexões de banco quanto para um contrato.

## Debaixo das duas posições

A posição de Bruna era "cortar a logística para 20 conexões". A de Henrique era "a logística precisa
de 40". Ditas assim, uma das duas tem que perder. Na call, Lívia fez a mesma pergunta a cada um, e
era a pergunta da aula 6 num cenário novo: **"O que acontece se você não tiver esse número?"**

- **Bruna:** "Numa sexta à noite, se a logística estiver usando as 40 dela, o checkout pode ficar
  sem conexão. Preciso que o checkout nunca espere por uma conexão entre 18:00 e 21:00." O
  interesse dela é **o pico do checkout**.
- **Henrique:** "O planejador de rotas roda o lote grande às 05:00. Com 20 conexões ele termina
  depois das 06:00, e os motoristas ficam esperando no depósito sem rota." O interesse dele são
  **rotas prontas até as 06:00**.

Dois interesses, em duas horas diferentes do dia. Ninguém precisava de 40 conexões às 19:00 de uma
sexta, e ninguém precisava das conexões do checkout às 05:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um gráfico das conexões da logística ao banco ao longo de 24 horas. A cota fixa antiga é uma linha reta em 40 o dia todo. A nova cota por horário é 40 das 02:00 às 06:00, durante o lote de rotas, e 15 no resto do tempo, inclusive no pico do checkout, das 18:00 às 21:00.\"><defs><marker id=\"quotas-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 190 L680 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"60.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00:00</text><text x=\"215.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">06:00</text><text x=\"370.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:00</text><text x=\"525.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24:00</text><text x=\"52\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"52\" y=\"126.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"52\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><polygon points=\"525.0,30 602.5,30 602.5,190 525.0,190\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></polygon><text x=\"563.75\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pico do checkout</text><polygon points=\"111.66666666666666,30 215.0,30 215.0,190 111.66666666666666,190\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></polygon><text x=\"163.33333333333331\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">lote de rotas</text><path d=\"M60 62.0 L680 62.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></path><text x=\"266.66666666666663\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cota fixa: 40 o dia todo</text><path d=\"M60 142.0 L111.66666666666666 142.0 L111.66666666666666 62.0 L215.0 62.0 L215.0 142.0 L680 142.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"266.66666666666663\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cota por horário: 40 das 02:00 às 06:00, 15 no resto</text><text x=\"60\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conexões da logística ao banco de pedidos, por hora do dia</text></svg>", "caption": "As duas posições eram 20 e 40. Os dois interesses ficavam em horas diferentes, e por isso uma cota que muda com o relógio atendeu os dois."}
```

## Opções de ganho mútuo

Com os interesses na mesa, a opção que ninguém tinha proposto ficou óbvia: **uma cota que muda com
a hora do dia**. A logística fica com 40 conexões entre 02:00 e 06:00, quando o checkout está quase
parado, e cai para 15 entre 06:00 e 02:00. O checkout ganha folga no pico, a logística mantém a
janela do lote. O time de plataforma confirmou que conseguia programar a cota por horário em um dia.

Vale ter em mente os quatro princípios de Fisher e Ury em qualquer conversa desse tipo:

1. **Separe as pessoas do problema.** A discussão é sobre conexões, não sobre se o checkout "culpa
   todo mundo".
2. **Concentre-se nos interesses, não nas posições.** A pergunta acima.
3. **Invente opções de ganho mútuo** antes de decidir. A cota por horário foi a terceira de cinco
   opções escritas no quadro; as duas primeiras eram as posições.
4. **Insista em critérios objetivos.** A próxima seção.

## O conflito de relacionamento não desaparece

A frase de Paulo sobre culpa continuava na thread. Lívia não pediu a ninguém que se desculpasse em
público, o que teria reaberto o assunto. Depois da call, ela falou com Paulo a sós: "Aquela frase
sobre o checkout caiu mal. O que estava por trás dela?" Descobriu que a logística tinha sido culpada
no primeiro rascunho das notas do incidente de 6 de março, antes da reescrita sem culpados (a aula
15 trata de por que isso importa), e Paulo não tinha esquecido. **Um conflito de relacionamento
costuma ter uma história, e a história é contada em particular, não num canal.**
