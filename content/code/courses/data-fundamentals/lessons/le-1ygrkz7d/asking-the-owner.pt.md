---
title: Perguntar ao dono, e anotar as respostas
version: 1
---

**Toda falha desta aula foi uma pergunta que ninguém fez ao dono da fonte antes da primeira cópia.** A
viagem apagada, o arquivo carregado pela metade, o evento reenviado, o relógio adiantado: cada um tem
uma resposta que o dono já sabia, e cada um foi descoberto aqui dando de cara com ele. Perguntar antes
sai mais barato, e as perguntas são quase as mesmas para todo tipo de fonte.

| pergunte ao dono | por causa de |
|---|---|
| O que é uma linha, ou um evento? O que o identifica? | duplicatas só se removem por um identificador |
| Como uma remoção é registrada, se for? | uma cópia incremental não vê uma linha que sumiu |
| Que coluna muda a cada mudança, e quem a preenche? | `updated_at` só vale o código que o escreve |
| Como sei que uma entrega está completa? | um arquivo ainda sendo escrito parece pronto |
| Como posso ler: de onde, em que ritmo, em que horário? | o primário, o limite de taxa, o horário calmo |
| Ela pode mandar a mesma coisa duas vezes? | entrega pelo menos uma vez, dos celulares e das docas |
| De que relógio vem o horário, e em que fuso? | o relógio do celular, o do sensor, a diferença no log |
| Que campos são dados pessoais? | um endereço IP é um, e um id de cliente também |
| Como vou saber de uma mudança antes de ela entrar? | um campo renomeado não faz nada falhar no dia em que chega |

A última pergunta é a que mais pesa ao longo de um ano. Toda outra resposta é verdadeira no dia em que é
dada e só continua verdadeira até o dono mudar alguma coisa. **Uma fonte que muda sem aviso é uma fonte
que você lê por sua conta e risco**, por mais cuidado que tenha ao lê-la hoje.

## Um contrato de dados

Quando as respostas são escritas, aceitas pelos dois lados e conferidas por um programa, elas se chamam
**contrato de dados**. A aula 2 contou os contratos entre as coisas de que um engenheiro de dados
cuida; isto é o que um contém. Não é um documento jurídico. É a promessa de quem produz sobre a forma e o
comportamento dos dados, com um dono com nome e uma regra para mudanças. Para as leituras das docas,
ele poderia dizer:

```json
{
  "dataset": "dock_readings",
  "owner": "operations, with the sensor vendor",
  "key": ["sensor_id", "seq"],
  "fields": {
    "sensor_id": {"type": "string", "example": "ST02-D02"},
    "seq": {"type": "integer", "rule": "one more than the sensor's previous reading"},
    "stamped_at": {"type": "timestamp", "rule": "the sensor's clock, synchronised by NTP"},
    "received_at": {"type": "timestamp", "rule": "the vendor's server clock, in UTC"},
    "has_bike": {"type": "boolean"}
  },
  "delivery": "at least once; duplicates share sensor_id and seq",
  "expected": "one reading per sensor per minute",
  "personal_data": "none",
  "changes": "announced 30 days ahead; a removed or renamed field is a new version"
}
```

Não existe um formato padrão único para um contrato, e os times os escrevem em JSON, em YAML ou numa
página de wiki. O que o torna um contrato é algo conferi-lo. A linha `key` é a verificação de
duplicatas, a linha `expected` é a contagem de lacunas, e a linha `changes` é o aviso que a última
pergunta pedia. A aula 7 roda verificações assim na chegada, e `data-cleaning` as leva muito mais longe.

O dono pode dizer não a uma parte. O fornecedor pode se recusar a numerar as leituras, ou o time do app
pode continuar apagando viagens canceladas. Aí a resposta vai para o contrato do mesmo jeito, como uma
lacuna conhecida, para que quem construir sobre os dados no ano que vem a encontre escrita em vez de
descobri-la do jeito que esta aula descobriu.
