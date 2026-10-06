---
title: O que um rollback não desfaz
version: 1
---

O `rollback.sh` move um link. Ele devolve o **código** ao estado anterior, e mais nada. Tudo o que o
release ruim fez no mundo fora do próprio diretório continua feito.

## Dados

Um release que rodou uma migração mudou o banco. Voltar o código deixa o schema novo no lugar, e o
código velho encontra agora um banco para o qual não foi escrito. Se a migração renomeou uma coluna,
o código velho pede uma coluna que não existe mais, e o rollback falha de um jeito novo.

É por isso que o **expandir e contrair** da aula 7 importa aqui. Uma mudança no schema é dividida em
releases que funcionam com a forma velha e com a nova: acrescentar a coluna nova, gravar nas duas,
copiar as linhas antigas, mudar quem lê, e então parar de gravar a coluna velha e removê-la. A cada
passo o release anterior ainda roda contra o banco como ele está, então a cada passo o rollback é
seguro. A parte destrutiva, remover a coluna velha, vem por último, num release próprio, quando
ninguém mais precisa voltar para trás dele.

## Tudo o mais que já saiu de casa

- **Mensagens e e-mails enviados.** Um release que mandou a todo cliente a data de entrega errada já
  mandou esses e-mails. Voltar impede os próximos.
- **Pagamentos cobrados, pedidos feitos, etiquetas impressas com a transportadora.** Agora são fatos
  no sistema de outra pessoa, e desfazê-los é um processo do negócio, não um deploy.
- **Caches e filas.** Um release que gravou um formato novo num cache compartilhado, ou publicou
  mensagens que os consumidores antigos não entendem, deixou isso para quem rodar depois.

## Então, antes de um release que mexe em estado

Faça uma pergunta na revisão: **se voltarmos isto uma hora depois de entrar, o que fica para trás?**
Se a resposta é "nada", o rollback desfaz tudo. Se a resposta é um schema, um formato de mensagem ou
um e-mail enviado, o release precisa de um plano de expandir e contrair, ou de uma flag que deixe
desligar o comportamento novo sem mexer no código, ou das duas coisas.
