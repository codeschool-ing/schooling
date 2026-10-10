---
title: Três formatos, e o que cada um mede de fato
version: 1
---

Todo processo de contratação de engenharia precisa responder a uma pergunta em algum ponto: essa pessoa
consegue escrever código e raciocinar sobre ele no nível que o cargo exige? **Três formatos dominam, e
cada um mede algo um pouco diferente dos outros, inclusive coisas que não são o trabalho.** Escolher
um é escolher o que você aceita medir sem querer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l16-formats\" aria-label=\"Três colunas, uma por formato, cada uma dividida entre o que mede bem e o que mais mede. Desafio em casa: bem, como a pessoa escreve código com tempo para pensar; também, quanto tempo livre ela tem. Pareamento: bem, como trabalha em código com outra pessoa; também, conforto em ser observada. Live coding: bem, produzir código rápido partindo do zero; também, desempenho sob pressão e prática nesse estilo de problema.\"><text x=\"130.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">desafio em casa</text><rect x=\"30.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mede bem</text><text x=\"130.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">código escrito com</text><text x=\"130.0\" y=\"108.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">tempo para pensar</text><rect x=\"30.0\" y=\"150.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">também mede</text><text x=\"130.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">quanto tempo livre</text><text x=\"130.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a pessoa tem</text><text x=\"360.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">pareamento</text><rect x=\"260.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mede bem</text><text x=\"360.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">trabalhar em código</text><text x=\"360.0\" y=\"108.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">com outra pessoa</text><rect x=\"260.0\" y=\"150.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">também mede</text><text x=\"360.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">conforto em</text><text x=\"360.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ser observada</text><text x=\"590.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">live coding</text><rect x=\"490.0\" y=\"40.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mede bem</text><text x=\"590.0\" y=\"91.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">código rápido</text><text x=\"590.0\" y=\"108.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">partindo do zero</text><rect x=\"490.0\" y=\"150.0\" width=\"200.0\" height=\"100.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">também mede</text><text x=\"590.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pressão, e prática</text><text x=\"590.0\" y=\"218.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nesse tipo de problema</text><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">todo formato mede algo além do trabalho</text></svg>", "caption": "Escolher um formato é escolher que coisa acidental você aceita medir.", "same": ["live coding"]}
```

## O desafio em casa

A candidata recebe um problema pequeno e trabalha nele em casa, no próprio ambiente, em geral com um
limite de tempo sugerido. Ela entrega o código e, às vezes, conversa sobre ele numa etapa seguinte.

**O que ele mede bem:** como a pessoa escreve código quando ninguém está olhando e ela tem tempo para
pensar: estrutura, testes, nomes, as decisões que toma e registra. Dos três, é o mais próximo de como
a maior parte do trabalho de engenharia é feita.

**O que mais ele mede:** quanto tempo livre a candidata tem. Um exercício de quatro horas são quatro
horas tiradas das noites ou do fim de semana de alguém, e esse custo cai mais pesado sobre quem cuida
de outras pessoas ou tem um emprego atual exigente. As candidatas também passam muito do limite
sugerido, porque sabem que outras vão passar, o que transforma um exercício "de duas horas" numa
competição de trabalho não pago. E ele não consegue dizer com certeza quem escreveu o código.

## Pareamento

A candidata e uma pessoa engenheira do time trabalham juntas num problema realista por mais ou menos
uma hora, numa tela compartilhada. Quem entrevista participa, em vez de só observar: responde
perguntas, sugere, às vezes pega o teclado.

**O que ele mede bem:** como a pessoa trabalha em código com outra pessoa. Como faz perguntas, como
reage a uma sugestão, se explica o que está pensando, como sai de um impasse. Boa parte do trabalho é
exatamente isso.

**O que mais ele mede:** conforto em ser observada, que varia mais do que a habilidade. E ele depende
muito de quem entrevista, que pode tornar a hora colaborativa ou transformá-la numa prova com plateia.

## Live coding

A candidata resolve um problema enquanto quem entrevista observa, muitas vezes num quadro ou num editor
sem nada, às vezes contra o relógio, em geral sem as ferramentas que usaria no trabalho.

**O que ele mede bem:** a capacidade de produzir código funcionando rápido, partindo do zero, num tipo
estreito de problema.

**O que mais ele mede:** desempenho sob observação e pressão, familiaridade com o estilo do problema
(que pode ser treinado por si só) e ansiedade. Uma candidata que trava diante de um estranho pode ser
uma engenheira excelente numa mesa. **Dos três, é o mais distante de como o trabalho é feito**, e o que
tem as medições acidentais maiores.

## Nenhum é neutro

Todo formato mede algo além do trabalho. Isso não é motivo para evitá-los; é motivo para saber que
coisa acidental você está escolhendo medir, e reduzi-la onde der. A próxima seção mostra como a Caju
escolheu, e a seguinte trata de tornar qualquer formato mais justo.
