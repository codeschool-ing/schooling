---
title: Acrescentando processadores
version: 1
---

Um teste de escalabilidade precisa de uma segunda configuração para comparar, e uma VM com quatro
processadores consegue fornecer uma sem construir nada. **`taskset` inicia um programa autorizado a
rodar só nos processadores que você nomeia**, numerados a partir de 0. Assim a bilheteria pode
receber um processador, depois dois, e o gerador de carga fica em outros dois, onde não disputa com
nenhum deles.

No terminal do servidor, pare a bilheteria com `Ctrl+C` e inicie-a só no processador 0:

```sh
taskset -c 0 python3 app.py
```

No segundo terminal, uma escada de 20 a 80 por segundo, com o gerador nos processadores 2 e 3:

```
ana@nft:~/loadtest$ taskset -c 2,3 python3 hammer.py http://127.0.0.1:8000/shows/990 20:2 40:2 60:2 80:2
second  sent  done  errors  median ms  max ms
     0    20    20       0         23      87
     1    20    20       0         25      43
     2    40    40       0         20      47
     3    40    39       0         23      66
     4    60    51       0        125     392
     5    60    48       0        341    1075
     6    80    46       0        944    3274
     7    80    47       0       1111    2326
89 answers came back after second 7; the last at 9.6 s
```

Depois `Ctrl+C` no terminal do servidor de novo, e a mesma bilheteria nos processadores 0 e 1:

```sh
taskset -c 0,1 python3 app.py
```

A mesma rodada a partir do segundo terminal:

```
ana@nft:~/loadtest$ taskset -c 2,3 python3 hammer.py http://127.0.0.1:8000/shows/990 20:2 40:2 60:2 80:2
second  sent  done  errors  median ms  max ms
     0    20    20       0         25      62
     1    20    20       0         23      37
     2    40    40       0         29     108
     3    40    40       0         22      41
     4    60    59       0         22      39
     5    60    60       0         23      52
     6    80    77       0         41      75
     7    80    79       0         26      97
5 answers came back after second 7; the last at 8.0 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-scale\" aria-label=\"A mesma carga em degraus, de 20 a 80 requisições por segundo, contra a bilheteria com um processador e depois com dois. Os dois carregam 20 e 40 por segundo. Com um processador as respostas param em 51, 48, 46 e 47 por segundo enquanto 60 e depois 80 são enviadas. Com dois elas chegam a 59, 60, 77 e 79, perto de tudo o que foi enviado.\"><path d=\"M90.0 230.0 L550.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M90.0 30.0 L90.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M86.0 230.0 L90.0 230.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M86.0 190.0 L90.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M90.0 190.0 L550.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 150.0 L90.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><path d=\"M90.0 150.0 L550.0 150.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 110.0 L90.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">60</text><path d=\"M90.0 110.0 L550.0 110.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 70.0 L90.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M90.0 70.0 L550.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M86.0 30.0 L90.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.0\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><path d=\"M90.0 30.0 L550.0 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"118.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"176.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"233.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"291.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"348.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"406.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"463.8\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"521.2\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"320.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundo da rodada</text><text x=\"56.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por segundo</text><path d=\"M90.0 190.0 L147.5 190.0 L147.5 190.0 L205.0 190.0 L205.0 150.0 L262.5 150.0 L262.5 150.0 L320.0 150.0 L320.0 110.0 L377.5 110.0 L377.5 110.0 L435.0 110.0 L435.0 70.0 L492.5 70.0 L492.5 70.0 L550.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M118.8 190.0 L176.2 190.0 L233.8 150.0 L291.2 150.0 L348.8 112.0 L406.2 110.0 L463.8 76.0 L521.2 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"118.8\" cy=\"190.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"176.2\" cy=\"190.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"233.8\" cy=\"150.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"291.2\" cy=\"150.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"348.8\" cy=\"112.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"406.2\" cy=\"110.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"463.8\" cy=\"76.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"521.2\" cy=\"72.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><path d=\"M118.8 190.0 L176.2 190.0 L233.8 150.0 L291.2 152.0 L348.8 128.0 L406.2 134.0 L463.8 138.0 L521.2 136.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"118.8\" cy=\"190.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"176.2\" cy=\"190.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"233.8\" cy=\"150.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"291.2\" cy=\"152.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"348.8\" cy=\"128.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"406.2\" cy=\"134.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"463.8\" cy=\"138.0\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"521.2\" cy=\"136.0\" r=\"3\" fill=\"var(--amber)\"></circle><path d=\"M570.0 60.0 L592.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"598.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">enviadas</text><path d=\"M570.0 84.0 L592.0 84.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"598.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done, 2 processadores</text><path d=\"M570.0 108.0 L592.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"598.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">done, 1 processador</text></svg>", "caption": "A vazão contra a mesma carga, com um processador e com dois. Onde a linha de um processador fica plana está a capacidade daquela configuração."}
```

Com um processador a bilheteria acompanha 20 e 40 por segundo, e depois fica plana: 51 e 48
respostas por segundo enquanto 60 são enviadas, 46 e 47 enquanto 80 são, com a mediana subindo até
1111 ms. **A capacidade dela com um processador fica perto de 50 requisições por segundo.** Com dois
ela carrega tudo, 79 respostas no último segundo de 80 enviadas, e a mediana nunca passa de 41 ms.
Esta rodada não encontrou a capacidade com dois processadores, porque parou em 80; um teste de
escalabilidade continuaria subindo até encontrá-la, e compararia as duas capacidades.

Essa razão é o resultado. Se dois processadores carregam o dobro do que um carregava, a operação
escala com processadores, e para `GET /shows/{id}` o começo da evidência está aqui: o trabalho é uma
consulta ao banco, e o SQLite consegue rodar consultas de várias threads em vários processadores ao
mesmo tempo.

Nem toda operação da bilheteria passaria no mesmo teste. Uma reserva segura `booking_lock` durante
todo o pagamento, então duas reservas nunca rodam ao mesmo tempo, tenha a máquina o que tiver, e
acrescentar processadores a ela não acrescenta nada. **Um sistema escala só até onde vai a parte
dele que não pode ser compartilhada**, e a aula 9 mede exatamente essa parte. Volte ao
`python3 app.py` simples quando terminar aqui; as próximas aulas esperam os quatro processadores.
