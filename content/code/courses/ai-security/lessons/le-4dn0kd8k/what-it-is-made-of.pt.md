---
title: Do que é feita uma aplicação com LLM
version: 1
---

A imagem de que a maioria parte é um modelo com uma caixa de texto na frente, e a pergunta de segurança
vira se o modelo pode ser levado a dizer algo que não deve. **O modelo é uma parte da aplicação, e em
geral não é a parte que causa o estrago.** Uma resposta só fere alguém quando algo age sobre ela: um
cliente que acredita nela, uma ferramenta que a executa, um log que a guarda, uma página que a mostra. A
superfície de ataque é tudo em volta do modelo por onde texto entra ou efeitos saem.

O assistente da Tarefa, sobre o qual toda aula deste curso trabalha, é típico. Ele tem cinco tipos de
parte:

| parte | na Tarefa | o que dá errado ali |
|---|---|---|
| **entradas** | mensagens de clientes no chat, tickets, requisições de parceiros, arquivos anexados | texto que a plataforma não escreveu chega ao prompt |
| **contexto** | o prompt de sistema, as páginas da central de ajuda | instruções e texto de referência ficam ao lado das palavras do cliente |
| **saídas** | respostas mostradas aos clientes, resumos enviados por e-mail | o texto do modelo é publicado como se fosse da empresa |
| **ações** | ferramentas: consultas, mensagens, reembolsos | uma proposta vira um efeito no mundo |
| **registros e terceiros** | o log de chamadas, o fornecedor do modelo | cópias de tudo, guardadas em outro lugar |

## Um fluxo só de texto

A propriedade que torna isto diferente de uma aplicação web comum está na segunda linha. Numa aplicação
web, código e dados viajam separados: uma consulta é código, e o valor que o usuário digitou é um
parâmetro, mantido à parte pelo driver do banco. **Um modelo recebe as instruções e o texto sobre o qual
trabalha num fluxo só**, e nada nesse fluxo marca quais palavras são ordens e quais são material. Um
modelo é treinado para seguir instruções, e não distingue de forma confiável as instruções que deveria
seguir de um texto com cara de instrução que chegou dentro de um ticket ou de um arquivo.

Essa é a raiz da injeção de prompt, que a aula 7 de `prompt-engineering` trata. Aqui ela dá a pergunta que organiza todo
o resto: **para cada texto que chega ao modelo, quem o escreveu, e o que o modelo pode fazer depois de
lê-lo?** Um prompt de sistema escrito pela Tarefa e uma página da central de ajuda revisada pela Tarefa
são confiáveis. Uma mensagem de cliente, um ticket, um arquivo que um cliente anexou e uma página buscada
na web não são, digam o que disserem sobre si mesmos.

## Onde o estrago acontece

Seguir a pergunta até o fim dá o princípio defensivo deste curso. Se texto não confiável pode chegar ao
modelo, então tudo o que o modelo pode fazer, texto não confiável pode tentar fazê-lo fazer. Então o
estrago é limitado pelo alcance do modelo, e não pelo julgamento dele:

- um modelo que só responde pode, no pior caso, responder mal, e as verificações da aula 9 e os
  filtros da aula 5 ficam entre essa resposta e o cliente;
- um modelo que chama ferramentas pode, no pior caso, chamá-las mal, e o portão e a confirmação da aula
  20 ficam entre a proposta e o efeito.

O resto desta aula transforma essa pergunta numa lista, e a lista num plano.
