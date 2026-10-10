---
title: Mudar um contrato sem quebrá-lo
version: 1
---

**Depois que um cliente depende da sua API, toda mudança é segura ou incompatível, e qual das duas
ela é depende tanto de como o cliente lê quanto do que você mudou.** Um campo acrescentado a uma
resposta não quebra ninguém que ignora o que não pediu, e quebra todo cliente que recusa qualquer
coisa inesperada. A lição 1 deu às mudanças incompatíveis um número de versão; esta seção é sobre
precisar desse número menos vezes.

## O leitor tolerante

O jeito que parece cuidadoso de escrever um cliente é conferir se toda resposta tem exatamente a
forma esperada e falhar em qualquer outra coisa. Aqui está a ideia que esse cliente faz de um livro,
como um schema com `additionalProperties: false`, contra o livro real do catálogo:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1 > one.json
ana@api:~/shelf$ echo '{"type": "object", "required": ["id", "title"], "additionalProperties": false, "properties": {"id": {}, "title": {}}}' > strict.json
ana@api:~/shelf$ jsonschema -i one.json strict.json; echo "exit $?"
{'id': 1, 'isbn': '9786500000016', 'title': 'Dom Casmurro', 'author_id': 1, 'year': 1899, 'price': {'amount_cents': 3990, 'currency': 'BRL'}, 'stock': 12, 'in_stock': True}: Additional properties are not allowed ('author_id', 'in_stock', 'isbn', 'price', 'stock', 'year' were unexpected)
exit 1
```

Seis campos de que o cliente nunca precisou, e ele falha em todos; o próximo campo que o catálogo
acrescentar também o quebraria. A versão tolerante pede o que usa e ignora o resto:

```
ana@api:~/shelf$ echo '{"type": "object", "required": ["id", "title"], "properties": {"id": {}, "title": {}}}' > tolerant.json
ana@api:~/shelf$ jsonschema -i one.json tolerant.json; echo "exit $?"
exit 0
```

Esse é o **leitor tolerante**: leia os campos de que precisa, ignore os que não precisa, e trate um
valor de enum que nunca viu como "outra coisa". É a mesma palavra-chave do schema apontando para o
lado oposto ao da seção sobre validação. **Na entrada o servidor é rígido, porque um campo que ele
ignora é um erro do cliente que ele esconde; na saída o cliente é tolerante, porque um campo que ele
recusa é uma melhoria do servidor que ele transforma em pane.**

## O que quebra, e o que não quebra

| mudança | quebra um cliente tolerante? | por quê |
|---|---|---|
| acrescentar um campo a uma resposta | não | ele só lê o que precisa |
| acrescentar um campo opcional a uma requisição | não | clientes antigos não o enviam, e vale o padrão |
| acrescentar um endpoint, um filtro ou um campo de ordenação | não | nada antigo o usa |
| acrescentar um valor a um enum numa resposta | não, se o contrato disse que ele pode crescer | um cliente que listou todos os valores falha no novo |
| remover ou renomear um campo | **sim** | quem o lia passa a não ler nada |
| mudar o tipo de um campo | **sim** | a versão 2 da lição 1 fez isso com o preço |
| tornar obrigatório um campo opcional da requisição | **sim** | clientes antigos nunca o enviam |
| apertar a validação, como um `maxLength` menor | **sim** | requisições que eram aceitas passam a ser recusadas |
| mudar o `type` de um erro | **sim** | os clientes decidem por ele |
| mudar o que um campo significa, mantendo nome e tipo | **sim, em silêncio** | todo cliente passa a estar errado e nenhum falha |

**A última linha é a pior, porque nada a denuncia.** Digamos que `in_stock` passe a significar "pode
ser enviado hoje" em vez de "pelo menos um exemplar". Toda resposta continua sendo um booleano no
lugar certo; o schema passa, os testes passam, e todo cliente age sobre um fato que mudou por baixo
dele. Um significado novo ganha um nome novo, `ships_today`, e o campo antigo mantém o significado
antigo até ser aposentado do jeito que a lição 1 aposenta uma versão.

## O contrato é o que os clientes usam

Um contrato não é só o que a documentação diz. A observação de Hyrum Wright, conhecida como lei de
Hyrum, é que, com usuários suficientes, todo comportamento observável de uma API vira dependência de
alguém: a ordem de uma lista que ninguém prometeu ordenar, o texto de um `detail`, quanto tempo uma
requisição leva. Então, antes de uma mudança, a pergunta útil não é "documentamos isso?" mas "alguém
lê isso?", e o jeito confiável de saber é perguntar aos clientes, ou fazer com que eles escrevam o
que usam. Isso se chama design **orientado ao consumidor** e, quando as expectativas dos clientes
viram testes que rodam contra o servidor, teste de contrato orientado ao consumidor.

Dois hábitos deixam as mudanças mais seguras, e o resto do curso usa os dois. A lição 6 escreve o
contrato inteiro como um documento OpenAPI, que uma ferramenta consegue comparar entre duas versões
para apontar as linhas da tabela acima. E quando uma mudança incompatível não pode ser evitada, ela
sai como uma versão nova, ao lado da antiga, como a lição 1 mostrou.
