---
title: O ambiente é uma lista
version: 2
---

A aula 12 descobriu que um hospedeiro entregava aos servidores o ambiente inteiro, chaves de API inclusive. O `mcp_host.py` entrega a cada servidor exatamente o que o `ENV` nomeia, e a lista tem duas entradas: `PATH`, com o `bin` do ambiente virtual na frente, e `HOME`. O `PATH` está ali por um motivo fácil de não ver: o comando é `python`, e o processo do servidor procura esse nome no `PATH` que recebe, não no seu. Sem o ambiente virtual nele, `python` é o que o sistema tiver, se tiver, e esse Python não tem o `mcp`. Nada mais é preciso, porque nada no `shop.py` lê uma variável: o `search_help` chega ao Ollama num endereço fixo.

Uma pergunta para a central de ajuda, e depois a saída de erro dos servidores:

```
{block("help")}
```

A busca funcionou, e o modelo respondeu só pelos títulos: mandou o cliente para uma aba "Help" e para o artigo de livros danificados, numa pergunta sobre devoluções. Ele poderia ter lido `help://h14` com o `read_help`; este modelo, como a aula 1 descobriu, não chama uma segunda ferramenta depois de um resultado de ferramenta. O erro ali não foi do hospedeiro, e a próxima seção mostra a metade do hospedeiro na leitura de um artigo.

O `host.err` está vazio. É para lá que vai a saída de erro dos dois servidores, porque o `2> host.err` cobre também os filhos do hospedeiro, e quando um servidor cai o traceback vai para lá e para nenhum outro lugar: o cliente recebe *"Error executing tool …"*, como a aula 14 mostrou. Daí saem duas regras. **Um ambiente mínimo tem de ser completo**: liste o que cada servidor precisa e teste as ferramentas que precisam disso. E **guarde a saída de erro dos servidores**: um hospedeiro que a joga fora (as aulas 11 e 12 jogaram, com `2> /dev/null`) jogou fora o único lugar onde uma queda se explica.
