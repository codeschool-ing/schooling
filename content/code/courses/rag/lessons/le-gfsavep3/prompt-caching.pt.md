---
title: Cache de prompt
version: 1
---

Os caches até aqui pulam o modelo. O **cache de prompt** mantém o modelo e torna parte do prompt mais
barata: o provedor guarda a forma processada de um prefixo longo que se repete entre requisições, e uma
requisição que começa com o mesmo prefixo paga menos por ele e começa mais rápido. A API da OpenAI faz isso
automaticamente para prompts longos; a da Anthropic deixa a requisição marcar onde termina o prefixo que
pode ir para o cache, com `cache_control`. O labgen imita a segunda, com um prefixo mínimo de 1.024
tokens e uma vida de cinco minutos.

As instruções da aula 7 têm 71 tokens, muito abaixo de qualquer mínimo, então este pipeline não ganha
nada com isso. O caso em que ajuda é um **prefixo longo e fixo**, e um comum é um conjunto de documentos
que o assistente sempre tem, as políticas centrais, mandadas antes de toda pergunta:

```
ana@lab:~/rag$ python cached_prompt.py
How much is express delivery?
  input 7, written to cache 2697, read from cache 0, output 40
How many days do I have to return a printed book?
  input 13, written to cache 0, read from cache 2697, output 86
```

**2.697 tokens gravados no cache na primeira chamada e lidos dele na segunda**, com só os 7 e 13 tokens de
cada pergunta cobrados como entrada comum. No momento em que este texto foi escrito, os provedores
cobram a leitura do cache a uma fração do preço normal de entrada e a gravação com um acréscimo, então a
economia começa na segunda requisição dentro da vida do cache; confira a tabela de preços atual do
provedor antes de contar com a proporção.

Três condições decidem se ele se aplica:

- **O prefixo precisa ser idêntico**, byte a byte, desde o começo. As fontes da aula 12 mudam a cada
  pergunta, então não podem fazer parte dele; só o que vem antes delas pode.
- **Ele precisa ser longo o bastante**, acima do mínimo do provedor.
- **Ele precisa ser reusado dentro da vida dele**, o que um assistente movimentado faz e um quieto não.

O cache de prompt também muda o argumento de desenho da aula 1. Mandar um acervo pequeno e fixo inteiro a
cada chamada fica mais barato quando o acervo está em cache, e para um punhado de documentos que nunca
mudam pode ser mais simples que a recuperação. Ainda é limitado pela janela, ainda paga a distração que a
aula 12 descreveu, e ainda precisa das permissões da aula 14, que um prefixo compartilhado por todos não
consegue expressar.
