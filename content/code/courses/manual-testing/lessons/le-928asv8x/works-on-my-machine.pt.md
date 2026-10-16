---
title: Na minha máquina funciona
version: 1
---

"Na minha máquina funciona" costuma ser ouvido como um desenvolvedor descartando um relatório. Lido
ao pé da letra, é uma medição, e útil: **a mesma versão se comporta de um jeito em dois lugares
diferentes, então alguma coisa nesses dois lugares é diferente, e essa coisa faz parte do defeito.**
As duas pessoas estão dizendo a verdade. O trabalho do testador é achar a diferença e transformá-la
em passos que qualquer um consiga seguir.

## O relatório

Às cinco e meia de uma tarde de sábado, horário de São Paulo, você está conferindo a candidata à
versão 1.1 na homologação antes de ela entrar no ar. Você entra como o membro e tenta reservar dois
ingressos para The Seagull, que começa às 20:00. As reservas deveriam fechar uma hora antes do
espetáculo (R4), às 19:00, então deviam estar abertas. A página responde:

> Booking for this show has closed.

Você relata. Rui abre o notebook, inicia o mesmo arquivo 1.1, reserva dois ingressos para The Seagull
no mesmo momento e recebe um pedido. Ele responde que na máquina dele funciona, e ele tem razão.

## Segurar tudo parado menos uma coisa

Duas máquinas diferem em dezenas de coisas, e compará-las à mão não acha nada. A técnica é a que todo
experimento usa: **reproduzir os dois resultados numa máquina só e depois mudar uma configuração de
cada vez até o resultado virar.** O que fez virar é a causa, ou está perto dela.

O primeiro obstáculo é o relógio. O defeito acontece às 17:30, e você não pode esperar dar 17:30 cada
vez que quiser tentar alguma coisa. O boxoffice lê de `BOXOFFICE_NOW` o momento em que deve
acreditar, então você pode fixá-lo: o mesmo instante, escrito com o deslocamento de São Paulo,
`-03:00`, em todas as execuções.

A segunda coisa a segurar ou variar é o fuso horário, e no Linux e no macOS um programa o lê da
variável `TZ`. Sua máquina está no horário de São Paulo, e Rui contou que os servidores alugados estão
em UTC. Então a primeira execução copia o notebook do Rui. Pare o boxoffice se ele estiver rodando e
inicie-o no terminal dele assim:

```
ana@laptop:~/boxoffice$ TZ=America/Sao_Paulo BOXOFFICE_NOW=2026-10-10T17:30:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

Reserve dois ingressos para The Seagull como o membro, no navegador ou do segundo terminal:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

É o resultado do Rui. Agora aperte Ctrl-C e inicie de novo com **uma** coisa mudada, o fuso horário:

```
ana@laptop:~/boxoffice$ TZ=UTC BOXOFFICE_NOW=2026-10-10T17:30:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

A mesma reserva, no mesmo instante:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

É o seu resultado da homologação, no seu próprio notebook. Mesmo arquivo, mesmo instante, mesma
requisição; o fuso horário foi a única mudança, então o fuso horário está no defeito. Esse é o
defeito 9 deste curso, e você o achou sem abrir o código.

**Nada na tela entrega o problema.** Na execução em UTC a página inicial lista o espetáculo
exatamente como em São Paulo:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<td>The Seagull</td><td>[^<]*</td>'
<td>The Seagull</td><td>2026-10-10 20:00</td>
```

## Onde ele fecha

Um relatório de defeito diz quando ele acontece, e "às 17:30" é um ponto, não uma regra. O raciocínio
de valores-limite da aula 4 acha a regra: tente um momento de cada lado de onde você suspeita que
está a fronteira. Inicie com `TZ=UTC BOXOFFICE_NOW=2026-10-10T15:59:00-03:00 python3 boxoffice.py` e
reserve:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

Depois com `TZ=UTC BOXOFFICE_NOW=2026-10-10T16:01:00-03:00 python3 boxoffice.py`:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

**Numa máquina em UTC, as reservas fecham às 16:00 do horário de São Paulo, três horas antes.** Essa
é uma frase que o gerente do teatro consegue pesar: três horas de vendas de uma noite, toda noite, na
única máquina que os clientes usam.

## A causa, nas palavras de um testador

Você não precisa da linha de código para explicar, e um relatório que chuta o código muitas vezes
erra. O que as duas execuções mostram é isto. Os horários dos espetáculos são horários de São Paulo
escritos sem fuso, como diz o R1. O programa os compara com **o relógio da própria máquina**. Numa
máquina no horário de São Paulo os dois concordam; numa máquina em UTC, o relógio marca três horas a
mais, então 17:30 em São Paulo são 20:30 naquela máquina, depois do fechamento das 19:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l21-two-clocks\" aria-label=\"Duas linhas de relógio, uma sobre a outra, alinhadas para que o mesmo instante fique no mesmo lugar. A de cima é uma máquina no horário de São Paulo, de 14:00 a 22:00. A de baixo é uma máquina em UTC, cujos rótulos vão três horas à frente, de 17:00 a 01:00. Uma linha vertical marca um instante, 17:30 em São Paulo, que a máquina de cima lê como 17:30 e a de baixo como 20:30. Cada linha tem o fechamento das reservas às 19:00 do seu próprio relógio: na de cima ele fica à direita do instante, então a reserva está aberta; na de baixo ele cai às 16:00 de São Paulo, à esquerda do instante, então a reserva está fechada.\"><text x=\"60.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">máquina no horário de São Paulo</text><rect x=\"435.0\" y=\"76.0\" width=\"225.0\" height=\"14.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><path d=\"M60.0 90.0 L660.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 86.0 L60.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14:00</text><path d=\"M135.0 86.0 L135.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"135.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M210.0 86.0 L210.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16:00</text><path d=\"M285.0 86.0 L285.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><path d=\"M360.0 86.0 L360.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M435.0 86.0 L435.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"435.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><path d=\"M510.0 86.0 L510.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20:00</text><path d=\"M585.0 86.0 L585.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"585.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M660.0 86.0 L660.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">22:00</text><path d=\"M435.0 66.0 L435.0 96.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"441.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fecha 19:00</text><text x=\"60.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">máquina em UTC</text><rect x=\"210.0\" y=\"191.0\" width=\"450.0\" height=\"14.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><path d=\"M60.0 205.0 L660.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 201.0 L60.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><path d=\"M135.0 201.0 L135.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"135.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M210.0 201.0 L210.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><path d=\"M285.0 201.0 L285.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20:00</text><path d=\"M360.0 201.0 L360.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M435.0 201.0 L435.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"435.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">22:00</text><path d=\"M510.0 201.0 L510.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">23:00</text><path d=\"M585.0 201.0 L585.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"585.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M660.0 201.0 L660.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">01:00</text><path d=\"M210.0 181.0 L210.0 211.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"216.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fecha 19:00</text><path d=\"M322.5 36.0 L322.5 262.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"322.5\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">o mesmo instante: 17:30 em São Paulo</text><circle cx=\"322.5\" cy=\"90.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"314.5\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">marca 17:30</text><text x=\"314.5\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">aberta</text><circle cx=\"322.5\" cy=\"205.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"330.5\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">marca 20:30</text><text x=\"330.5\" y=\"253.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">fechada</text></svg>", "caption": "Um instante em duas máquinas. Cada uma fecha as reservas às 19:00 do próprio relógio, e a máquina em UTC chega às 19:00 três horas antes."}
```

Isso basta para o Rui achar a linha em um minuto, e está escrito de um jeito que continua verdadeiro
qualquer que seja a correção que ele fizer.

## No Windows

Nada disto foi executado no Windows, e os comandos acima não servem lá. O Windows guarda o fuso
horário como uma configuração do sistema, e o Python ali não lê um nome de fuso como
`America/Sao_Paulo` de uma variável `TZ` do jeito que lê no Linux e no macOS. Para reproduzir a
execução em UTC no Windows, você muda o fuso horário do próprio computador para UTC nas
configurações de data e hora, inicia o boxoffice com `BOXOFFICE_NOW` definido e volta o fuso ao
terminar. No PowerShell a variável se define com `$env:BOXOFFICE_NOW = "2026-10-10T17:30:00-03:00"`
antes de `py boxoffice.py`.

## O que o tornou difícil de achar

Três coisas, e todas são comuns. **A diferença era invisível**: nenhuma página mostra o fuso, e
ninguém tinha listado o relógio como parte do ambiente. **Dependia da hora**: de manhã as duas
máquinas aceitam toda reserva, então a maioria das execuções de teste passa nas duas. **E as duas
pessoas envolvidas tinham, cada uma, um resultado verdadeiro**, o que transforma um defeito numa
discussão sobre qual máquina está certa. A saída dessa discussão é o par de execuções acima, que
qualquer um pode repetir e que mostra os dois resultados de uma vez.
