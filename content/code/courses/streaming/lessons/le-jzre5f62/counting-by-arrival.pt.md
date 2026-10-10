---
title: Contar pela chegada, e contar pelo evento
version: 1
---

**As mesmas vendas, contadas por hora, dão duas tabelas diferentes conforme o relógio que decide a
hora.** Nenhuma das tabelas é um erro de contagem. Cada uma é a resposta certa para uma pergunta
diferente, e o erro é publicar uma acreditando que é a outra.

Este programa lê o tópico `late` desde o início e conta cada venda duas vezes: uma no balde em que
cai o timestamp do registro, que é quando ela chegou, e outra no balde em que cai o `at`, que é
quando ela aconteceu. Salve como `~/work/per_minute.py`:

```schooling-example
{
  "language": "python",
  "file": "per_minute.py",
  "parts": [
    {
      "code": "\"\"\"per_minute.py: sales per minute, counted by two clocks.\n\n    python per_minute.py [--topic T] [--size MINUTES] [--from HH:MM] [--to HH:MM]\n\nReads the whole topic, then prints, for each bucket of --size minutes, how many\nsales ARRIVED in it (the record's timestamp) and how many HAPPENED in it (the\nsale's own \"at\").\n\"\"\"\nimport argparse\nimport json\nfrom collections import Counter\nfrom datetime import datetime, timedelta, timezone\n\nfrom confluent_kafka import Consumer, TopicPartition, OFFSET_BEGINNING\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--topic\", default=\"late\")\nargs.add_argument(\"--size\", type=int, default=1)\nargs.add_argument(\"--from\", dest=\"start\", default=\"00:00\")\nargs.add_argument(\"--to\", dest=\"end\", default=\"23:59\")\nargs = args.parse_args()\nLOCAL = timezone(timedelta(hours=-3))\n",
      "note": "O que ele faz. Os baldes têm um minuto, a não ser que `--size` diga outra coisa, e `--from` e `--to` cortam o que é impresso."
    },
    {
      "code": "def bucket(t):\n    t = t.astimezone(LOCAL)\n    minute = (t.hour * 60 + t.minute) // args.size * args.size\n    return f\"{minute // 60:02d}:{minute % 60:02d}\"\n",
      "note": "**Um balde é o início da fatia do dia em que um momento cai**: 10:37 está no balde das 10:00 de uma hora, e no balde das 10:37 de um minuto."
    },
    {
      "code": "consumer = Consumer({\"bootstrap.servers\": \"localhost:9092\", \"group.id\": \"per-minute\",\n                     \"enable.partition.eof\": True, \"enable.auto.commit\": False})\nconsumer.assign([TopicPartition(args.topic, 0, OFFSET_BEGINNING)])",
      "note": "Ele lê a partição 0 a partir do primeiro offset e para no fim dela: `enable.partition.eof` transforma o fim numa mensagem que o laço consegue ver. Nada é confirmado, então toda execução lê tudo."
    },
    {
      "code": "arrived, happened = Counter(), Counter()\nwhile True:\n    msg = consumer.poll(5)\n    if msg is None or msg.error():\n        break\n    sale = json.loads(msg.value())\n    arrived[bucket(datetime.fromtimestamp(msg.timestamp()[1] / 1000, LOCAL))] += 1\n    happened[bucket(datetime.fromisoformat(sale[\"at\"]))] += 1\nconsumer.close()\n",
      "note": "O coração do programa: **uma venda, dois baldes.** `msg.timestamp()` é um par, o tipo e os milissegundos; o segundo é a chegada."
    },
    {
      "code": "print(f\"{'minute' if args.size == 1 else 'from':>6}  arrived  happened\")\nfor b in sorted(set(arrived) | set(happened)):\n    if args.start <= b <= args.end:\n        print(f\"{b:>6}  {arrived[b]:7d}  {happened[b]:8d}\")",
      "note": "Uma linha por balde que tenha algo em qualquer das colunas."
    }
  ]
}
```

Um programa que consumisse as vendas ao vivo usaria o próprio relógio como tempo de processamento,
e esse relógio estaria poucos milissegundos atrás da chegada de cada registro. Lendo depois do fato,
como este faz, o relógio dele poria as 360 vendas no minuto em que você o rodou, o que não diz nada.
**Então o timestamp do registro faz as vezes do tempo de processamento**: é o momento em que um
leitor em dia teria visto a venda.

Primeiro por hora:

@@fence@@

Leia as duas colunas de cima para baixo. Até as dez elas quase concordam; a diferença de uma venda é
uma venda do fim da hora das nove que chegou na hora das dez. Das 10:00 às 13:00 a coluna de chegada
fica abaixo em todas as horas, por 5, 11, 13 e 9, e então a hora das 14:00 tem 93 onde aconteceram
54. **As duas colunas somam 360.** Nenhuma venda se perdeu e nenhuma foi contada duas vezes; a
coluna de chegada moveu 38 delas, todas de Natal, para a hora em que o caixa voltou, e mais duas
pela borda de uma hora, por alguns segundos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Barras de vendas por hora, duas por hora. Contadas pelo tempo do evento, as horas de 10:00 a 13:00 têm 62, 59, 54 e 60 vendas e 14:00 tem 54. Contadas pela chegada, essas quatro horas têm 57, 48, 41 e 51, e 14:00 tem 93.\" data-fig=\"l9-per-hour\"><line x1=\"60\" y1=\"250\" x2=\"700\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"60\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">vendas</text><text x=\"54\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"54\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><line x1=\"60\" y1=\"150.0\" x2=\"700\" y2=\"150.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"54\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><line x1=\"60\" y1=\"50.0\" x2=\"700\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><rect x=\"70\" y=\"136.0\" width=\"30\" height=\"114.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"104\" y=\"138.0\" width=\"30\" height=\"112.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">57</text><text x=\"119\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">56</text><text x=\"102\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">09:00</text><rect x=\"160\" y=\"126.0\" width=\"30\" height=\"124.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"194\" y=\"136.0\" width=\"30\" height=\"114.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">62</text><text x=\"209\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">57</text><text x=\"192\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10:00</text><rect x=\"250\" y=\"132.0\" width=\"30\" height=\"118.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"284\" y=\"154.0\" width=\"30\" height=\"96.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">59</text><text x=\"299\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">48</text><text x=\"282\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11:00</text><rect x=\"340\" y=\"142.0\" width=\"30\" height=\"108.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"374\" y=\"168.0\" width=\"30\" height=\"82.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">54</text><text x=\"389\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">41</text><text x=\"372\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12:00</text><rect x=\"430\" y=\"130.0\" width=\"30\" height=\"120.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"464\" y=\"148.0\" width=\"30\" height=\"102.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">60</text><text x=\"479\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">51</text><text x=\"462\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13:00</text><rect x=\"520\" y=\"142.0\" width=\"30\" height=\"108.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"554\" y=\"64.0\" width=\"30\" height=\"186.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">54</text><text x=\"569\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">93</text><text x=\"552\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14:00</text><rect x=\"610\" y=\"222.0\" width=\"30\" height=\"28.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"644\" y=\"222.0\" width=\"30\" height=\"28.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">14</text><text x=\"659\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">14</text><text x=\"642\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15:00</text><rect x=\"460\" y=\"18\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"476\" y=\"23\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aconteceram</text><rect x=\"570\" y=\"18\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"586\" y=\"23\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chegaram</text></svg>", "caption": "As mesmas 360 vendas por hora. Pela chegada, a manhã perde as vendas de Natal e as 14:00 ganham todas."}
```

O minuto em torno das 14:00 mostra para onde elas foram:

@@fence@@

**Trinta e nove vendas chegaram no minuto das 14:00, e nenhuma aconteceu nele.** Um painel de vendas
por minuto pela chegada mostraria um pico ali, e um período sem nada em Natal das 10:20 às 14:00. Um
alerta do tipo "Natal não vende nada há uma hora" teria disparado antes das onze e meia, verdadeiro
pela chegada e falso pelo evento, e teria sido apagado às 14:00 por uma rajada que parece uma
correria de clientes. Uma contagem de estoque feita em cima disso estaria errada a manhã inteira, de
um jeito que ninguém conseguiria ver.

## O preço da coluna certa

A coluna do que aconteceu é o que o gerente quer dizer com "vendas entre as dez e as onze", e é ela
que se publica. Mas veja quanto ela custou: às 11:00, a hora das 10:00 pelo tempo do evento não era
62. Era 62 menos cada venda de Natal ainda presa no caixa. **Um resultado pelo tempo do evento só
está correto quando todos os eventos que pertencem a ele chegaram, e o processador não tem como
saber quando isso acontece.** Ou ele espera, ou publica e corrige depois, ou decide que alguns
eventos estão atrasados demais para contar. A lição 10 dá a esses baldes o nome certo, janelas, e a
lição 11 é inteira sobre essa decisão.
