---
title: Novas tentativas, e o mesmo evento duas vezes
version: 1
---

Um webhook é uma requisição HTTP, e requisições falham: o receptor está reiniciando, a rede perde
um pacote, a resposta demora demais. **Então quem envia tenta de novo.** O roteador do laboratório
tenta até quatro vezes, esperando 1, 2 e 4 segundos entre as tentativas, sempre que não recebe um
2xx. Quando não há ninguém escutando, trazer o link de volta produz isto:

```
ana@ctl:~$ python link.py edge1 eth2 up
edge1 eth2: up
ana@ctl:~$ python deliveries.py
edge1-1790682864-1 attempt 1 at 08:54:45 -> 204
edge1-1790682864-2 attempt 1 at 08:54:46 -> None
edge1-1790682864-2 attempt 2 at 08:54:47 -> None
edge1-1790682864-2 attempt 3 at 08:54:49 -> None
edge1-1790682864-2 attempt 4 at 08:54:53 -> None
```

O `deliveries.py` lê o próprio log do roteador com o que ele tentou:

```schooling-example
{
  "language": "python",
  "file": "deliveries.py",
  "parts": [
    {
      "code": "from devapi import Device\n"
    },
    {
      "code": "edge1 = Device(\"edge1\")\nhook = edge1.request(\"GET\", \"/webhooks\")[\"results\"][0]\nfor d in edge1.all(f\"/webhooks/{hook['id']}/deliveries\"):\n    print(d[\"delivery\"], \"attempt\", d[\"attempt\"], \"at\", d[\"time\"][11:19], \"->\", d[\"status\"])",
      "note": "**O registro do próprio remetente do que ele tentou**: uma linha por tentativa, com o status que o receptor respondeu, ou `None` quando nada respondeu."
    }
  ]
}
```

A primeira entrega, o evento `down`, foi respondida com `204`. A segunda, o evento `up`, foi
tentada quatro vezes em intervalos crescentes e nunca respondida, `None`, e aí **o roteador
desistiu**. Esse evento se perdeu: nada vai avisar o receptor de que o link voltou. Um remetente
que tentasse para sempre encheria a memória. Um que desiste significa que **um receptor que ficou
fora do ar por um minuto tem um buraco no que sabe**, e outra coisa, uma verificação periódica ou
uma assinatura de estado como na aula 4, tem que preenchê-lo.

As novas tentativas têm uma segunda consequência, e é ela que causa incidentes. **Uma nova
tentativa pode entregar um evento sobre o qual o receptor já agiu.** Isso acontece sempre que o
receptor fez o trabalho mas a resposta não chegou a quem enviou: um timeout, uma queda logo depois
da escrita no banco de dados, ou, nesta demonstração, um receptor instruído a responder `500` uma
vez, de propósito, depois de fazer o trabalho:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Um evento, entregue duas vezes e tratado uma. O edge1 posta interface.up, assinado, para o receptor no ctl. O receptor confere a assinatura, resolve o chamado na central e responde 500. Depois de um segundo o edge1 manda o mesmo id de entrega de novo; o receptor o reconhece, não faz nada e responde 204, e o edge1 para.\"><defs><marker id=\"wh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge1</text><path d=\"M110 36 L110 346\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">receptor no ctl</text><path d=\"M360 36 L360 346\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">central de chamados</text><path d=\"M610 36 L610 346\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M112 60 L356 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST interface.up  #4</text><text x=\"372\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura conferida</text><path d=\"M362 116 L606 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"484\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resolver INC-1001</text><path d=\"M606 150 L364 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><path d=\"M356 188 L114 202\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">500</text><text x=\"100\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">espera 1 s</text><path d=\"M112 256 L356 272\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a mesma entrega #4</text><text x=\"372\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">já tratada: nada a fazer</text><path d=\"M356 316 L114 330\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wh-ah)\"></path><text x=\"234\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">204</text></svg>", "caption": "O receptor agiu na primeira entrega e não conseguiu dizer isso. O id da entrega é o que torna a segunda inofensiva.", "same": ["edge1"]}
```

```
ana@ctl:~$ python link.py edge1 eth2 up
edge1 eth2: up
```

```
ana@ctl:~$ python receiver.py 2 --fail-once
edge1-1790682864-4: interface.up edge1 eth2
   INC-1001: resolved
edge1-1790682864-4: answering 500 on purpose
edge1-1790682864-4: already handled, ignored
```

```
ana@ctl:~$ python deliveries.py | tail -2
edge1-1790682864-4 attempt 1 at 08:55:02 -> 500
edge1-1790682864-4 attempt 2 at 08:55:03 -> 204
```

A primeira tentativa resolveu o chamado e recebeu `500` como resposta. Um segundo depois o roteador
enviou **a mesma entrega**, com o mesmo id, e o receptor a encontrou em `SEEN` e não fez nada. Sem
essa verificação o chamado teria sido resolvido duas vezes, ou, para um evento `down`, aberto duas
vezes.

**Um receptor precisa ser idempotente: a mesma entrega duas vezes tem o efeito de uma.** O id da
entrega é o que torna isso possível, e um receptor que guarda o conjunto `SEEN` na memória, como
este, o perde ao reiniciar. Um receptor de produção o guarda num banco de dados com a data, e
esquece os ids depois que a janela de novas tentativas de quem envia já passou.
