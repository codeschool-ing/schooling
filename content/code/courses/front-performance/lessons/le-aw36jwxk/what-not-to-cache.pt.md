---
title: O que um worker não deve guardar
version: 1
---

**Tudo o que a aula 9 disse que um cache compartilhado não deve guardar, um worker também não deve**, e mais duas
coisas, porque o cache de um worker dura até o worker decidir o contrário.

- **Respostas que não são `GET`.** O worker do planner retorna cedo para qualquer outra, então o `POST` para
  `/vitals` vai para a rede como se o worker não existisse. O Cache Storage se recusa a guardar um `POST` de
  qualquer jeito; o retorno cedo deixa a intenção clara.
- **Os servidores dos outros.** O worker do planner só responde à própria origem. Uma resposta de outro servidor,
  buscada sem CORS, é *opaca*: o worker pode guardá-la mas não consegue ler o status, então um erro guardado
  parece um sucesso guardado, e os navegadores contam cada resposta opaca como vários megabytes da cota.
- **Erros.** O `fetchAndKeep` só guarda uma resposta cujo `ok` é verdadeiro. Uma página 500 guardada pelo
  network first seria o que o visitante vê offline, para sempre, sem como distingui-la da página de verdade.
- **Os dados de uma pessoa.** Uma página com os dados de uma pessoa conectada, guardada por um worker, continua
  lá depois de ela sair, num computador compartilhado, para a próxima pessoa. Network only, ou um cache limpo na
  saída.
- **Sem limite.** O Cache Storage conta contra a parte do disco do site. Um worker que guarda toda página e toda
  imagem que lhe pedem cresce a cada visita; o do planner é pequeno porque o planner é, e um catálogo de verdade
  limitaria o número de páginas que guarda, apagando as mais antigas.
