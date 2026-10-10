---
title: Origens ociosas
version: 1
---

**Um processador que lê várias partições mantém um watermark por partição e usa o menor, então uma
partição sem nada segura abertas todas as janelas de todas as partições.** É a falha que mais
surpreende, porque parece nada: nenhum erro, nenhum evento atrasado e nenhum resultado.

O menor é a regra certa, e o motivo é a última seção da lição 9. Cada partição tem a própria ordem de
chegada e não há ordem entre partições. Se a venda mais recente de uma partição é das 09:21 e a de
outra é das 09:12, a segunda ainda pode estar prestes a entregar uma venda das 09:11; um watermark
tirado da primeira a declararia atrasada antes de ela chegar. Então o processador só pode afirmar que
o tempo chegou até onde a entrada mais lenta chegou.

O `watermark.py --partitions 2` manda as vendas de Recife e Olinda por uma partição e as de Natal e
Caruaru por outra, do jeito que lojas usadas como chave se espalham pelas partições:

```
ubuntu@stream:~/work$ python watermark.py --partitions 2
```

O watermark agora é segurado pela partição que estiver atrás. Depois da venda 10, a de Recife das
09:21:00, a primeira partição chegou às 09:21, mas a mais recente da segunda ainda é a de Caruaru das
09:12:30, então o watermark fica em 09:10:30 e a janela das 09:10, emitida na venda 10 com uma
partição, **continua aberta no fim**. Uma partição lenta custa latência para todo mundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três partições depois da venda 10. A partição 0, Recife e Olinda, chegou a 09:21:00. A partição 1, Natal e Caruaru, chegou a 09:12:30. A partição 2, João Pessoa, não tem nada. O watermark é o menor dos três menos o limite, então com a partição 2 vazia não existe watermark nenhum; deixá-la de fora como ociosa dá 09:12:30 menos dois minutos, 09:10:30.\" data-fig=\"l11-partitions\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 0: recife, olinda</text><line x1=\"220\" y1=\"40\" x2=\"640\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><line x1=\"220\" y1=\"40\" x2=\"560\" y2=\"40\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></line><circle cx=\"560\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"570\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais recente 09:21:00</text><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 1: natal, caruaru</text><line x1=\"220\" y1=\"80\" x2=\"640\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><line x1=\"220\" y1=\"80\" x2=\"400\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></line><circle cx=\"400\" cy=\"80\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"410\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais recente 09:12:30</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partição 2: joao-pessoa</text><line x1=\"220\" y1=\"120\" x2=\"640\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"230\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada ainda</text><rect x=\"20\" y=\"160\" width=\"680\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o menor dos três: nenhum, então sem watermark</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">partição 2 ociosa: 09:12:30 menos 2 min = 09:10:30</text></svg>", "caption": "A partição mais lenta define o watermark. Uma vazia não define nenhum, até ser declarada ociosa."}
```

## Uma partição sem nada

A Ponto Final tem cinco lojas e estas vendas vêm de quatro delas. Com três partições, a partição de
João Pessoa não tem nada:

```
ubuntu@stream:~/work$ python watermark.py --partitions 3
```

**O watermark nunca existe, e nenhuma janela é emitida.** Toda venda é contada, nada está atrasado, e a
saída fica vazia enquanto João Pessoa não vender nada, o que numa segunda-feira calma pode ser a manhã
inteira. Uma loja que fecha por uma semana trava a cadeia inteira por uma semana. Num tópico de
verdade o mesmo acontece com uma partição para a qual nenhuma chave vai, o que a seção da lição 3
sobre escolher partições torna provável com poucas chaves e muitas partições.

## Declarando uma origem ociosa

A saída é deixar que uma partição quieta há algum tempo saia do mínimo, e volte quando mandar algo. O
Flink chama isso de `withIdleness(Duration)`, medido no relógio do processador. O programa não tem
relógio, então o `--idle` conta vendas: uma partição que não teve nada durante as últimas três vendas
fica de fora:

```
ubuntu@stream:~/work$ python watermark.py --partitions 3 --idle 3
```

A partir da venda 3, a partição de João Pessoa está ociosa e o watermark vem das outras duas. As duas
primeiras janelas são emitidas na venda 7 e a venda 8 é descartada, como com duas partições.

**Ociosidade é uma aposta no sentido contrário.** Uma partição declarada ociosa que depois entrega uma
venda antiga entrega uma venda atrasada, e o watermark, que só anda para a frente, não espera por ela.
O tempo limite deveria ser maior que os períodos quietos normais da origem mais quieta, o que é mais
uma distribuição que vale medir. O Spark contorna a questão mantendo um watermark por consulta a
partir do tempo de evento mais recente em toda a entrada, o que nunca trava e descarta mais eventos
quando as partições andam desiguais; o Kafka Streams mantém um stream time por tarefa a partir do
maior timestamp que viu. Nenhum dos dois é de graça, e a lição 13 os compara.
