---
title: Aritmética de retenção
version: 1
---

**O disco que um tópico precisa não é um chute nem um padrão; é uma multiplicação que você pode
fazer antes de o tópico existir.** Os quatro fatores são os da primeira seção desta lição: mensagens
por dia, bytes por mensagem em disco, dias guardados e cópias. Multiplique, e depois deixe folga,
porque um disco cheio para o broker (lição 16).

A conta é curta o bastante para fazer à mão e fácil o bastante de errar por um fator de mil, então
aqui ela vai como programa. Salve como `~/work/bill.py`:

```schooling-example
{
  "language": "python",
  "file": "bill.py",
  "parts": [
    {
      "code": "\"\"\"bill.py: how much disk a topic needs.\n\n    python bill.py MESSAGES_PER_DAY BYTES_PER_MESSAGE DAYS COPIES\n\"\"\"\nimport sys\n\nper_day, size, days, copies = (float(a) for a in sys.argv[1:5])\n\ndef human(n):\n    for unit in (\"B\", \"KB\", \"MB\", \"GB\", \"TB\", \"PB\"):\n        if n < 1000:\n            return f\"{n:.1f} {unit}\"\n        n /= 1000\n    return f\"{n:.1f} EB\"\n",
      "note": "Quatro números de entrada, e as unidades de saída são decimais: um gigabyte aqui é mil milhões de bytes, como conta a etiqueta de um disco."
    },
    {
      "code": "print(\"written per day     \", human(per_day * size))\nprint(\"average write rate  \", human(per_day * size / 86400) + \"/s\")\n",
      "note": "**A taxa média de escrita** é o que um dia espalha pelos seus segundos. O tráfego de verdade tem picos várias vezes maiores, e os brokers precisam absorvê-los."
    },
    {
      "code": "print(\"kept, one copy      \", human(per_day * size * days))\nprint(\"kept, all copies    \", human(per_day * size * days * copies))",
      "note": "A retenção guarda `days` disso, e toda cópia é uma cópia completa."
    }
  ]
}
```

## As vendas da Ponto Final

Suponha que as cinco lojas, abertas doze horas, juntas registrem umas 20 000 vendas num dia bom. A
seção de compressão mediu 16,9 bytes por venda com `zstd`, arredondados aqui para 17. Uma semana de
retenção, para que um replay alcance a segunda passada, e três cópias, como na lição 5:

```
ubuntu@stream:~/work$ python bill.py 20000 17 7 3
written per day      340.0 KB
average write rate   3.9 B/s
kept, one copy       2.4 MB
kept, all copies     7.1 MB
```

**As vendas da Ponto Final cabem num cartão de memória.** Esse é o resultado honesto para um negócio
pequeno: o armazenamento do stream dele é desprezível, e a conta é a computação sempre ligada da
primeira seção. Guardar um ano em vez de uma semana muda o número, e não a conclusão:

```
ubuntu@stream:~/work$ python bill.py 20000 17 365 3
written per day      340.0 KB
average write rate   3.9 B/s
kept, one copy       124.1 MB
kept, all copies     372.3 MB
```

## Um tópico em que o armazenamento é a conta

Agora um negócio diferente: o clickstream de um site, cada visualização de página, busca e clique.
Suponha 50 milhões de eventos por dia, e 400 bytes cada um em disco depois da compressão, já que uma
visualização de página carrega uma URL, um referrer e uma descrição do dispositivo. Esses dois
números são uma suposição para o exemplo, não uma medição. A mesma semana e as mesmas três cópias:

```
ubuntu@stream:~/work$ python bill.py 50000000 400 7 3
written per day      20.0 GB
average write rate   231.5 KB/s
kept, one copy       140.0 GB
kept, all copies     420.0 GB
```

**A mesma aritmética, e agora o disco é a decisão.** Cada fator é uma alavanca, e elas não são
igualmente fáceis de puxar:

| alavanca | efeito | custo de puxá-la |
|---|---|---|
| dias guardados | linear | os replays não voltam tão longe |
| compressão | divide pela taxa dela | tempo de processador em produtores e consumidores |
| cópias | linear | uma falha a menos sobrevivida; nunca abaixo de 3 para dados que importam |
| bytes por mensagem | linear | uma mudança de esquema (lição 6); tirar campos que alguém lê |
| mensagens por dia | linear | é o negócio; filtre ou amostre só o que ninguém precisa inteiro |

## Configurando

A retenção é por tópico, em milissegundos, e o padrão do broker é sete dias. Defini-la explicitamente
no tópico faz o número ficar escrito onde quem ler o tópico vai vê-lo:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name sales-zstd --alter --add-config retention.ms=604800000
Completed updating config for topic sales-zstd.
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name sales-zstd --describe
Dynamic configs for topic sales-zstd are:
  compression.type=zstd sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:compression.type=zstd, DEFAULT_CONFIG:compression.type=producer}
  retention.ms=604800000 sensitive=false synonyms={DYNAMIC_TOPIC_CONFIG:retention.ms=604800000}
```

604 800 000 milissegundos são sete dias. `retention.bytes` limita uma partição por tamanho, e quando
as duas estão definidas vale o primeiro limite alcançado. De um jeito ou de outro **a remoção é por
segmento** (lição 3): um segmento só vai embora quando a mensagem mais nova dele passou do limite,
então uma partição guarda até um segmento a mais do que a aritmética diz, e com o segmento padrão de
um gigabyte essa é uma folga real num tópico calmo.
