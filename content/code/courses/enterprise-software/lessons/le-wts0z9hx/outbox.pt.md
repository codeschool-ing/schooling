---
title: O outbox transacional
version: 1
---

O consumidor da seção anterior está protegido contra duplicatas. O publicador tem um problema
próprio, e é fácil escrevê-lo sem enxergá-lo. Um serviço que grava algo no seu banco e depois
publica uma mensagem sobre isso está escrevendo em **dois sistemas que não compartilham
transação**. Uma escrita pode dar certo e a outra falhar, e **nenhuma ordem das duas chamadas, e
nenhuma quantidade de retentativas, faz as duas darem certo ou falharem juntas**. Esse é o
*problema da escrita dupla*, e o outbox transacional é a resposta padrão a ele.

## Quatro resultados, dois deles errados

A primeira versão do Portal B2B recebia o pedido de uma padaria assim: confirmava o pedido no seu
próprio banco PostgreSQL e depois punha uma mensagem em `SA.PORTAL.ORDERS` para o SAP. As duas
escritas dão quatro resultados:

| commit no banco | publicação | resultado |
|---|---|---|
| dá certo | dá certo | correto |
| falha | não tentada | correto: a padaria vê um erro e tenta de novo |
| dá certo | falha | a padaria tem um pedido confirmado do qual o SAP nunca fica sabendo |
| falha depois da publicação | dá certo | o SAP cria uma ordem de venda da qual o portal não tem registro |

A terceira linha foi a que aconteceu. Num domingo à noite de 2024 o gerenciador de filas foi
reiniciado para manutenção com o portal funcionando, e por uns quarenta minutos todo put falhou. O
portal tinha gravado cada pedido e mostrado a cada padaria uma confirmação; o erro do put foi para
um log que ninguém lia aos domingos. **47 pedidos nunca foram entregues.** A Serra Alta descobriu
na segunda de manhã, quando as primeiras padarias ligaram perguntando pela manteiga.

Inverter a ordem das chamadas só leva o problema para a quarta linha: publicar primeiro e depois
confirmar, e um commit que falha deixa o SAP com um pedido que o portal nunca confirmou. Um laço de
retentativas em volta da publicação ajuda numa queda curta e não faz nada quando o próprio processo
do portal morre entre as duas chamadas, que é o momento que um deploy ou uma falha escolhe.

## Uma transação, depois um relay

O outbox põe as duas escritas no único sistema que tem transações: o banco do próprio serviço.

1. Numa transação local, grave a linha de negócio **e** uma linha numa tabela `outbox` que guarda a
   mensagem, como ela será publicada, com o seu id.
2. Um processo separado, o **relay**, lê as linhas do outbox ainda não enviadas, publica cada uma e
   a marca como enviada.

O passo 1 é atômico: o pedido existe se e somente se a mensagem dele existe. O passo 2 pode falhar
em qualquer ponto e ser repetido, porque a mensagem está segura na tabela até ser marcada. Chris
Richardson deu ao padrão o nome *transactional outbox* no seu catálogo de padrões de microsserviços
e no livro *Microservices Patterns* (2018); a ideia é mais velha que o nome.

O passo 2 tem o mesmo intervalo de todo consumidor das seções anteriores. **Se o relay publica e
para antes de marcar a linha como enviada, publica a mesma mensagem de novo quando reinicia.** O
outbox não remove duplicatas; ele transforma mensagens perdidas em mensagens duplicadas, que o
consumidor idempotente já sabe absorver. Por isso os dois andam juntos: o outbox torna o publicador
at-least-once, e o consumidor idempotente torna o at-least-once inofensivo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l10-outbox\" aria-label=\"Um diagrama de sequência com cinco linhas de vida: o portal, o banco do portal, o relay, a fila e o consumidor. O portal grava o pagamento e a linha de outbox portal-1 numa transação. O relay lê as linhas não enviadas e publica portal-1 na fila, e então para antes de marcá-la como enviada. Ao reiniciar, lê de novo as linhas não enviadas, encontra portal-1 ainda ali, publica-a uma segunda vez e a marca como enviada. A fila entrega as duas cópias ao consumidor, que aplica a primeira e pula a segunda porque o id dela já foi processado.\"><defs><marker id=\"l10-outbox-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-outbox-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"16.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"72.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">portal</text><path d=\"M72.0 40.0 L72.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"160.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">banco do portal</text><path d=\"M216.0 40.0 L216.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"304.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">relay</text><path d=\"M360.0 40.0 L360.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"448.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fila</text><path d=\"M504.0 40.0 L504.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"592.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consumidor</text><path d=\"M648.0 40.0 L648.0 352.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"144.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma transação</text><path d=\"M76.0 90.0 L210.0 90.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"144.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pagamento + portal-1</text><path d=\"M356.0 128.0 L222.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"288.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lê não enviadas</text><path d=\"M364.0 156.0 L498.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"432.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publica portal-1</text><path d=\"M353.0 175.0 L367.0 189.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M353.0 189.0 L367.0 175.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"376.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">para antes de marcar enviada</text><path d=\"M356.0 216.0 L222.0 216.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"288.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lê não enviadas: portal-1 de novo</text><path d=\"M364.0 244.0 L498.0 244.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-amber)\"></path><text x=\"432.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publica portal-1</text><path d=\"M356.0 272.0 L222.0 272.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"288.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">marca enviada</text><path d=\"M508.0 304.0 L642.0 304.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-phosphor)\"></path><text x=\"576.0\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal-1</text><text x=\"640.0\" y=\"318.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aplicada</text><path d=\"M508.0 340.0 L642.0 340.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-outbox-es-ah-amber)\"></path><text x=\"576.0\" y=\"331.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal-1</text><text x=\"640.0\" y=\"354.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pulada: processada</text></svg>", "caption": "O outbox transforma uma mensagem perdida numa mensagem duplicada, e o consumidor idempotente transforma a duplicata em nada. O id é fixado na linha do outbox, então as duas cópias levam o mesmo.", "same": ["portal", "portal-1", "relay"]}
```

Um detalhe decide se o consumidor consegue reconhecer a duplicata: **o id da mensagem é fixado
quando a linha do outbox é gravada, não quando o relay a envia.** Um relay que gerasse um id novo a
cada tentativa publicaria o mesmo pagamento com dois ids, e a tabela `processed` do consumidor
veria duas mensagens diferentes. A tabela de chaves naturais e ids de mensagem da seção anterior
supunha que o id pertencia ao fato; é aqui que isso se torna verdade.

## O programa

`outbox.py` é o lado do portal no exemplo de pagamentos. O comando `pay` grava um pagamento e a
mensagem dele no outbox numa transação; o comando `relay` publica o que estiver pendente. O broker
de novo é um arquivo, `queue.jsonl`, para que o consumidor da seção anterior possa ler o que o
relay publicou. Para encenar a falha de que esta seção trata, `relay --crash` para o relay depois
de publicar a primeira mensagem e antes de marcá-la como enviada, que é o que um deploy ou uma
queda de energia faz no momento errado.

Salve como `outbox.py` no mesmo diretório de `consumer.py`.

```schooling-example
{
  "language": "python",
  "file": "outbox.py",
  "parts": [
    {
      "code": "# outbox.py: record a payment and its message in one transaction; a relay publishes\nimport json\nimport sqlite3\nimport sys",
      "note": "Os mesmos três módulos de `consumer.py`. O banco do portal é outro arquivo, `portal.db`, porque publicador e consumidor nunca compartilham um."
    },
    {
      "code": "\ndb = sqlite3.connect(\"portal.db\")\ndb.executescript(\"\"\"\nCREATE TABLE IF NOT EXISTS payments (invoice TEXT PRIMARY KEY, customer TEXT, cents INTEGER);\nCREATE TABLE IF NOT EXISTS outbox (id INTEGER PRIMARY KEY, body TEXT, sent INTEGER DEFAULT 0);\n\"\"\")",
      "note": "`payments` é o dado de negócio do portal. `outbox` guarda cada mensagem exatamente como será publicada, e `sent` diz se o relay já terminou com ela."
    },
    {
      "code": "\n\ndef pay(invoice, customer, cents):\n    with db:  # the payment and the message about it commit together, or not at all\n        db.execute(\"INSERT INTO payments VALUES (?, ?, ?)\", (invoice, customer, cents))\n        row = db.execute(\"INSERT INTO outbox (body) VALUES ('')\").lastrowid\n        body = {\"id\": f\"portal-{row}\", \"invoice\": invoice, \"customer\": customer, \"cents\": cents}\n        db.execute(\"UPDATE outbox SET body = ? WHERE id = ?\", (json.dumps(body), row))\n    print(f\"recorded {invoice} with outbox message portal-{row}\")",
      "note": "Uma transação para o pagamento e sua mensagem. O id da mensagem vem do número da própria linha do outbox, então é fixado aqui, uma vez, e toda cópia posterior da mensagem leva o mesmo id."
    },
    {
      "code": "\n\ndef relay(crash):\n    pending = db.execute(\"SELECT id, body FROM outbox WHERE sent = 0 ORDER BY id\").fetchall()\n    for row, body in pending:\n        with open(\"queue.jsonl\", \"a\") as queue:  # the broker, for this example\n            queue.write(body + \"\\n\")\n        print(f\"published portal-{row}\")",
      "note": "O relay lê toda linha não enviada em ordem de id e a publica. O broker aqui é um arquivo que o consumidor consegue ler; com IBM MQ seria um put num tópico."
    },
    {
      "code": "        if crash:\n            sys.exit(f\"relay stopped before marking portal-{row} sent\")\n        with db:\n            db.execute(\"UPDATE outbox SET sent = 1 WHERE id = ?\", (row,))",
      "note": "A falha encenada, e depois a marca. `--crash` para o programa no único lugar que importa: depois da publicação e antes de a linha ser marcada como enviada. Um deploy ou uma queda de energia também podem pará-lo ali."
    },
    {
      "code": "\n\nif sys.argv[1] == \"pay\":\n    pay(sys.argv[2], sys.argv[3], int(sys.argv[4]))\nelse:\n    relay(crash=\"--crash\" in sys.argv)",
      "note": "Dois comandos: `pay` com uma nota, um cliente e um valor em centavos, e `relay`, com ou sem `--crash`."
    }
  ]
}
```

Grave dois pagamentos, rode o relay com a queda encenada, rode-o de novo como um reinício faria, e
veja o que chegou ao broker:

```
$ python3 outbox.py pay NF-18240 "Mercado Central" 48000
recorded NF-18240 with outbox message portal-1
$ python3 outbox.py pay NF-18241 "Casa Minas" 91050
recorded NF-18241 with outbox message portal-2
$ python3 outbox.py relay --crash
published portal-1
relay stopped before marking portal-1 sent
$ python3 outbox.py relay
published portal-1
published portal-2
$ cat queue.jsonl
{"id": "portal-1", "invoice": "NF-18240", "customer": "Mercado Central", "cents": 48000}
{"id": "portal-1", "invoice": "NF-18240", "customer": "Mercado Central", "cents": 48000}
{"id": "portal-2", "invoice": "NF-18241", "customer": "Casa Minas", "cents": 91050}
```

`portal-1` está na fila duas vezes: uma da execução que caiu e uma do reinício, que encontrou a
linha ainda não enviada. Nada se perdeu, e algo foi duplicado, exatamente como o outbox promete.
Agora entregue a fila ao consumidor da seção anterior, cujo razão já tem os três pagamentos dela:

```
$ python3 consumer.py queue.jsonl
paid NF-18240 for Mercado Central: R$ 480,00
skip portal-1: already processed
paid NF-18241 for Casa Minas: R$ 910,50
ledger: 5 payments, R$ 6.736,80
```

**O consumidor aplicou `portal-1` uma vez, pulou a cópia e aplicou `portal-2`.** O razão foi de
três pagamentos para cinco, não seis. As duas metades se encontraram: o outbox garantiu que os
pagamentos chegassem à fila, acontecesse o que acontecesse com o relay, e a tabela `processed`
garantiu que a repetição não mudasse nada.

## O relay na prática

O relay de `outbox.py` consulta a tabela: lê o que não foi enviado, publica, marca. É o relay mais
simples e muitas vezes basta. Custa uma consulta a cada poucos segundos e acrescenta até um
intervalo de consulta de latência, o que para o pedido de uma padaria não é nada.

A alternativa é ler o log de transações do banco em vez da tabela, a captura de mudanças de dados
que a aula 9 descreveu. O Debezium, por exemplo, tem um modo outbox que transforma as linhas
inseridas no outbox em mensagens publicadas. Não há consulta periódica e a latência é menor, e é
mais um componente para operar e monitorar. O portal da Serra Alta consulta a tabela; o ADR da
Joana diz que um requisito de latência abaixo de poucos segundos seria o motivo para mudar.

Três regras de operação completam o padrão:

- **Publique em ordem de id, a partir de um relay de cada vez.** Dois relays lendo a mesma tabela
  publicariam as mesmas linhas duas vezes como rotina, e poderiam publicá-las fora de ordem. Se um
  relay não der conta, divida o outbox para que cada relay seja dono de uma parte.
- **Apague as linhas enviadas num agendamento.** A tabela é um buffer, não um arquivo histórico; o
  portal guarda as linhas enviadas por sete dias, tempo suficiente para responder "foi publicada?"
  durante um incidente.
- **Ponha alarme na linha não enviada mais antiga.** Um relay parado parece exatamente um dia
  tranquilo. Uma linha do outbox com mais de cinco minutos quer dizer que o relay está parado ou que
  o broker a está recusando, e alguém deveria saber antes de uma padaria ligar.

A segunda-feira dos 47 pedidos é o motivo de o fluxo de pedidos do portal funcionar assim hoje.
Durante a janela de manutenção do SAP, todo domingo, os pedidos continuam esperando na fila; o que
mudou é que um pedido não pode mais existir no portal sem que a mensagem dele exista também.
