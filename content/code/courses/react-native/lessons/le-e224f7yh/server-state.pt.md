---
title: Estado de servidor não é como o resto
version: 1
---

**Estado que mora num servidor é uma cópia emprestada.** O plano no provider da aula 9 pertencia ao app: só
mudava quando o app o mudava. Um plano buscado num servidor pode mudar no servidor a qualquer momento, por
outro celular, por um navegador, pelo script de alguém. Então a cópia do app tem perguntas que a do provider
nunca teve:

- **Já chegou?** Buscar leva tempo, e a tela precisa mostrar algo enquanto espera.
- **Chegou mesmo?** O servidor pode estar fora do ar, a rede pode ter caído, a resposta pode ser um erro.
- **Ainda é verdade?** Uma cópia buscada há dez minutos talvez não seja.
- **A minha mudança chegou lá?** Um toque que marca uma sessão como feita é uma requisição, que pode falhar
  depois que a tela já o mostrou.

Escrever essas respostas com `useState` e `useEffect` em cada tela é como os apps acabam com um indicador de
carregando que nunca some, uma requisição disparada duas vezes a cada renderização, e uma lista que mostra os
dados de ontem depois de uma mudança. O **TanStack Query** é uma biblioteca que responde às quatro de uma vez:
busca, guarda cada resultado em cache sob uma chave, acompanha a idade dele, busca de novo quando deve, e roda
mudanças com um caminho de volta.

## Dois vocabulários

| o TanStack Query chama de | é | o do planner |
|---|---|---|
| uma **query** | uma leitura, identificada por uma chave, em cache | `["plan"]`, o plano inteiro |
| uma **mutation** | uma escrita, rodada sob demanda, com hooks em volta | marcar uma sessão como feita |
| **invalidação** | marcar uma query em cache como velha para ela ser buscada de novo | depois de toda mutation |
| **stale time** | por quanto tempo um resultado conta como fresco | 30 segundos |

## O que continua igual

As telas. A aula 9 lhes deu o `usePlan()`, que devolve `{ plan, dispatch }`. Esta aula mantém esse hook e muda o
que está por trás dele, de um reducer na memória para uma query e uma mutation, e **nenhum arquivo de tela
muda**. É isso que um hook como fronteira compra: as telas pedem o plano e as mudanças, e nunca ficam sabendo
para onde vai nenhum dos dois.

A história offline contada aqui é a curta, uma requisição que espera pela rede. O curso `mobile-offline`, que
todo aluno faz depois deste, é sobre a longa: um banco de dados no celular, uma fila de mudanças, e o que fazer
quando duas delas discordam.
