---
title: Um schema diz o que é uma resposta válida
version: 1
---

A lição 18 parou numa pergunta: a resposta é lida pelo parser? Isso é necessário e está longe de
bastar. Uma resposta pode ser um JSON perfeito com uma categoria que ninguém listou, um booleano
escrito como a palavra `"no"`, e sem o campo de que o seu programa mais precisa. **Um parser
confere a sintaxe; um schema confere a forma.**

Um **JSON Schema** é um documento JSON que descreve os objetos que você aceita: quais campos, de
quais tipos, com quais valores, e quais deles são obrigatórios. É um padrão publicado, e há
bibliotecas que conferem dados contra ele em todas as linguagens comuns. Na bancada, o `validate`
usa a biblioteca `jsonschema` do Python.

## Um schema para triar reclamações

O Café Aurora quer cada reclamação classificada antes que uma pessoa a leia: de que tipo é, se cabe
reembolso e de quanto, e um resumo de uma linha curto o bastante para a lista do gerente. Este é o
schema:

```
ana@lab:~/pe$ cat schema.json
{
  "type": "object",
  "properties": {
    "category": {"enum": ["wrong_item", "cold_or_late", "allergen", "billing", "other"]},
    "refund": {"type": "boolean"},
    "refund_amount": {"type": "number", "minimum": 0},
    "summary": {"type": "string", "maxLength": 80}
  },
  "required": ["category", "refund", "summary"],
  "additionalProperties": false
}
```

Leia de cima para baixo. A resposta inteira é um `object`. A `category` é uma de cinco palavras, e
a lista é tudo o que é permitido: `enum` quer dizer exatamente estas. `refund` é um booleano, `true`
ou `false`. `refund_amount` é um número não menor que zero. `summary` é uma string de no máximo 80
caracteres. Três campos são `required`, e **`additionalProperties: false` recusa qualquer campo que
o schema não nomeou**.

Cada uma dessas linhas é uma decisão sobre o programa que usa a resposta. As categorias são as
cinco filas que o café tem. Os 80 caracteres são o que cabe numa linha da lista do gerente. O
`refund_amount` é opcional, porque uma reclamação sem reembolso não tem valor a devolver.

## Uma resposta válida

```
ana@lab:~/pe$ cat triage/good.json
{"category": "cold_or_late", "refund": false, "summary": "Waited fifteen minutes for a tea at noon; staff were kind."}
ana@lab:~/pe$ validate schema.json triage/good.json; echo "exit $?"
valid
exit 0
```

`valid`, e código de saída `0`. O programa agora pode ler `category` sabendo que é uma de cinco
palavras, e ler `refund` sabendo que é um booleano.

## Duas inválidas, e o que o validador diz

```
ana@lab:~/pe$ cat triage/bad-1.json
{"category": "slow service", "refund": "no", "summary": "The customer waited fifteen minutes for a tea at noon, which is too long, although the staff were kind about it."}
ana@lab:~/pe$ validate schema.json triage/bad-1.json; echo "exit $?"
category: 'slow service' is not one of ['wrong_item', 'cold_or_late', 'allergen', 'billing', 'other']
refund: 'no' is not of type 'boolean'
summary: 'The customer waited fifteen minutes for a tea at noon, which is too long, although the staff were kind about it.' is too long
3 problems
exit 1
```

Três problemas, cada um na sua linha, **cada um começando pelo caminho até o campo de que trata**.
Compare com a lição 18, em que um parser parava no primeiro problema e apontava uma linha e uma
coluna. Um validador percorre o objeto inteiro e informa tudo, porque já o leu. As mensagens são
específicas o bastante para agir: `'slow service'` não está na lista, `'no'` é uma string onde cabe
um booleano, e o resumo é longo demais.

```
ana@lab:~/pe$ cat triage/bad-2.json
{"category": "cold_or_late", "refund": false, "mood": "annoyed"}
ana@lab:~/pe$ validate schema.json triage/bad-2.json; echo "exit $?"
(top level): 'summary' is a required property
(top level): Additional properties are not allowed ('mood' was unexpected)
2 problems
exit 1
```

`(top level)` é o caminho de um problema com o próprio objeto, e não com um campo dele. A resposta
deixou de fora `summary`, que é obrigatório, e acrescentou `mood`, que o schema nunca nomeou. Sem
`additionalProperties: false` a segunda linha não apareceria, e um programa carregaria um campo
inesperado sem ninguém ter decidido que ele deveria.

## Onde o schema entra

O schema é escrito uma vez e usado duas. **Ele vai no prompt**, ou ao lado dele, para que o modelo
saiba a forma que se pede; isso troca a lista de campos em prosa da lição 18 por algo exato. **E ele
vai no programa**, que confere cada resposta contra o mesmo documento. Uma mudança nas categorias é
então uma edição só, e o prompt e a conferência não têm como se desencontrar.

Um schema não diz tudo. Ele confere tipos, valores permitidos, tamanhos, faixas e presença. Ele não
consegue conferir se o resumo descreve a reclamação, ou se o reembolso tem o valor certo para ela.
Esses são o assunto da última seção de leitura desta lição.
