---
title: Stubs, mocks, fakes e um relógio falso
version: 1
---

Um teste muitas vezes precisa de algo que não controla. Ele quer conferir o que acontece às 19:30 do
dia de um espetáculo, e o relógio diz 14:00. Quer saber se o cadastro manda um e-mail, e ninguém
quer um teste mandando e-mail de verdade. A resposta de costume é um **dublê de teste** (*test
double*): um substituto que ocupa o lugar da coisa real durante um teste, do jeito que um dublê
ocupa o lugar de um ator numa cena. O nome e a família de palavras abaixo vêm do livro de Gerard
Meszaros sobre padrões de teste, e são as palavras que os desenvolvedores vão usar perto de você,
quase sempre em inglês.

## Três tipos, pelo que fazem

A palavra "mock" é muito usada para todos eles. Vale ter as distinções, porque cada tipo responde a
uma pergunta diferente.

| dublê | o que faz | no boxoffice ou em volta dele |
|---|---|---|
| stub | dá respostas prontas, e nada mais | um serviço de pagamento que sempre diz "aprovado", para que um teste da página do pedido nunca encoste num cartão |
| mock | registra como foi chamado, para o teste conferir as chamadas | uma `send` que não envia nada e lembra cada endereço que recebeu |
| fake | uma versão funcional e mais simples da coisa real | a caixa de saída, que guarda cada e-mail na memória em vez de passá-lo a um servidor de e-mail |

Um **stub** trata da resposta que o código recebe de volta. Um **mock** trata do que o código pediu.
Um **fake** se comporta como a coisa real o bastante para ser usado, e pega um atalho que estaria
errado em produção. Você usa um fake desde a aula 1: a caixa de saída em `/outbox` é a build de
teste do boxoffice trocando um servidor de e-mail, e a aula 22 trata do que isso custa.

## Um mock, num arquivo de teste

Aqui está um mock fazendo o seu trabalho. O cadastro deveria mandar um e-mail de confirmação para o
endereço novo. O teste troca a `send` do boxoffice por um mock durante um cadastro, e depois
pergunta ao mock o que aconteceu. Salve-o como `test_signup.py`, ao lado dos outros:

```schooling-example
{"language": "python", "file": "test_signup.py", "parts": [
 {"code": "import unittest\nfrom unittest import mock\n\nimport boxoffice\n\n", "note": "`unittest.mock` é o kit de dublês de teste da biblioteca padrão. Desta vez o módulo inteiro é importado, porque o teste precisa mexer dentro dele."},
 {"code": "class SignupTest(unittest.TestCase):\n\n    def test_signup_sends_one_email(self):\n        with mock.patch.object(boxoffice, \"send\") as send:\n            boxoffice.signup({\"name\": \"Caio\", \"email\": \"caio@example.org\",\n                              \"password\": \"long-enough\"})\n", "note": "Durante o bloco `with`, `boxoffice.send` é trocada por um mock que não envia nada e lembra cada chamada. Então roda um cadastro, exatamente como o formulário o dispararia."},
 {"code": "        send.assert_called_once()\n        self.assertEqual(send.call_args.args[0], \"caio@example.org\")\n        self.assertEqual(boxoffice.OUTBOX, [])", "note": "As verificações são sobre a conversa, e não sobre um resultado: um e-mail foi pedido, para o Caio, e nada chegou à caixa de saída, porque a `send` de verdade nunca rodou."}
]}
```

Rode-o sozinho, dando o nome dele:

```
ana@laptop:~/boxoffice$ python3 -m unittest -v test_signup
test_signup_sends_one_email (test_signup.SignupTest.test_signup_sends_one_email) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.001s

OK
```

Ele passa sem nenhum servidor rodando, e nada chegou à caixa de saída. O teste conferiu a conversa entre `signup` e o código de e-mail, que era a única coisa de
que ele tratava. O `unittest.mock` está na biblioteca padrão; outras linguagens têm os seus kits, e
todos fazem isso.

## O relógio falso

O boxoffice lê uma configuração que é um dublê de teste por qualquer definição. `BOXOFFICE_NOW`
fixa o relógio da aplicação num momento que você escolhe, para que um teste não precise esperar por
ele. O R4 diz que a reserva de um espetáculo fecha uma hora antes do início. Para conferir isso no
relógio de verdade, você teria de estar na frente do computador entre 19:00 e 20:00 no dia de The
Seagull. Com um relógio falso, basta reiniciar.

No terminal do servidor, pare o boxoffice e inicie-o com o relógio em 19:30:

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T19:30:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

Depois reserve dois ingressos para The Seagull pelo segundo terminal:

```
ana@laptop:~$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

Fechada, como o R4 diz. Reinicie às 18:30 e o mesmo pedido passa:

```
ana@laptop:~$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

Os espetáculos são marcados a partir da data fixada, então, num computador com o horário de São
Paulo, estas transcrições saem iguais seja qual for a data de hoje; a aula 21 trata do que muda em
outros lugares. No Windows a variável é definida antes do comando: `$env:BOXOFFICE_NOW =
"2026-10-10T19:30:00-03:00"` no PowerShell, e depois `python boxoffice.py`. Essa linha não foi
rodada para este curso. Para voltar ao relógio de verdade, feche esse terminal ou rode
`Remove-Item Env:BOXOFFICE_NOW`; no Linux e no macOS a variável só valeu para aquele comando.

## O que um dublê pode esconder

**Um dublê é uma afirmação de que a coisa real se comporta como ele**, e todo teste que usa um se
apoia nessa afirmação. Se o stub de pagamento sempre diz "aprovado", nenhum teste da página do
pedido jamais viu um cartão recusado. Se o mock de `send` aceita qualquer endereço, um cadastro que
manda para o endereço errado passa. O relógio é o mais sutil: um momento fixo esconde tudo o que
depende de onde a máquina está no mundo, e a aula 21 usa `BOXOFFICE_NOW` para mostrar um defeito que
só existe em algumas máquinas.

É por isso que as camadas de cima existem. Os dublês deixam as camadas de baixo rápidas e estáveis,
e os testes de sistema deste curso rodam com o relógio real, o formulário real e um navegador real,
onde nada está no lugar de nada. Para um testador manual, o hábito útil é uma pergunta diante de
toda suíte verde: **o que foi trocado, e alguém conferiu o de verdade?**
