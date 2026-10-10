---
title: Executando os casos, e registrando o que aconteceu
version: 1
---

Executar um caso parece a metade fácil: seguir os passos, olhar a tela. A parte que exige
disciplina é o registro. **Uma execução que não deixa registro não se distingue de uma execução que
nunca aconteceu**, e o registro é o que um desenvolvedor, um gerente ou você mesmo na semana que
vem lê em vez de perguntar. Esta seção executa os sete casos no boxoffice 1.0, de uma vez só, e
anota o que cada um fez.

## Antes do primeiro caso

Anote o que está sendo testado. Um veredito pertence a uma versão da aplicação num ambiente, e um
passou na 1.0 não diz nada sobre a 1.1. Inicie o boxoffice do zero, como mostra a seção 04 da aula
1, e pergunte a ele que versão é:

```
ana@laptop:~/boxoffice$ curl http://127.0.0.1:8000/health
ok boxoffice 1.0
```

No navegador a versão fica no rodapé de toda página, `boxoffice 1.0`.

**Depois confira a ordem em que os casos rodam.** O TC-CONFIRM-01 precisa que o TC-SIGNUP-01 tenha
rodado, e o TC-BOOK-03 precisa do TC-CONFIRM-01, então esses três vão nessa ordem. Os outros só
precisam do estado que as pré-condições deles citam, e uma inicialização limpa dá todos. A execução
abaixo os pega na ordem em que a seção 04 os lista, num único servidor que não é reiniciado no
meio.

As transcrições são os mesmos passos enviados com curl, guardados como evidência. No navegador você
preenche os formulários que os passos descrevem; a linha a comparar é a mensagem no meio da página.

## Cadastro

O TC-SIGNUP-01 preenche o formulário de cadastro com os dados da Ana. O navegador mostra uma página
chamada Account created:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to ana@example.org.</p>
```

A primeira metade do resultado esperado vale, e a segunda está na caixa de saída, que o próximo
caso também confere. O TC-SIGNUP-02 preenche o mesmo formulário com o endereço do membro, e recebe
o formulário de volta com uma frase no topo. Depois a caixa de saída é contada:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Ana+Lima&email=member@example.org&password=boxoffice-2026' http://127.0.0.1:8000/signup | grep msg
<p class="msg">There is already an account with that e-mail.</p><form method="post" action="/signup">
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -c '<article>'
1
```

Um e-mail na caixa de saída resolve dois resultados esperados de uma vez: o TC-SIGNUP-01 enviou um,
e o TC-SIGNUP-02 não enviou nenhum. No navegador, a página Outbox mostra um único e-mail, Confirm
your account, para `ana@example.org`.

## Confirmação

O TC-CONFIRM-01 abre a caixa de saída e segue o link desse e-mail:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -E 'h2|token'
<article><h2>Confirm your account</h2><p>To: ana@example.org · 2026-10-10 14:00</p><pre>Hello Ana Lima,
http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv' | grep msg
<p class="msg">Your account is confirmed.</p>
```

O seu link termina num token diferente do da Ana; o caso cita o e-mail, não o token, então isso não
importa. O TC-CONFIRM-02 abre um link que ninguém enviou:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nottherealone' | grep msg
<p class="msg">This link is not valid.</p>
```

## Reserva

O TC-BOOK-01 reserva dois ingressos para Hamlet como o membro, e depois olha a página Shows:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1001 reserved.</p>
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
<p>State: <strong>reserved</strong></p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>200</td>
```

No navegador isso é uma página Order com o total em negrito, e na página Shows a última coluna de
Hamlet mostra 78. O TC-BOOK-02 tenta a mesma reserva com um endereço que ninguém cadastrou:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=nobody@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Sign up before you book.</p><form method="post" action="/book">
```

O TC-BOOK-03 reserva como a Ana, cuja conta o TC-CONFIRM-01 confirmou, e a página Shows é lida mais
uma vez:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=ana@example.org&show=S3&quantity=2' http://127.0.0.1:8000/book | grep -A3 'class="msg"'
<p class="msg">Order 1002 reserved.</p>
<p>The Little Prince, 2 ticket(s), 10% off:
<strong>R$ 54,00</strong></p>
<p>State: <strong>reserved</strong></p>
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'
<tr><td>The Seagull</td><td>2026-10-10 20:00</td><td>R$ 60,00</td><td>120</td>
<tr><td>Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78</td>
<tr><td>The Little Prince</td><td>2026-10-18 16:00</td><td>R$ 30,00</td><td>198</td>
```

Essa única leitura fecha dois casos. The Little Prince foi de 200 para 198 pelo TC-BOOK-03, e
Hamlet continua em 78, então a reserva recusada do TC-BOOK-02 não levou lugar nenhum.

## O registro

Todo caso recebe um de quatro status:

- **passou**: o resultado obtido bateu com o resultado esperado, inteiro;
- **falhou**: alguma parte não bateu;
- **bloqueado**: o caso não pôde rodar, porque algo de que ele depende falhou ou está faltando. Se
  o TC-SIGNUP-01 tivesse falhado, o TC-CONFIRM-01 e o TC-BOOK-03 estariam bloqueados, não falhos,
  porque nada sobre a confirmação teria sido conferido;
- **não executado**: ninguém chegou até ele.

**Bloqueado e falhou ficam separados de propósito.** Contar um caso bloqueado como falho relata
três defeitos onde há um, e contá-lo como passou relata como funcionando uma funcionalidade que
ninguém olhou. Este é o registro da execução feito pela Ana:

| caso | status | observação |
|---|---|---|
| TC-SIGNUP-01 | passou | |
| TC-SIGNUP-02 | passou | "There is already an account with that e-mail." |
| TC-CONFIRM-01 | passou | |
| TC-CONFIRM-02 | passou | |
| TC-BOOK-01 | passou | pedido 1001 |
| TC-BOOK-02 | passou | "Sign up before you book." |
| TC-BOOK-03 | passou | pedido 1002 |

Acima dele ela anotou a data, 2026-10-10, a build, `boxoffice 1.0`, e o ambiente: o notebook dela,
com os passos enviados pelo curl. As observações guardam o que o caso deixou em aberto de propósito,
como o texto exato de uma recusa e os números dos pedidos, para que uma pergunta sobre esta execução
na semana que vem tenha resposta.

## Quando um caso falha, pergunte primeiro sobre o caso

O primeiro rascunho da Ana para o TC-BOOK-01 esperava R$ 160,00, e a execução disse R$ 144,00. Isso
é uma falha, e ainda não é um defeito. **A primeira pergunta diante de uma falha é se o caso está
certo**, e o requisito responde: o R5 dá 10% de desconto ao membro, dois ingressos para Hamlet são
R$ 160,00, e 10% a menos dá R$ 144,00. A aplicação estava certa e o caso tinha esquecido o desconto,
então o caso foi corrigido e executado de novo.

A pergunta tem de ser resolvida contra o requisito, nunca contra a tela. Mudar o resultado esperado
para bater com o que apareceu faria o caso passar, e todo defeito que ele foi escrito para pegar
passaria junto. Uma falha que sobrevive à pergunta é um defeito, e a aula 15 trata de relatar um.
