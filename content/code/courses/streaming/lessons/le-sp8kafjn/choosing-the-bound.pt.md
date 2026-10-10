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
```

Nada é emitido até a venda 6, e então só a janela das 09:00; a janela das 09:05 espera até a venda
10. Mas quando é emitida ela tem **três vendas e 21.380 centavos**, venda 8 incluída, e nada é
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
```

Depois o mesmo pipeline da lição 9, com outro final: ele imprime a distância de cada venda, ordena,
lê os percentis, em que p90 é a distância igual ou abaixo da qual estão 90 por cento das vendas, e
conta quantas estão a até um minuto e a até dois:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic late --from-beginning --max-messages 360 2>/dev/null \
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
dos números: as entregas lentas terminam em 92 segundos e a próxima coisa é Natal, meia hora depois.
Um limite em qualquer ponto desse vão pega o primeiro grupo e nada do segundo, então o menor limite
depois do primeiro grupo é o melhor. O segundo grupo não é trabalho do limite. É para ele que servem o
atraso permitido, o tópico de atrasadas e o batch noturno.

## Quando a distribuição muda

Um limite medido uma vez envelhece. Um caixa novo com conexão lenta alarga o primeiro grupo; uma loja
numa rede móvel que cai toda tarde cria um terceiro. É por isso que vale vigiar a contagem de eventos
atrasados no tópico de atrasadas: **um limite que combina produz um fio constante de eventos
atrasados, e uma mudança no fio é uma mudança no stream.** Meça de novo, com o mesmo pipeline, e mude
o limite quando os dados disserem, não quando uma janela estiver inconvenientemente atrasada.
