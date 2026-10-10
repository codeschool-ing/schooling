---
title: "Medindo o fluxo: lead time, vazão e o diagrama de fluxo cumulativo"
version: 1
---

**O Kanban mede como o trabalho anda, e não quanto as pessoas estão ocupadas.** Três números carregam quase
tudo, e quem testa os lê procurando algo que o resto do time muitas vezes não vê: quanto da vida de um cartão
passa esperando teste.

| medida | o que conta | Cine Aurora, março |
|---|---|---|
| **lead time** | do pedido até pronto: o que quem pediu vive | 15 dias úteis em média |
| **tempo de ciclo** | do começo do trabalho até pronto: o que o time controla | 9 dias úteis em média |
| **vazão** | cartões que chegam a pronto por semana | 3 |

O lead time é o que importa à Célia; ela não liga para quando o Rafael começou, só para quando ela pediu. O
tempo de ciclo é o que o time consegue mudar diretamente. A diferença entre os dois é o tempo em "a fazer",
esperando alguém começar.

## Para onde vão os dias

A Lia fez mais uma coisa com os cartões de março: para cada um, contou os dias que ele passou em cada coluna.

| coluna | média de dias |
|---|---|
| construindo | 2 |
| esperando teste | 5 |
| testando | 1 |
| esperando a entrega | 1 |

De nove dias de tempo de ciclo, **dois foram construindo e um testando**. O resto foi espera. A fração do tempo
em que um cartão está de fato sendo trabalhado se chama **eficiência de fluxo**, e aqui é 3 ÷ 9, um terço.
Times que a medem pela primeira vez muitas vezes acham bem menos da metade, e se surpreendem.

Para o teste, isso muda a conversa. "O teste é lento" era o que todo mundo achava em março. O teste levou um
dia. Os cinco dias antes dele eram fila, e uma fila é uma propriedade de como o trabalho está organizado, não de
quão rápido alguém trabalha.

## O diagrama de fluxo cumulativo

Um **diagrama de fluxo cumulativo** desenha, para cada dia, quantos cartões já chegaram a cada coluna,
empilhados em faixas. Cada faixa é uma coluna. Leia assim:

- **a espessura vertical** de uma faixa num dia é quantos cartões estão naquela coluna naquele dia;
- **a largura horizontal** de uma faixa, entre a linha em que os cartões entram e a linha em que saem, é mais
  ou menos quanto tempo um cartão fica ali;
- **uma faixa que fica cada vez mais grossa** é uma fila crescendo: os cartões entram mais rápido do que saem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" data-fig=\"l13-cfd\" aria-label=\"Um diagrama de fluxo cumulativo ao longo de vinte dias úteis. Cinco faixas empilhadas de baixo para cima: pronto, testando, esperando teste, construindo e a fazer. Pronto cresce sem parar. Testando, construindo e a fazer mantêm a espessura. A faixa esperando teste começa fina e incha até cerca de quatro cartões e meio no dia vinte.\"><path d=\"M60.0 220.0 L83.0 214.5 L106.0 209.1 L129.0 203.6 L152.0 198.2 L175.0 192.7 L198.0 187.3 L221.0 181.8 L244.0 176.4 L267.0 170.9 L290.0 165.5 L313.0 160.0 L336.0 154.5 L359.0 149.1 L382.0 143.6 L405.0 138.2 L428.0 132.7 L451.0 127.3 L474.0 121.8 L497.0 116.4 L520.0 110.9 L520.0 220.0 L497.0 220.0 L474.0 220.0 L451.0 220.0 L428.0 220.0 L405.0 220.0 L382.0 220.0 L359.0 220.0 L336.0 220.0 L313.0 220.0 L290.0 220.0 L267.0 220.0 L244.0 220.0 L221.0 220.0 L198.0 220.0 L175.0 220.0 L152.0 220.0 L129.0 220.0 L106.0 220.0 L83.0 220.0 L60.0 220.0 Z\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\"0.55\"></path><path d=\"M60.0 210.9 L83.0 205.5 L106.0 200.0 L129.0 194.5 L152.0 189.1 L175.0 183.6 L198.0 178.2 L221.0 172.7 L244.0 167.3 L267.0 161.8 L290.0 156.4 L313.0 150.9 L336.0 145.5 L359.0 140.0 L382.0 134.5 L405.0 129.1 L428.0 123.6 L451.0 118.2 L474.0 112.7 L497.0 107.3 L520.0 101.8 L520.0 110.9 L497.0 116.4 L474.0 121.8 L451.0 127.3 L428.0 132.7 L405.0 138.2 L382.0 143.6 L359.0 149.1 L336.0 154.5 L313.0 160.0 L290.0 165.5 L267.0 170.9 L244.0 176.4 L221.0 181.8 L198.0 187.3 L175.0 192.7 L152.0 198.2 L129.0 203.6 L106.0 209.1 L83.0 214.5 L60.0 220.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor)\" fill-opacity=\"0.55\"></path><path d=\"M60.0 206.4 L83.0 199.1 L106.0 191.8 L129.0 184.5 L152.0 177.3 L175.0 170.0 L198.0 162.7 L221.0 155.5 L244.0 148.2 L267.0 140.9 L290.0 133.6 L313.0 126.4 L336.0 119.1 L359.0 111.8 L382.0 104.5 L405.0 97.3 L428.0 90.0 L451.0 82.7 L474.0 75.5 L497.0 68.2 L520.0 60.9 L520.0 101.8 L497.0 107.3 L474.0 112.7 L451.0 118.2 L428.0 123.6 L405.0 129.1 L382.0 134.5 L359.0 140.0 L336.0 145.5 L313.0 150.9 L290.0 156.4 L267.0 161.8 L244.0 167.3 L221.0 172.7 L198.0 178.2 L175.0 183.6 L152.0 189.1 L129.0 194.5 L106.0 200.0 L83.0 205.5 L60.0 210.9 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\" fill-opacity=\"0.8\"></path><path d=\"M60.0 197.3 L83.0 190.0 L106.0 182.7 L129.0 175.5 L152.0 168.2 L175.0 160.9 L198.0 153.6 L221.0 146.4 L244.0 139.1 L267.0 131.8 L290.0 124.5 L313.0 117.3 L336.0 110.0 L359.0 102.7 L382.0 95.5 L405.0 88.2 L428.0 80.9 L451.0 73.6 L474.0 66.4 L497.0 59.1 L520.0 51.8 L520.0 60.9 L497.0 68.2 L474.0 75.5 L451.0 82.7 L428.0 90.0 L405.0 97.3 L382.0 104.5 L359.0 111.8 L336.0 119.1 L313.0 126.4 L290.0 133.6 L267.0 140.9 L244.0 148.2 L221.0 155.5 L198.0 162.7 L175.0 170.0 L152.0 177.3 L129.0 184.5 L106.0 191.8 L83.0 199.1 L60.0 206.4 Z\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"var(--wire)\" fill-opacity=\"0.55\"></path><path d=\"M60.0 174.5 L83.0 167.3 L106.0 160.0 L129.0 152.7 L152.0 145.5 L175.0 138.2 L198.0 130.9 L221.0 123.6 L244.0 116.4 L267.0 109.1 L290.0 101.8 L313.0 94.5 L336.0 87.3 L359.0 80.0 L382.0 72.7 L405.0 65.5 L428.0 58.2 L451.0 50.9 L474.0 43.6 L497.0 36.4 L520.0 29.1 L520.0 51.8 L497.0 59.1 L474.0 66.4 L451.0 73.6 L428.0 80.9 L405.0 88.2 L382.0 95.5 L359.0 102.7 L336.0 110.0 L313.0 117.3 L290.0 124.5 L267.0 131.8 L244.0 139.1 L221.0 146.4 L198.0 153.6 L175.0 160.9 L152.0 168.2 L129.0 175.5 L106.0 182.7 L83.0 190.0 L60.0 197.3 Z\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"var(--scan)\" fill-opacity=\"0.55\"></path><text x=\"52.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"52.0\" y=\"174.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"52.0\" y=\"129.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"52.0\" y=\"83.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"52.0\" y=\"38.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 220.0 L520.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 220.0 L60.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M175.0 220.0 L175.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"175.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M290.0 220.0 L290.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"290.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M405.0 220.0 L405.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"405.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M520.0 220.0 L520.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"290.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dia útil</text><path d=\"M60.0 20.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"12.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cartões</text><text x=\"530.0\" y=\"165.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pronto</text><text x=\"530.0\" y=\"106.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">testando</text><text x=\"530.0\" y=\"81.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">esperando teste</text><text x=\"530.0\" y=\"56.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">construindo</text><text x=\"530.0\" y=\"39.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a fazer</text></svg>", "caption": "Março no Cine Aurora. Uma faixa inchando enquanto as vizinhas continuam finas é uma fila crescendo, e ela aparece antes de alguém reclamar."}
```

O diagrama de março mostrava uma faixa inchando, "esperando teste", enquanto as faixas dos dois lados
continuavam finas. Foi essa imagem que fez o time adotar limites, porque mostrou a fila crescendo antes de
alguém reclamar. Quem testa e sabe ler esse diagrama consegue mostrar a um time o gargalo dele numa imagem, em
vez de discutir.

## Uma medida é uma pergunta, não uma meta

Nenhum desses números diz se o trabalho ficou bom. Um time mandado cortar o lead time consegue isso movendo
cartões para "pronto" antes de testá-los, e o diagrama vai ficar lindo. A aula 22 é exatamente sobre essa falha.
Por ora: medidas de fluxo dizem onde o trabalho espera, e responder *por quê* continua sendo trabalho de alguém.
