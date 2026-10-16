---
title: Uma execução não é um veredito
version: 1
---

Toda execução de um teste de desempenho é uma amostra. Rode o mesmo teste no mesmo código e os
números voltam diferentes, porque a máquina está fazendo outras coisas, o coletor de lixo rodou
em outro momento, ou a rede fez outro caminho. A aula 8 encontrou isso como a variação dos tempos
de resposta dentro de uma execução; **aqui é a variação entre execuções**, e ela decide como um
portão tem de ser construído.

As três execuções que fizeram a linha de base na seção anterior são um pequeno exemplo:

```
ana@nft:~/boxoffice$ jq '.metrics.http_req_duration["p(95)"]' perf/runs/base-*.json
2.113172
3.177051450000001
3.384710850000008
```

O mesmo código, a mesma carga, três respostas, de 2.113 a 3.385 ms: a execução mais lenta fica 60%
acima da mais rápida. As três execuções da regressão, medidas pelo portão na próxima seção, ficam
ainda mais afastadas, e cada uma delas fica muito acima da linha de base.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 345\" role=\"img\" data-fig=\"l11-noise\" aria-label=\"O percentil 95 do GET /shows/{id} em cada execução do k6 desta aula, um ponto por execução, numa escala logarítmica de 1 a 50 milissegundos. Uma linha tracejada marca a linha de base em 3,18 ms e uma linha âmbar contínua o limite em 9,8 ms. Com o índice: as três execuções da linha de base em 2,11, 3,18 e 3,38 ms; o portão na página corrigida em 3,1, 1,9 e 1,7 ms, todas abaixo do limite; o portão na página lenta em 2,1, 12,5 e 11,4 ms, duas acima do limite sem mudança nenhuma no código. Sem o índice: a execução avulsa em 33,4 ms e o portão em 23,1, 16,8 e 21,9 ms, todas bem acima do limite.\"><text x=\"30.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">com índice</text><text x=\"30.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">sem índice</text><text x=\"30.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linha de base, 3 execuções</text><path d=\"M250.0 64.0 L690.0 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"334.1\" cy=\"64.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"380.0\" cy=\"64.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"387.1\" cy=\"64.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><text x=\"30.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">portão em /fast.html</text><path d=\"M250.0 100.0 L690.0 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"377.3\" cy=\"100.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"322.2\" cy=\"100.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"309.7\" cy=\"100.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><text x=\"30.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">portão em /</text><path d=\"M250.0 136.0 L690.0 136.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"333.4\" cy=\"136.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"534.1\" cy=\"136.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"523.7\" cy=\"136.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><text x=\"30.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma execução</text><path d=\"M250.0 202.0 L690.0 202.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"644.6\" cy=\"202.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><text x=\"30.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">portão em /fast.html</text><path d=\"M250.0 238.0 L690.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"603.1\" cy=\"238.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.3\" cy=\"238.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"597.1\" cy=\"238.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><path d=\"M380.0 46.0 L380.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M506.7 46.0 L506.7 252.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"380.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linha de base 3,18 ms</text><text x=\"512.7\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">limite 9,8 ms</text><path d=\"M250.0 290.0 L690.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M250.0 290.0 L250.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"250.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 ms</text><path d=\"M328.0 290.0 L328.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"328.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 ms</text><path d=\"M431.0 290.0 L431.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"431.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 ms</text><path d=\"M509.0 290.0 L509.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"509.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 ms</text><path d=\"M586.9 290.0 L586.9 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"586.9\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 ms</text><path d=\"M690.0 290.0 L690.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 ms</text></svg>", "caption": "Todas as execuções do back-end nesta aula. Os dois pontos à direita do limite na terceira linha são ruído: o código era o da linha de base."}
```

## Por que uma execução só não consegue ser o portão

Um portão decide a partir de um número, e com uma execução só esse número é o que aquela execução
por acaso deu. Seguem-se dois tipos de erro, e os dois custam caro:

- **Uma falsa reprovação.** Uma boa mudança reprova porque a única execução dela caiu num momento
  ocupado. Alguém roda o job de novo, ele passa, e a equipe aprende que um portão de desempenho
  vermelho quer dizer "roda de novo". Depois de algumas semanas disso, ninguém mais o lê. A
  próxima seção tem uma, nesta máquina.
- **Uma falsa aprovação.** Uma regressão de verdade passa porque a única execução dela caiu num
  momento tranquilo. Ninguém percebe, e a próxima linha de base é gravada da versão mais lenta.

## Repita, e tire a mediana

A mediana de várias execuções se mexe muito menos que qualquer uma delas, e uma execução fora da
curva não a arrasta como arrasta uma média. A documentação do Lighthouse recomenda a mediana de
cinco execuções; o portão desta aula usa três de cada ferramenta para ficar em poucos minutos, a
troca de sempre entre quanto um pull request espera e quantas vezes o portão erra.

Há um atalho para limites. **Com três execuções e um limite fixo, a mediana cruza o limite
exatamente quando pelo menos duas das execuções cruzam.** Então o portão não precisa juntar os
três percentis 95 e ordená-los: ele conta quantas execuções o k6 reprovou, e reprova com duas.
Com cinco execuções a regra é três.

## A tolerância precisa ser mais larga que o ruído

Uma tolerância é uma afirmação sobre o ruído. Ponha-a mais estreita que a variação entre execuções
e o portão reprova boas mudanças; ponha-a larga demais e ele aprova regressões de verdade.
**Meça a variação primeiro, depois defina a tolerância**, e defina em duas partes quando o
endpoint é rápido:

- uma **parte relativa**, aqui 50%, que cresce com o endpoint: um endpoint de 100 ms ganha 50 ms
  de folga;
- uma **parte absoluta**, aqui 5 ms, porque numa requisição que leva dois milissegundos o ruído se
  mede em milissegundos, não em porcentagem. Cinquenta por cento de 2 ms é 1 ms, e uma máquina
  ocupada acrescenta mais que isso.

Mais dois hábitos seguram o ruído. Rode o portão no mesmo tipo de máquina toda vez, já que uma
linha de base de um runner e uma execução em outro comparam os runners. E renove a linha de base
de propósito, quando se aceita uma mudança que deveria movê-la, nunca automaticamente a partir da
última execução: uma linha de base que segue cada execução segue cada regressão também.
