---
title: Limites, e para onde vai o estado
version: 1
---

Uma função é barata e fácil dentro de uma caixa cujas paredes o provedor define. **Saber onde estão as
paredes é a maior parte do projeto, porque uma função que bate numa delas falha em produção, não no
teste no seu notebook.** No Lambda estas são as que moldam os projetos, só com os números que a AWS
documenta com clareza:

- Duração: no máximo 15 minutos por chamada. Uma tarefa de vinte minutos não cabe numa chamada de
  Lambda, seja qual for a configuração; ela precisa ser cortada em etapas ou rodar em outro lugar.
- Memória: de 128 MB a 10.240 MB, e a fatia de processador cresce junto. Uma função lenta por falta de
  CPU fica mais rápida com mais memória, e a conta dos GB-segundos decide se ela também fica mais
  barata.
- Payload: a requisição e a resposta de uma chamada síncrona têm, cada uma, um teto de 6 MB. Uma
  função que produz um arquivo grande o põe no armazenamento de objetos e devolve um link para ele.
- Disco local: `/tmp` existe, com 512 MB por padrão e configurável até 10.240 MB, e vive só enquanto o
  ambiente de execução vive. É espaço de rascunho, não armazenamento.
- Concorrência: a conta tem uma cota por região de quantas cópias rodam ao mesmo tempo, dividida entre
  todas as funções dela. Uma função num laço descontrolado pode tomar a capacidade de que as outras
  precisam, e um limite de concorrência reservado por função é a proteção.

## Nenhum estado entre chamadas

O handler desta aula já mostrou isso com um contador. **O que uma função guarda na memória pertence a
um ambiente de execução, e a plataforma cria e descarta esses ambientes quando quer.** Então todo
pedaço de estado mora fora: num banco de dados, num cache, num armazenamento de objetos ou numa fila.
A sessão de um usuário é uma linha ou um token assinado, não uma variável. Um arquivo em processamento
está num bucket, não no `/tmp` esperando a próxima chamada encontrá-lo.

## Milhares de funções, um banco de dados

A falha que isso produz é específica e comum. **Um banco de dados relacional aceita um número limitado
de conexões, e cada ambiente de execução abre as suas.** Uma aplicação de servidor mantém um pool de,
digamos, vinte conexões e as divide entre todas as requisições. Funções não conseguem dividir entre
ambientes, então um pico que cria 800 ambientes pode abrir 800 conexões, e o banco recusa as que
passam do limite, ou fica lento com o resto, justamente quando o tráfego chega ao máximo.

Há três respostas:

- um proxy de conexões entre as funções e o banco, que mantém um pool pequeno de conexões de verdade e
  as empresta; a AWS vende um, o RDS Proxy;
- um limite na concorrência da função, baixo o bastante para ela não abrir mais conexões do que o
  banco aceita, o que quer dizer que as requisições além do limite são recusadas ou enfileiradas;
- um banco cuja interface são requisições HTTP em vez de conexões longas, como o DynamoDB, que não
  deixa pool nenhum para esgotar.

**Nada disso aparece num notebook**, onde um processo faz uma conexão. Aparece no primeiro dia
movimentado.
