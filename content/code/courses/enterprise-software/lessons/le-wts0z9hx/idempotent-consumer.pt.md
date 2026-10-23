---
title: O consumidor idempotente
version: 1
---

O primeiro instinto quando aparecem duplicatas é impedir o broker de mandá-las. A seção anterior
mostrou por que isso não dá: a duplicata nasce no intervalo entre o trabalho e a confirmação, e
nenhuma configuração do broker fecha um intervalo que está no seu programa. **A correção é do
consumidor: fazer com que tratar a mesma mensagem duas vezes deixe o mesmo estado que tratá-la uma
vez.** Uma operação com essa propriedade é **idempotente**, e Hohpe e Woolf (2003) chamam um
consumidor construído assim de Idempotent Receiver.

## Algumas operações já são

Olhe o que uma mensagem pede ao consumidor. Algumas operações são idempotentes por natureza:

- "O preço da manteiga 200 g agora é R$ 12,00." Gravar um valor duas vezes deixa o mesmo valor.
- "O pedido 4711 está cancelado." Um pedido cancelado, cancelado de novo, continua cancelado.
- "Apague o endereço de entrega de id 88." A segunda exclusão não acha nada e não faz nada.

Outras não são, e são as que custam dinheiro:

- "Some R$ 3.480,90 aos pagamentos do Mercado Central." Duas vezes são R$ 6.961,80.
- "Lance uma entrada de mercadoria de 4.120 litros da fazenda 10233." Duas vezes pagam à fazenda
  um leite que ela não entregou.
- "Mande o certificado de análise para o cliente." Duas vezes é um constrangimento, e cem vezes é
  uma reclamação.

Então a primeira pergunta sobre um consumidor é de que tipo são as mensagens dele. **Uma mensagem
que informa um valor novo é mais segura que uma mensagem que informa uma mudança**, e onde você
mesmo desenha a mensagem, prefira a primeira. A última seção desta aula volta a isso, porque um
valor informado também é o que torna a ordem administrável.

Quando a operação não é idempotente por natureza, o consumidor a torna idempotente lembrando o que
já fez.

## Lembre o id, na mesma transação

Toda mensagem leva um id dado pelo publicador. O consumidor mantém uma tabela dos ids que já
processou, e trata uma mensagem em três passos dentro de **uma transação de banco**: registrar o
id, fazer o trabalho, confirmar. Se o id já está na tabela, a mensagem é uma repetição e o
consumidor não faz nada além de confirmá-la ao broker.

As palavras *uma transação* carregam o desenho. Veja os outros dois arranjos:

- Registrar o id numa transação própria **depois** do trabalho. Uma queda entre os dois commits
  deixa o trabalho feito e o id faltando, e a mensagem reentregue é processada de novo.
- Registrar o id **antes** do trabalho, numa transação própria. Uma queda entre os dois deixa o id
  registrado e o trabalho nunca feito, e a reentrega é pulada: a mensagem se perde, o que é
  at-most-once por um caminho mais longo.

Só quando as duas escritas são confirmadas juntas não existe um momento em que uma é verdade e a
outra não.

## O programa

O programa abaixo é o consumidor das mensagens `invoice.paid` da Serra Alta, reduzido ao que esta
seção trata. Ele mantém um razão de pagamentos em SQLite, que faz parte da biblioteca padrão do
Python, então não há nada para instalar. Rodar é opcional; ler o programa e a saída basta para
acompanhar a aula, e a aula 1 diz onde rodar os programas deste curso.

Primeiro as mensagens. Um consumidor de verdade as lê de um broker; este lê um arquivo com uma
mensagem JSON por linha, o que deixa você reentregar uma mensagem à mão. Este script curto escreve
dois arquivos: três mensagens, e uma cópia só da segunda:

```sh
# make-messages.sh: three "invoice paid" messages, then the second one again
cat > first.jsonl <<'END'
{"id": "m-1", "invoice": "NF-18231", "customer": "Padaria Estrela", "cents": 125000}
{"id": "m-2", "invoice": "NF-18232", "customer": "Mercado Central", "cents": 348090}
{"id": "m-3", "invoice": "NF-18233", "customer": "Padaria Nova", "cents": 61540}
END
grep '"m-2"' first.jsonl > again.jsonl
```

Os ids aqui foram escritos à mão. Na próxima seção eles vêm do banco do próprio publicador, que é o
lugar deles. Valores são centavos inteiros, nunca uma fração: R$ 1.250,00 viaja como `125000`.

Salve o consumidor ao lado do script como `consumer.py`. As notas dizem para que serve cada parte;
o botão de copiar leva o programa sem elas.

```schooling-example
{
  "language": "python",
  "file": "consumer.py",
  "parts": [
    {
      "code": "# consumer.py: apply \"invoice paid\" messages to a ledger, each one once\nimport json\nimport sqlite3\nimport sys",
      "note": "Três módulos da biblioteca padrão e nada para instalar. `sqlite3` é um banco de dados inteiro num arquivo, e é tudo de que este exemplo precisa."
    },
    {
      "code": "\ndb = sqlite3.connect(\"ledger.db\")\ndb.executescript(\"\"\"\nCREATE TABLE IF NOT EXISTS ledger (invoice TEXT, customer TEXT, cents INTEGER);\nCREATE TABLE IF NOT EXISTS processed (message_id TEXT PRIMARY KEY);\n\"\"\")",
      "note": "Duas tabelas. `ledger` é o trabalho: uma linha por pagamento recebido. `processed` é a memória: uma linha por mensagem tratada, e a chave primária recusa o mesmo id duas vezes. A primeira execução cria `ledger.db`; as seguintes o reaproveitam."
    },
    {
      "code": "\n\ndef brl(cents):\n    return f\"R$ {cents // 100:,}\".replace(\",\", \".\") + f\",{cents % 100:02d}\"",
      "note": "O dinheiro fica em centavos inteiros e só é formatado para uma pessoa ler, do jeito brasileiro: `125000` vira `R$ 1.250,00`. Nenhum float encosta nele."
    },
    {
      "code": "\n\ndef handle(message):\n    with db:  # one transaction: both rows are written, or neither is\n        try:\n            db.execute(\"INSERT INTO processed VALUES (?)\", (message[\"id\"],))\n        except sqlite3.IntegrityError:\n            print(f\"skip {message['id']}: already processed\")\n            return",
      "note": "O coração do programa. `with db:` abre uma transação e a confirma no fim do bloco, ou a desfaz se algo levantar exceção. O id entra primeiro, sem pergunta antes: se a chave primária o recusar, essa mensagem já foi tratada, e o consumidor não grava nada."
    },
    {
      "code": "        db.execute(\"INSERT INTO ledger VALUES (?, ?, ?)\",\n                   (message[\"invoice\"], message[\"customer\"], message[\"cents\"]))\n        print(f\"paid {message['invoice']} for {message['customer']}: {brl(message['cents'])}\")",
      "note": "O trabalho, dentro da mesma transação do id. As duas linhas são confirmadas juntas, então não existe um momento em que o pagamento está gravado e o id não, nem o contrário."
    },
    {
      "code": "\n\nfor line in open(sys.argv[1]):\n    handle(json.loads(line))\ncount, total = db.execute(\"SELECT count(*), sum(cents) FROM ledger\").fetchone()\nprint(f\"ledger: {count} payments, {brl(total)}\")",
      "note": "Uma mensagem por linha do arquivo passado na linha de comando, e depois o estado do razão. Com um broker de verdade, a confirmação seria enviada aqui, depois que `handle` retorna: primeiro o trabalho, depois a confirmação."
    }
  ]
}
```

Rode o script, depois entregue ao consumidor as três mensagens, depois a repetição. No Windows o
comando é `python` em vez de `python3`, e os dois arquivos `.jsonl` podem ser escritos em qualquer
editor.

```
$ sh make-messages.sh
$ python3 consumer.py first.jsonl
paid NF-18231 for Padaria Estrela: R$ 1.250,00
paid NF-18232 for Mercado Central: R$ 3.480,90
paid NF-18233 for Padaria Nova: R$ 615,40
ledger: 3 payments, R$ 5.346,30
$ python3 consumer.py again.jsonl
skip m-2: already processed
ledger: 3 payments, R$ 5.346,30
```

A segunda execução é a reentrega que a seção anterior disse que viria. **O consumidor reconheceu
`m-2`, não gravou nada, e o razão continua com três pagamentos e o mesmo total.** Sem a tabela
`processed`, a segunda execução teria inserido o pagamento de novo, e os R$ 3.480,90 do Mercado
Central teriam sido contados duas vezes.

## Por que "conferir, depois inserir" não basta

Uma primeira versão natural pergunta antes de agir:

```python
seen = db.execute("SELECT 1 FROM processed WHERE message_id = ?", (msg["id"],)).fetchone()
if not seen:
    apply_payment(msg)
    db.execute("INSERT INTO processed VALUES (?)", (msg["id"],))
```

Ela passa em todo teste rodado com um consumidor, e falha exatamente no caso que produz
duplicatas. Duas instâncias do consumidor leem a mesma fila. A instância A pega `m-2` e está lenta;
o timeout do broker vence e a instância B também recebe `m-2`. As duas rodam o `SELECT`, as duas
não acham nada, porque nenhuma confirmou ainda, e as duas aplicam o pagamento. Conferir e inserir
são dois passos, e outro consumidor pode agir entre eles.

`consumer.py` nunca pergunta. Ele insere o id e deixa a **chave primária** recusar uma segunda
cópia. O banco é o único lugar onde as duas instâncias se encontram, e uma restrição de unicidade é
o jeito dele de dizer "só um de vocês": a transação que inserir em segundo lugar falha, é desfeita
e não grava nada. **A restrição não precisa que os consumidores combinem nada; ela decide por
eles.**

## Chave natural ou id da mensagem

A tabela `processed` lembra *mensagens*. Às vezes o próprio fato de negócio tem uma identidade que
faz o mesmo papel, uma **chave natural**. Uma NF-e tem uma chave de acesso de 44 dígitos e é
autorizada uma vez; um consumidor que guarda registros de NF-e pode pôr uma restrição de unicidade
na chave de acesso e ignorar qualquer segunda mensagem sobre a mesma nota, seja qual for o id da
mensagem.

As duas falham em lugares diferentes, e a escolha depende de qual falha é possível:

| | impede | falha quando |
|---|---|---|
| id da mensagem | a mesma mensagem entregue duas vezes | o publicador manda o mesmo fato duas vezes com dois ids, por exemplo uma pessoa reenviando pelo console |
| chave natural | qualquer segunda mensagem sobre o mesmo fato | o fato pode legitimamente acontecer duas vezes: uma padaria pagando a nota NF-18232 em duas parcelas são dois pagamentos com um número de nota |

`consumer.py` usa o id da mensagem porque um pagamento não é único por nota. Para a autorização de
uma NF-e, a chave natural é melhor. **Use a chave natural onde o negócio diz que o fato acontece
uma vez, e o id da mensagem em todo o resto.** Depois garanta que o publicador fixe o id quando o
fato é registrado, não quando a mensagem é enviada, que é o assunto da próxima seção.

## O que a transação não cobre

O truque funciona porque o razão e a tabela `processed` estão no mesmo banco. Quando o trabalho
está em outro lugar, uma chamada ao SAP ou um e-mail, não há transação compartilhada. Duas
respostas, em ordem de preferência:

1. **Repasse o id.** Muitas APIs aceitam uma chave de idempotência junto com a requisição e
   devolvem o primeiro resultado a uma repetição; a API de pagamentos do Stripe é o exemplo
   conhecido. O consumidor manda o id da mensagem como essa chave, e a duplicata é absorvida um
   sistema adiante.
2. **Registre a tentativa e aceite a repetição rara.** Para um e-mail, registre o id antes de
   mandar e aceite que uma queda no momento errado significa um e-mail perdido ou mandado duas
   vezes. Escolha qual, de propósito, e escreva.

Por último, a tabela `processed` cresce uma linha por mensagem. Guarde os ids por mais tempo do que
qualquer reentrega poderia levar, incluindo uma reprodução a partir de uma fila de mensagens mortas
semanas depois (duas seções adiante), e apague os mais antigos num agendamento. A Serra Alta os
guarda por 90 dias.
