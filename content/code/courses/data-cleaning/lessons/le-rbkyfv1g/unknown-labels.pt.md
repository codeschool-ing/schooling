---
title: Um rótulo que ninguém mapeou
version: 1
---

**A linha mais importante do `categorise.py` é a que para.** Uma tabela de mapeamento está completa
para o dado contra o qual foi escrita, e a próxima exportação vai trazer algo que ela nunca viu: uma
categoria nova, uma grafia nova, um erro de digitação que ninguém cometeu ainda.

Há três coisas que o código poderia fazer com isso, e só uma é segura:

- **descartar a linha**: o produto some de todo relatório, em silêncio;
- **mapear para um padrão** como `Outros`: o produto aparece, num grupo que cresce quieto até ser a
  terceira maior categoria sem que ninguém saiba o que tem dentro;
- **recusar, e dar nome ao rótulo**: a limpeza para até alguém acrescentar uma linha à tabela.

Para ver isso funcionando, Ana tira a linha `emporio` do mapa e roda o passo de novo:

```
ana@lab:~/clean$ cp category_map.csv map.bak && grep -v '^emporio' map.bak > category_map.csv && python -c 'import categorise' ; cp map.bak category_map.csv
3 products have a category the map does not know: ['Empório']
```

A mensagem diz quantos produtos são afetados e que rótulo eles têm. **A correção leva um minuto e é
feita por alguém que sabe o que `Empório` quer dizer**; a alternativa é um erro silencioso em todo
relatório de vendas por meses.

A mesma recusa vale ser acrescentada a todo mapeamento de um pipeline, e a aula 17 a transforma num
teste que roda a cada nova exportação. É também por isso que a junção no `categorise.py` é à
esquerda: uma junção interna teria descartado os produtos não mapeados antes de a checagem conseguir
contá-los.
