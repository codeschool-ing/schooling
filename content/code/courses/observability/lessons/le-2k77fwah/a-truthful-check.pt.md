---
title: Uma verificação de readiness que diz a verdade
version: 1
---

A correção de um `/health` mentiroso não é fazê-lo verificar tudo. **É perguntar, para cada serviço, de
que ele precisa para fazer o trabalho dele**, e verificar exatamente isso. O `orders` precisa do banco
para guardar um pedido e do broker para anunciá-lo, então a readiness dele verifica os dois:

```schooling-example
{
  "language": "python",
  "file": "orders/app.py",
  "parts": [
    {
      "code": "@app.get(\"/ready\")\ndef ready():\n    \"\"\"Ready to take an order: the database answers and the broker takes a connection.\"\"\"\n",
      "note": "Um segundo endpoint ao lado do `/health`, que fica como estava. A docstring é o contrato: o que *pronto* significa para este serviço."
    },
    {
      "code": "    checks = {}\n    try:\n        with psycopg.connect(DB, connect_timeout=2) as conn:\n            conn.execute(\"SELECT 1\")\n        checks[\"postgres\"] = \"ok\"\n    except psycopg.Error as e:\n        checks[\"postgres\"] = type(e).__name__\n",
      "note": "**A mesma coisa de que um pedido precisa, feita de verdade**: uma conexão e uma consulta. O `connect_timeout` impede que uma sonda fique pendurada mais tempo do que quem sonda espera por ela."
    },
    {
      "code": "    try:\n        params = pika.ConnectionParameters(RABBIT, socket_timeout=2, connection_attempts=1)\n        with pika.BlockingConnection(params):\n            checks[\"rabbitmq\"] = \"ok\"\n    except pika.exceptions.AMQPError as e:\n        checks[\"rabbitmq\"] = type(e).__name__\n",
      "note": "O broker também, já que um pedido que não pode ser anunciado deixa o cliente sem confirmação. Uma tentativa, dois segundos."
    },
    {
      "code": "    ok = all(v == \"ok\" for v in checks.values())\n    return {\"ready\": ok, \"checks\": checks}, 200 if ok else 503\n",
      "note": "**Uma verificação que falha se nomeia** no corpo, e o código de status leva o veredito: 503 é o que todo sondador entende como *agora não*."
    }
  ]
}
```

O `/health` fica como estava, e agora tem um nome que merece: diz que o processo está no ar e
respondendo, que é o que uma sonda de liveness deve perguntar. O `/ready` diz se um pedido passaria. O
Docker o usa na próxima seção, e ele responde assim com o banco parado: `503`,
`{"checks": {"postgres": "OperationalError", "rabbitmq": "ok"}, "ready": false}`.

Quatro regras impedem que uma verificação de readiness cause o problema que devia relatar:

- **Verifique as suas próprias dependências, nunca a readiness de outro serviço.** Se a readiness da
  vitrine perguntasse a readiness do `orders`, a queda do banco tiraria a vitrine do rodízio também,
  incluindo as páginas que nunca tocam no banco.
- **Mantenha-a barata.** Uma sonda roda a cada poucos segundos em toda cópia; esta abre uma conexão
  com o banco e uma com o broker a cada vez, o que está bem para duas cópias e vale medir para
  duzentas. Uma conexão já existente de um pool, ou um resultado guardado por alguns segundos, é a
  resposta de costume.
- **Desista antes de quem sonda desistir.** Uma verificação que trava é relatada como timeout, e o
  corpo que nomeia a dependência com falha se perde.
- **Exclua-a dos rastros e das métricas, ou saiba que ela está lá.** O laboratório exclui o `/health`
  dos rastros do `orders`, mas não o `/ready`, então toda sonda agora aparece no Jaeger e na taxa de
  requisições. Um painel de requisições por segundo que de repente sobe uma a cada cinco segundos é
  uma sonda.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Duas formas de escrever prontidão para uma cadeia: a vitrine chama o orders, e o orders usa o banco. Em cima, cada serviço verifica só o que usa diretamente, então quando o banco cai só o orders fica não pronto. Embaixo, a prontidão da vitrine pergunta a prontidão do orders, então o banco fora deixa a vitrine não pronta também, e o balanceador não tem para onde mandar nem as páginas que não precisam do banco.\"><defs><marker id=\"cs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dependências próprias</text><rect x=\"200\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"260.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pronto</text><rect x=\"360\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"420.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não pronto</text><rect x=\"520\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">banco</text><text x=\"580.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora</text><path d=\"M322 60 L358 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M482 60 L518 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">prontidão encadeada</text><rect x=\"200\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"260.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não pronto</text><rect x=\"360\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"420.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não pronto</text><rect x=\"520\" y=\"150\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">banco</text><text x=\"580.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora</text><path d=\"M322 170 L358 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><path d=\"M482 170 L518 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cs-ah)\"></path><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">só o orders sai do rodízio</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a vitrine sai também, por um banco que ela nunca chama</text></svg>", "caption": "Prontidão que verifica as próprias dependências isola uma falha; prontidão que pergunta a prontidão de outros serviços a espalha por tudo acima.", "same": ["orders", "storefront"]}
```

**Uma verificação que diz *não pronto* precisa ser obedecida por alguém.** O Docker a registra e não
faz nada; o Kubernetes tira o pod do Service; um balanceador para de mandar para ele. As duas próximas
seções observam os dois primeiros.
