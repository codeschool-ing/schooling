---
title: Validação, quando a necessidade não está escrita
version: 1
---

A validação costuma ser tratada como tarefa do cliente, feita uma vez no fim, quando a gerente do
teatro experimenta o produto pronto e diz sim ou não. Essa tarde importa, e a aula 12 é sobre ela.
Ela também é o momento mais caro para descobrir que o produto é o errado, porque a essa altura tudo
já foi construído. **A validação é uma pergunta feita ao longo do projeto inteiro, e o testador
pode começar a fazê-la assim que existe um requisito e uma pessoa que tem a necessidade.**

A dificuldade é a que a seção 02 desta aula apontou: aquilo com que comparar o produto não está no
papel. Então a validação funciona pondo o produto, ou uma imagem dele, em contato com a necessidade.

## Jeitos de perguntar

Cinco jeitos cobrem a maioria dos projetos, mais ou menos na ordem em que um projeto os encontra:

- *percorrer um caso real*: sentar com a gerente e seguir um cliente de verdade pelos requisitos,
  passo a passo, em voz alta;
- *um rascunho ou protótipo*: mostrar a página de reserva no papel antes de ela existir e perguntar
  à equipe da bilheteria o que está faltando;
- *observar alguém usando*: um frequentador do teatro reserva um ingresso enquanto você olha sem
  dizer nada, e você anota cada hesitação;
- *teste de aceitação*: o cliente experimenta o produto contra os próprios critérios antes de ele
  entrar no ar, que é a aula 12;
- *um piloto*: um espetáculo é vendido pelo sistema novo enquanto o jeito antigo continua
  funcionando, e depois alguém olha o que os clientes fizeram e do que reclamaram.

Cada um deles põe uma pessoa com a necessidade diante de algo concreto. **Um requisito lido numa
reunião raramente provoca uma objeção; uma página que recusa uma reserva que a gerente faz toda
semana provoca.**

## Uma jornada em vez de um requisito

Um testador trabalhando sozinho não consegue validar, mas consegue preparar a evidência que torna a
validação rápida. A ferramenta é o cenário, um tipo real de cliente tentando fazer uma coisa real
do começo ao fim, em vez de um requisito de cada vez. Uma passada requisito por requisito pergunta
se o limite do R4 funciona. Uma jornada pergunta se as pessoas para quem o teatro vende conseguem
comprar o que vieram comprar.

The Little Prince tem sessão no domingo às 16:00, com 200 lugares, e é uma peça infantil. Um tipo
de cliente que o teatro certamente vai encontrar é a professora reservando para a turma. Ana tenta:
a conta do membro, The Little Prince, trinta ingressos.

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S3&quantity=30' http://127.0.0.1:8000/book | grep msg
<p class="msg">You can book 1 to 6 tickets.</p><form method="post" action="/book">
```

No navegador, a página Book responde com a mesma frase acima do formulário. Como verificação, isso
passa duas vezes: o R4 diz de 1 a 6 ingressos por pedido, e o R7 pede uma frase em vez de uma
página de erro. A aula 4 descobriu que o limite também recusa seis, o que é um defeito à parte
contra o R4 e não muda nada aqui. Como jornada, falha no primeiro passo: a professora pode reservar
a turma em cinco pedidos de seis, se pensar nisso, ou pode telefonar, se o teatro atender aos
domingos.

## Um achado sem resultado esperado

O que Ana tem não é um teste que falhou, porque nenhum requisito diz o que deveria ter acontecido. É
uma pergunta sobre o requisito, e ela vem com o que a pessoa que decide precisa para decidir:

- *a jornada*: uma professora reserva trinta lugares para um espetáculo;
- *o que acontece*: o R4 recusa todo pedido acima de seis, com a frase capturada;
- *quem é afetado*: todo grupo acima de seis, e The Little Prince mais que os outros;
- *o que pode significar*: o limite pode ser proposital, para impedir que um comprador leve um
  espetáculo inteiro, ou um descuido; só o teatro sabe qual.

**Um achado de validação oferece leituras, não um veredito**, e é para isso que serve a última
linha. O limite de seis pode existir por um bom motivo que ninguém escreveu, e nesse caso a
resposta é uma frase no R4 explicando-o e, talvez, um aviso na página dizendo aos grupos que
telefonem. O trabalho de Ana é garantir que a pergunta foi feita a alguém que pudesse respondê-la, e
a seção 05 desta aula diz para onde ela a manda.

## Validação não é gosto

Há uma armadilha própria de testadores. Depois de usar o produto mais do que qualquer um, o testador
tem opiniões fortes sobre como ele deveria se comportar, e é fácil chamar uma preferência de
necessidade. A diferença é a evidência. "Eu poria o preço antes da data" é uma preferência. "Três
dos cinco frequentadores que reservaram enquanto eu olhava passaram direto pelo preço e perguntaram
quanto custava o ingresso" é um achado sobre a necessidade, e dá para discutir com ele.
