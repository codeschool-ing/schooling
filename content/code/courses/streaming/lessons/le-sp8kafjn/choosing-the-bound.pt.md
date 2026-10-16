---
title: Escolhendo o limite
version: 1
---

**O limite troca latência por completude, e o único jeito honesto de escolhê-lo é medir quão
atrasados os eventos realmente chegam.** Um limite de dois minutos quer dizer que todo resultado
espera dois minutos depois do fim da janela; um limite de três horas quer dizer que ele espera três
horas. O que cada um compra é a fração de eventos que chega a tempo de contar.

A troca aparece nas doze vendas. Com um limite de seis minutos:

```
ubuntu@stream:~/work$ python watermark.py --bound 6
 #  happened  shop      watermark  what happened
 1  09:00:40  recife    08:54:40  
 2  09:02:10  natal     08:56:10  
 3  09:03:55  olinda    08:57:55  
 4  09:05:00  recife    08:59:00  
 5  09:06:20  natal     09:00:20  
 6  09:12:30  caruaru   09:06:30  
                              emit 09:00:00-09:05:00: 3 sales, 12470
 7  09:13:05  recife    09:07:05  
 8  09:08:50  natal     09:07:05  
 9  09:14:10  olinda    09:08:10  
10  09:21:00  recife    09:15:00  
                              emit 09:05:00-09:10:00: 3 sales, 21380
                              emit 09:10:00-09:15:00: 3 sales, 12690
11  09:04:30  natal     09:15:00  too late for 09:00:00-09:05:00: dropped
12  09:23:10  olinda    09:17:10  
still open: 09:20:00 (2)
```

Nada é emitido até a venda 6, e então só a janela das 09:00; a janela das 09:05 espera até a venda 10. Mas quando é emitida ela tem **três vendas e 21.380 centavos**, venda 8 incluída, e nada é
descartado além da venda 11, que nenhum limite razoável teria pegado. **Esperar mais comprou uma
venda e custou quatro chegadas de atraso.** Num painel, é a diferença entre um número que aparece
quatro vendas depois e está certo, e um que aparece antes e fica errado.

## Medindo

A lição 9 mediu a que distância cada venda de um dia da Ponto Final chegou atrás da venda mais
recente vista antes dela. Essa distância é exatamente o que um limite precisa cobrir: uma venda cuja
distância está abaixo do limite nunca chega atrasada. Então o limite é escolhido a partir da
distribuição dessa distância, e a pergunta é qual percentil cobrir.

O tópico `late` da lição 9 guarda o dia. Se o seu cluster foi recriado desde então, crie-o de novo com
os mesmos dois comandos de lá:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic late --partitions 1 --config retention.ms=-1
Created topic late.
ubuntu@stream:~/work$ python late_tills.py
sent 360 sales to late, from 09:00:27 to 15:13:59; natal held 38 from 10:20 to 14:00
```

Depois o mesmo pipeline da lição 9, com outro final: ele imprime a distância de cada venda, ordena,
lê os percentis e conta quantas estão a até um minuto e a até dois. O p90 é a distância igual ou
abaixo da qual estão 90 por cento das vendas:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic late --from-beginning --max-messages 360 2>/dev/null \
  | jq -r '.at[:19] + "Z" | fromdate' \
  | awk '$1 > seen { seen = $1 } { print seen - $1 }' | sort -n \
  | awk '{ d[NR] = $1 } $1 <= 0 { w0++ } $1 <= 60 { w60++ } $1 <= 120 { w120++ }
         END { split("50 80 85 90 95 99 100", p, " ")
               for (i = 1; i <= 7; i++) { k = int(NR * p[i] / 100 + 0.99); print "p" p[i], d[k], "s" }
               print "within 0 s:", w0, " within 60 s:", w60, " within 120 s:", w120 }'
p50 0 s
p80 0 s
p85 40 s
p90 1847 s
p95 6373 s
p99 11332 s
p100 12154 s
within 0 s: 292  within 60 s: 311  within 120 s: 322
```

Leia de cima para baixo. **Metade das vendas, e quatro em cada cinco, chegam em ordem**: a distância
delas é zero. No p85 a distância está abaixo de um minuto. Entre o p85 e o p90 ela salta de segundos
para meia hora, porque é ali que começa a segunda população da lição 9, as vendas retidas de Natal.
Cobrir os últimos 10 por cento quer dizer esperar mais de três horas.

| limite | vendas nunca atrás dele | cada resultado espera |
|---|---|---|
| 0 | 292 de 360 | nada |
| 1 minuto | 311 de 360 | um minuto |
| 2 minutos | 322 de 360 | dois minutos |
| a maior distância | 360 de 360 | mais de três horas, o que é um batch |

**Um limite de um ou dois minutos é o certo para estes caixas**, e é certo por causa do formato, não
dos números: as entregas lentas terminam em 92 segundos e a próxima coisa é Natal, quase catorze minutos atrás.
Um limite em qualquer ponto desse vão pega o primeiro grupo e nada do segundo, então o menor limite
depois do primeiro grupo é o melhor. O segundo grupo não é trabalho do limite. É para ele que servem o
atraso permitido, o tópico de atrasadas e o batch noturno.

## Quando a distribuição muda

Um limite medido uma vez envelhece. Um caixa novo com conexão lenta alarga o primeiro grupo; uma loja
numa rede móvel que cai toda tarde cria um terceiro. É por isso que vale vigiar a contagem de eventos
atrasados no tópico de atrasadas: **um limite que combina produz um fio constante de eventos
atrasados, e uma mudança no fio é uma mudança no stream.** Meça de novo, com o mesmo pipeline, e mude
o limite quando os dados disserem, não quando uma janela estiver inconvenientemente atrasada.
