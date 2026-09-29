---
title: Chamando no notebook
version: 1
---

Um handler é uma função comum de Python, então dá para chamá-lo como uma. **É o teste mais barato que
existe, e ele mostra exatamente uma coisa: o contrato entre a plataforma e o seu código.** O Lambda
não participa de nada nesta página. Não há conta, rede nem ambiente de execução, só um processo
Python num notebook importando `handler.py` e passando para ele um dicionário escrito à mão.

O `call_local.py` escreve um evento com alguns campos do que um API gateway HTTP manda, o bastante
para este handler. A segunda
chamada passa um evento sem query string nenhuma, o caso para o qual o `or {}` existe:

```python
from handler import handler

event = {
    "rawPath": "/hello",
    "queryStringParameters": {"name": "ana"},
    "requestContext": {"http": {"method": "GET"}},
}
print(handler(event, None))
print(handler({"rawPath": "/hello"}, None))
```

O `None` faz o papel do context, que este handler nunca lê. Rodando a partir da pasta que tem os dois
arquivos:

```
ana@laptop:~/cloud$ python3 call_local.py
{'statusCode': 200, 'headers': {'Content-Type': 'application/json'}, 'body': '{"message": "hello, ana", "served_by_this_copy": 1}'}
{'statusCode': 200, 'headers': {'Content-Type': 'application/json'}, 'body': '{"message": "hello, world", "served_by_this_copy": 2}'}
```

**O valor devolvido é a resposta inteira, antes de qualquer gateway mexer nela.** `statusCode` vira a
linha de status, `headers` os cabeçalhos, e `body` é uma string com JSON dentro. O Python imprime o
dict com aspas simples; o corpo dentro dele tem aspas duplas, porque quem o escreveu foi o
`json.dumps`.

A segunda chamada respondeu `world`, que é o valor padrão fazendo o seu trabalho. O contador diz
`2`. **As duas chamadas rodaram no mesmo processo Python, então dividiram o módulo e o contador.**
Na plataforma não existe essa promessa: a segunda requisição poderia ter ido para outro ambiente de
execução e ser respondida com `1`. **O notebook mostra o caso mais otimista**, uma cópia quente
atendendo tudo, e nada nele consegue mostrar o outro.

O que este teste não diz:

- se o evento real se parece com o que você escreveu. Um gateway manda muitos outros campos, e o
  formato exato depende do tipo de gateway e da versão dele; os campos que o seu handler lê são os que
  você confere na documentação do provedor;
- nada sobre permissões, timeout, memória, cold starts ou concorrência, que só existem na plataforma;
- se o gateway está configurado para mandar a requisição a este handler.

**O que ele diz é se a lógica está certa**, e ele roda em qualquer framework de testes, porque para
o `pytest` um handler é uma função como outra qualquer. Existem ferramentas que chegam mais perto do
real: a linha de comando SAM da AWS, por exemplo, roda um handler dentro de um contêiner feito para
imitar o ambiente do Lambda. Continua sendo uma imitação, e este curso não a usa.
