---
title: A RFC interna
version: 1
---

**Uma RFC é uma proposta com um processo em volta: qualquer pessoa afetada pode comentar, por um
prazo fixo, e depois alguém nomeado decide e o resultado fica registrado.** O documento parece uma
proposta técnica. O que faz dele uma RFC é o processo, e é o processo que permite fazer uma mudança
que afeta todo mundo sem uma reunião com todo mundo.

O nome vem dos próprios padrões da internet. Em abril de 1969, Steve Crocker, um estudante de
pós-graduação que trabalhava na ARPANET, fez circular a primeira de uma série de notas e a chamou de
*Request for Comments* (pedido de comentários), porque um nome mais oficial parecia presunçoso para
estudantes. A série já passa de nove mil documentos e ainda leva o nome. As empresas o tomaram
emprestado pelo mesmo motivo: ele convida à discordância antes da decisão, e não depois.

## Quando a Marola usa uma

Uma RFC compensa o trabalho extra quando a mudança **cria uma regra que outros times precisam
seguir** ou **muda algo de que eles dependem**. Depois do incidente da sexta, a proposta de Lívia de
dar a cada serviço uma cota fixa de conexões do banco foi uma RFC, e não uma proposta, porque
restringia os sete times, e cada um deles sabia coisas sobre o próprio tráfego que ela não sabia.

## A vida de uma RFC

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro passos da esquerda para a direita: rascunho, com quem decide nomeado; aberta, com data de fechamento; revisão, com todo comentário respondido; decisão, por um dono, por escrito. A decisão leva a aceita ou rejeitada, e uma RFC aceita pode depois ser substituída. Os dois desfechos ficam onde as pessoas encontram, porque uma RFC rejeitada responde por que não.\"><defs><marker id=\"lifecycle-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">rascunho</text><text x=\"90.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem decide, nomeado</text><path d=\"M168 60 L188 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"190\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"266.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aberta</text><text x=\"266.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">data de fechamento</text><path d=\"M344 60 L364 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"366\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"442.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">revisão</text><text x=\"442.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo comentário respondido</text><path d=\"M520 60 L540 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"542\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decisão</text><text x=\"618.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um dono, por escrito</text><rect x=\"452\" y=\"150\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">aceita</text><rect x=\"592\" y=\"150\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"652\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rejeitada</text><path d=\"M592 92 L512 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><path d=\"M642 92 L652 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"452\" y=\"210\" width=\"120\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"512\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">substituída, depois</text><path d=\"M512 192 L512 208\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#lifecycle-ah)\"></path><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os dois desfechos ficam onde as pessoas encontram:</text><text x=\"20\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma RFC rejeitada responde \"por que não…?\"</text></svg>", "caption": "O que faz de uma proposta uma RFC é este processo: um prazo fixo para qualquer afetado, depois um decisor nomeado, depois um registro que fica."}
```

1. **Rascunho.** O autor escreve, em geral com uma ou duas das pessoas mais afetadas, e diz quem
   decide.
2. **Aberta para comentários, com data de encerramento.** Anunciada onde todos os times afetados vão
   ver. Duas semanas é um prazo comum dentro de uma empresa; o projeto Rust, que passa as mudanças
   da linguagem por RFCs públicas, encerra cada uma com um *final comment period* (período final de
   comentários) de dez dias, depois que o time que decide sinaliza que está pronto.
3. **Revisão.** O autor responde a cada comentário: mudou o design, explicou por que não ou
   registrou como questão em aberto. Todo comentário recebe uma das três.
4. **Decisão.** Quem foi nomeado para decidir aceita ou rejeita, por escrito, com os motivos. **Nem
   votação nem unanimidade**: os comentários informam a decisão, e uma pessoa ou um grupo é dono
   dela.
5. **Registro.** A RFC guarda o status final (*aceita*, *rejeitada* e, mais tarde, *substituída*
   por uma mais nova) e fica onde as pessoas conseguem encontrá-la.

## RFCs rejeitadas valem a pena guardar

Uma RFC rejeitada é a documentação mais barata que uma empresa tem. **Ela responde "por que a gente
não simplesmente…?" antes que alguém gaste uma semana descobrindo.** A lista da Marola tem uma RFC
de dois anos atrás que propunha dividir o banco de pedidos por região; ela foi rejeitada porque dois
terços dos pedidos cruzam uma fronteira regional. Todo ano alguém novo tem a mesma ideia, encontra a
RFC e lê o motivo em dez minutos.

## Da RFC ao registro de decisão

Uma RFC aceita é longa, e quase tudo nela é argumentação. O que a próxima engenheira precisa é da
decisão. Muitos times mantêm para isso um **registro de decisão de arquitetura** (ADR) curto, o
formato que Michael Nygard descreveu em 2011: um título, o contexto, a decisão, as consequências e
um status, em uma página ou menos, numerado e guardado junto do código.

::: track software-architecture
A aula 5 de `architecture-role` defendeu por que decisões de tecnologia são postas por escrito. A
RFC é o documento que faz uma decisão dessas ser tomada com as pessoas que ela afeta, e o registro
é o que fica depois que ela foi tomada.
:::

::: track tech-lead
`tech-strategy`, o curso que vem depois deste na sua trilha, volta aos registros de decisão na aula
17, como a memória do time. A RFC é o documento que faz uma decisão ser tomada; o registro é o que
fica depois que ela foi tomada.
:::

::: track *
A RFC é o documento que faz uma decisão ser tomada com as pessoas que ela afeta; o registro é o que
fica depois que ela foi tomada.
:::
