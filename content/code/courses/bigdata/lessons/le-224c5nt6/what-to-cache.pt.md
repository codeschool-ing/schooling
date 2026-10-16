---
title: O que guardar em cache, e quando soltar
version: 1
---

**Guarde em cache o que é usado mais de uma vez, depois do trabalho que o torna caro, e só com as
colunas que serão lidas.** Cada parte dessa frase vem dos números da seção 02.

- **Mais de uma vez.** Um cache é uma cópia, e o primeiro uso paga por ela. Um resultado usado uma
  vez só fica mais lento por estar em cache.
- **Depois do trabalho caro.** Guardar os cliques crus economiza uma leitura dos arquivos, que o
  Spark faz depressa. Guardar o resultado de um join, de uma janela ou de um filtro pesado economiza o
  join, a janela ou o filtro, toda vez.
- **Só as colunas que serão lidas.** Três colunas ocuparam 51,4 MiB onde sete ocuparam 284,7. Um
  `select` antes do `cache` deixa memória para o trabalho, e para outros caches.

**Um cache é preguiçoso.** O `cache()` e o `persist()` marcam um DataFrame e retornam na hora; a
primeira ação que o calcula enche a cópia. Um programa que guarda em cache um DataFrame e depois só
usa uma versão filtrada dele não guarda nada útil, porque a versão filtrada é outro plano.

**Um cache fica até a aplicação terminar, ou até ser empurrado para fora.** A memória de
armazenamento é dividida com a de execução, a região unificada da aula 7. Quando uma tarefa em
execução precisa de espaço, o Spark expulsa partições em cache, as usadas há mais tempo primeiro, e
um cache que estava lá há um minuto pode ter sumido em parte, sem erro nenhum. O `df.unpersist()`
solta um cache assim que ele não é mais preciso, o que é educado num programa longo e necessário num
loop.

Em SQL a mesma coisa é um comando, e, ao contrário do `cache()`, é ansioso a menos que digam outra
coisa:

```sql
CACHE TABLE purchases AS SELECT * FROM clicks WHERE kind = 'purchase';
CACHE LAZY TABLE purchases AS SELECT * FROM clicks WHERE kind = 'purchase';
UNCACHE TABLE purchases;
```

O `CACHE TABLE` enche a cópia antes de retornar. O `CACHE LAZY TABLE` espera a primeira consulta,
como o `cache()`. Nos dois casos a tabela em cache fica visível para toda consulta da aplicação, pelo
nome.
