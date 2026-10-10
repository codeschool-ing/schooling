---
title: Relógios que mentem
version: 1
---

**O tempo do evento só é tão bom quanto o relógio que o escreveu, e o relógio que o escreve pertence a
um aparelho que você não administra.** Tudo nas últimas três seções supôs que cada caixa sabe que
horas são. A maioria sabe. Os que não sabem não são raros, e falham de jeitos que um pipeline por
tempo do evento amplifica em vez de absorver.

Os jeitos de o relógio de um caixa dar errado são poucos e conhecidos:

- **Ele deriva.** Um cristal barato adianta ou atrasa um ou dois segundos por dia. Deixado sozinho
  por um ano, um caixa fica minutos fora, e ninguém nota porque o cupom continua saindo.
- **Ele zera.** Uma bateria de relógio morta e uma queda de energia, e o caixa liga achando que é
  1º de janeiro de 2000, ou 1970. Cada venda que ele faz chega com um quarto de século de atraso.
- **O fuso dele está errado.** Um caixa configurado em UTC que escreve a leitura com `-03:00` no fim
  afirma que cada venda aconteceu três horas depois do que de fato aconteceu, sempre, o dia todo.
- **Alguém acerta na mão**, pelo relógio da parede, que está cinco minutos adiantado.

Um relógio **atrasado** faz as vendas parecerem tardias, e elas são tratadas como as de Natal. Um
relógio **adiantado** é pior. As vendas dele dizem vir do futuro, e tudo no pipeline que acompanha
"até onde o tempo chegou" pelo maior tempo do evento visto, como faz o watermark da lição 11, salta
para a frente junto com elas. Toda venda honesta depois disso parece atrasada em comparação. Um
caixa uma hora adiantado pode deixar errados os resultados de toda a cadeia por uma hora.

## A proteção que o Kafka tem

O Kafka confere o timestamp do registro contra o relógio do próprio broker e, desde o Kafka 4.0,
recusa por padrão **qualquer registro carimbado mais de uma hora no futuro**. A configuração do
tópico é `message.timestamp.after.max.ms`, 3.600.000 milissegundos se ninguém mudar. A parceira dela,
`message.timestamp.before.max.ms`, recusaria registros antigos demais, e por padrão aceita qualquer
idade, e é por isso que os timestamps de março das últimas seções foram aceitos.

Para ver a proteção, este programa manda uma venda de um caixa cujo relógio está adiantado um certo
número de horas em relação ao real. Salve como `~/work/clock_ahead.py`:

```python
"""clock_ahead.py: one sale from a till whose clock is HOURS ahead of the broker's."""
import json
import sys
import time

from confluent_kafka import Producer

hours, topic = float(sys.argv[1]), sys.argv[2]
stamp = int((time.time() + hours * 3600) * 1000)

def report(err, msg):
    print(f"{hours:+} h: " + (f"refused, {err.str()}" if err else
          f"stored at offset {msg.offset()}, timestamp {msg.timestamp()}"))

producer = Producer({"bootstrap.servers": "localhost:9092"})
producer.produce(topic, key="caruaru", value=json.dumps({"shop": "caruaru"}),
                 timestamp=stamp, on_delivery=report)
producer.flush()
```

Duas horas adiantado e meia hora adiantado, para o tópico `clocks`, que guarda `CreateTime`:

```
ubuntu@stream:~/work$ python clock_ahead.py 2 clocks
+2.0 h: refused, Broker: Invalid timestamp
ubuntu@stream:~/work$ python clock_ahead.py 0.5 clocks
+0.5 h: stored at offset 2, timestamp (1, 1791621242883)
```

O relógio de duas horas é recusado, e o produtor é informado do motivo. O de meia hora é gravado,
dentro da hora de tolerância, com o timestamp que o caixa afirmou. No tópico `appended`, o mesmo
relógio de duas horas passa:

```
ubuntu@stream:~/work$ python clock_ahead.py 2 appended
+2.0 h: stored at offset 2, timestamp (2, 1791619443040)
```

**`LogAppendTime` pula a verificação porque descarta o timestamp do produtor de qualquer jeito**; o
par impresso diz tipo 2, log-append, e o número é o presente do broker. Nenhum dos dois tópicos olhou
dentro da mensagem. O Kafka nunca lê o `at` da venda, e um caixa poderia escrever qualquer data ali.

## O que um pipeline pode fazer

**Sincronizar os aparelhos.** Cada caixa roda NTP, que mantém o relógio a milissegundos de um
servidor de hora; no Ubuntu, `timedatectl` mostra se ele está ligado e sincronizado. Esse comando não
foi rodado para este curso: a máquina em que ele foi gravado é um contêiner que recebe o relógio do
host e não tem relógio próprio para acertar. Na sua máquina virtual, rode uma vez e leia a linha
sobre sincronização.

**Guardar os dois relógios.** Um registro cujo `at` é o relógio do caixa e cujo timestamp é o do
broker carrega a própria prova. Uma venda cujo tempo do evento é posterior à chegada é impossível:
nada chega antes de acontecer. A diferença entre os dois é o skew das últimas seções, e a mesma
subtração pega um relógio mentiroso.

**Limitar o que você acredita.** Um processador pode se recusar a deixar um tempo do evento passar à
frente da chegada por mais que uma tolerância, e prendê-lo ali:

```python
def believed(at, arrived, tolerance=timedelta(minutes=1)):
    return min(at, arrived + tolerance)
```

Essas duas linhas são um esboço, não um programa para rodar. Prender o valor impede que um caixa ruim
empurre o relógio de todo mundo para a frente, ao preço de arquivar as vendas dele no minuto errado.
A outra opção é separar esses eventos, num tópico próprio, para alguém olhar; a lição 11 faz isso
com eventos que chegam tarde demais, e o mesmo mecanismo serve para eventos que dizem ter chegado
cedo demais.
