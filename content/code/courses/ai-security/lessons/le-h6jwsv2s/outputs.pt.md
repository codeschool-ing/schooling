---
title: Um schema entre o modelo e todo o resto
version: 1
---

A entrada pede ao modelo um objeto JSON, e o prompt diz quais campos incluir. **Um prompt é um pedido,
e a resposta é o que o modelo escreveu**, que costuma ser o que foi pedido e às vezes não é. O código
que lê a resposta precisa saber em qual caso está antes de fazer qualquer coisa com ela, e um schema é
como ele sabe. O da Tarefa está em `data/output-schema.json`:

```
ana@lab:~/guard$ cat data/output-schema.json
{
 "type": "object",
 "additionalProperties": false,
 "required": [
  "category",
  "title",
  "summary",
  "price_suggestion_cents",
  "skills"
 ],
 "properties": {
  "category": {
   "enum": [
    "design",
    "development",
    "writing",
    "translation",
    "marketing"
   ]
  },
  "title": {
   "type": "string",
   "maxLength": 80
  },
  "summary": {
   "type": "string",
   "maxLength": 400
  },
  "price_suggestion_cents": {
   "type": "integer",
   "minimum": 5000,
   "maximum": 5000000
  },
  "skills": {
   "type": "array",
   "maxItems": 5,
   "items": {
    "type": "string",
    "maxLength": 30
   }
  },
  "links": {
   "type": "array",
   "maxItems": 3,
   "items": {
    "type": "string",
    "pattern": "^https://"
   }
  }
 }
}
```

`additionalProperties: false` recusa um campo que o schema não nomeia, `enum` fecha a categoria, os
tamanhos e as contagens de itens limitam quanto texto chega à tela, e o preço precisa ser um inteiro
dentro de uma faixa. O `guardlab/shapes.py` confere exatamente essas palavras-chave, escritas com a
biblioteca padrão para que cada regra possa ser lida; numa aplicação real, uma biblioteca de JSON
Schema mantida por alguém faz o mesmo trabalho.

As respostas em `data/outputs.jsonl` **foram escritas pelo curso**, uma para passar e seis para serem
pegas por regras diferentes. Nenhum modelo as produziu. Eis a que passa, e a primeira que não passa:

```
ana@lab:~/guard$ guard check-out data/outputs.jsonl --id out-1 --show
{"category": "design", "title": "Logo for a bakery in Recife", "summary": "A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.", "price_suggestion_cents": 150000, "skills": ["logo design", "branding", "print"], "links": ["https://help.tarefa.example/pricing/logos"]}
out-1  ok
ana@lab:~/guard$ guard check-out data/outputs.jsonl --id out-2 --show
Sure! Here is the JSON you asked for:
{"category": "design", "title": "Logo for a bakery in Recife", "summary": "A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.", "price_suggestion_cents": 150000, "skills": ["logo design", "branding", "print"], "links": ["https://help.tarefa.example/pricing/logos"]}
out-2  REJECT  not JSON: Expecting value at character 0
```

O `out-2` é o JSON do `out-1` com uma frase simpática na frente. O conserto tentador é procurar a
primeira `{` na resposta e interpretar dali, e é um mau conserto: um parser que cava JSON no meio do
texto aceita qualquer coisa que contenha um objeto em algum lugar, inclusive uma resposta que diz outra
coisa inteiramente em volta dele. Recuse e peça de novo. Muitos fornecedores também oferecem um modo de
saída estruturada que restringe a resposta a JSON válido, ou a um schema dado, enquanto ela é gerada,
e vale ligá-lo. Ele resolve o formato, e **os valores dentro de uma resposta bem formada ainda precisam
ser conferidos**, que é o assunto das outras cinco respostas:

```
ana@lab:~/guard$ guard check-out data/outputs.jsonl
out-1  ok
out-2  REJECT  not JSON: Expecting value at character 0
out-3  REJECT  $.category: 'illustration' is not one of design, development, writing, translation, marketing
out-4  REJECT  $: 'internal_notes' is not allowed
out-5  REJECT  $.price_suggestion_cents: 990000 is more than twice the budget of 120000
out-6  REJECT  $.links[1]: host pay-tarefa.example is not on the allowlist
out-7  REJECT  $.summary: 607 characters, limit 400
               $.skills: 7 items, limit 5
ana@lab:~/guard$ cat data/allowed-hosts.json
["tarefa.example", "help.tarefa.example"]
```

## O que cada recusa teria feito se passasse

- O `out-3` inventou a categoria `illustration`. O código que encaminha um trabalho pela categoria não
  tem ramo para ela, então o trabalho cai no que o ramo padrão fizer, ou em lugar nenhum.
- O `out-4` acrescentou `internal_notes` dizendo que o cliente *parece rico*. Sem
  `additionalProperties: false`, um template que desenha todo campo teria mostrado isso ao cliente.
- O `out-5` sugere R$ 9.900,00 para um trabalho com orçamento de R$ 1.200,00. Cada campo é válido
  sozinho, e o schema o deixa passar. **Um schema confere cada valor por si**, então uma regra que
  relaciona dois valores, aqui o preço e o orçamento, é escrita em código depois do schema.
- O `out-6` tem um link para `pay-tarefa.example`, um host que parece o da Tarefa e não é. O padrão
  `^https://` o deixa passar, porque o problema é o host e não o esquema; só uma lista de hosts
  permitidos o pega. Um modelo pode produzir um link assim porque o leu no material que recebeu, ou
  porque o inventou, e nos dois casos o cliente veria uma página de pagamento no domínio de outra
  pessoa.
- O `out-7` tem um resumo de 607 caracteres e sete habilidades. Nada nele é nocivo, e ele quebraria o
  layout de toda tela que o mostra.

Toda recusa nomeia o caminho e a regra. Essa mensagem é para quem desenvolve e lê o log, e, na próxima
seção, para o modelo a quem se pede de novo.
