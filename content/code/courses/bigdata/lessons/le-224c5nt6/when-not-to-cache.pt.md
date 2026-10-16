---
title: Quando não guardar em cache
version: 1
---

**Um cache é uma decisão de gastar memória, e na maior parte do tempo a memória é mais bem gasta no
trabalho.** Alguns padrões aparecem sempre em programas que guardam em cache demais.

- **Guardar tudo, por via das dúvidas.** Cada cache tira memória de armazenamento da memória de
  execução, e a aula 7 mostrou o que uma ordenação faz com menos dela: despeja em disco. Um programa
  que guarda em cache todo DataFrame intermediário pode rodar mais devagar que um que não guarda
  nenhum.
- **Guardar o que é lido uma vez.** O primeiro uso do cache dá mais trabalho que não guardar, os
  20,0 segundos de tarefa contra 15,2 da seção 02, e sem um segundo uso não há como recuperar.
- **Guardar logo depois da leitura.** Os arquivos Parquet já deixam o Spark pular as colunas e os
  dias de que a consulta não precisa, aula 6. Um cache da tabela crua economiza só a leitura que o
  Parquet tornou barata, e segura toda coluna e todo dia na memória para isso.
- **Guardar em vez de consertar o plano.** Um job que roda um join lento três vezes porque o programa
  monta o mesmo DataFrame de três jeitos se conserta montando-o uma vez.
- **Esquecer o unpersist num loop.** O cache de cada iteração fica até ser expulso, e as partições
  expulsas são escolhidas por uso recente, não por o programa ainda precisar delas.

**Na dúvida, meça, como esta aula fez**: o tempo das ações com e sem o cache, e o tamanho que a
página de armazenamento informa. Um cache que não recupera o seu primeiro uso dentro do programa é um
cache a remover.
