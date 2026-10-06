---
title: Filtros
version: 1
---

Algumas perguntas sobre quais pedaços devolver não têm nada a ver com significado. *Esta política ainda
está em vigor?* *Esta pessoa pode lê-la?* *Está no idioma do leitor?* Nenhuma nota de similaridade
responde a isso, e a aula 5 guardou as respostas ao lado de cada pedaço exatamente para este momento. Um
**filtro** é uma condição sobre esses metadados, aplicada como parte da busca.

## O regulamento substituído, uma última vez

```
ana@lab:~/rag$ python show.py vector "Who pays for the return postage?"
1    0.806  Returns policy > Return postage  | Return postage is paid by the customer. You can 
2    0.537  Returns and refunds policy > How to start a return  | 1. Open the order in your account and choose Ret
3    0.514  Returns and refunds policy > How to start a return  | Returns are free. You do not pay for the label, 
4    0.508  Returns and refunds policy > Gifts  | The person who received a gift can return it wit
5    0.502  Shipping and delivery > Damage in transit  | If a parcel arrives visibly damaged, you may ref
```

A *Return postage* do regulamento de 2025 está em primeiro, com 0,806, como está desde a aula 1. Todo
método desta aula a manteria ali: é o pedaço mais relevante do índice. A relevância não é o problema. O
problema é que um cliente nunca deveria ver uma política substituída como se estivesse em vigor, e isso
é uma regra, não uma nota.

```
ana@lab:~/rag$ python -c "from search import vector; [print(r[1]) for r in vector(\"Who pays for the return postage?\", 3, \"status = %s AND audience = %s\", (\"current\", \"public\"))]"
Returns and refunds policy > How to start a return
Returns and refunds policy > How to start a return
Returns and refunds policy > Gifts
```

**Com `status = 'current' AND audience = 'public'` na consulta, o regulamento de 2025 não pode ser
devolvido, e *How to start a return* vem em primeiro**, a seção cujo segundo pedaço diz *Returns are
free*. O filtro vai para o `WHERE` do SQL, ao lado da ordenação por distância, e os valores viajam como
parâmetros, nunca colados na string.

## Onde o filtro pertence

O filtro faz parte da busca, não é um passo depois dela. Jogar fora as linhas substituídas *depois* de
buscar as três primeiras teria deixado dois pedaços; buscar mais para compensar é adivinhar quantos
serão jogados fora. Dentro da consulta, o PostgreSQL devolve três linhas que passam.

Com um índice HNSW há um porém, visto na aula 5: o índice acha primeiro as linhas próximas e o filtro
tira algumas depois, então um filtro estrito pode devolver menos linhas que o `LIMIT`. A aula 17 do
`embeddings-vectors` mediu isso e os remédios, índices parciais e busca exata sobre o subconjunto
filtrado. A tabela desta aula não tem índice HNSW, já que o `ingest.py` não constrói um, então toda busca
aqui é exata sobre as linhas que passam.

## O que esta aula cobre e o que não cobre

Esta aula filtra por uma constante: toda busca aqui é de um cliente, então `current` e `public` estão
sempre certos. A parte difícil, decidir o filtro a partir de **quem está perguntando**, com um atendente
vendo o manual de atendimento e um cliente não, e o banco garantindo isso em vez da aplicação, é a aula
14. A regra para as duas é a que a aula 2 tirou do vazamento do financeiro: **um filtro é decidido pelo
sistema, a partir do que ele sabe sobre o leitor, e nunca pela pergunta.** Um usuário que digita *inclua
os documentos do financeiro* numa caixa de busca não pediu nada que o sistema deva conceder.
