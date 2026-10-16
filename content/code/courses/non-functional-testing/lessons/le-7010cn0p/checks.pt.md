---
title: As linhas que um teste consegue segurar
version: 1
---

Algumas linhas do plano são conferidas olhando, uma vez, à mão, e o resto por um teste que continua
olhando. **Olhe primeiro, à mão, para o seu próprio serviço em `127.0.0.1`**, porque é ali que um
achado é entendido; depois escreva o teste que o segura. Inicie o `account.py` no terminal dele se
não estiver rodando e, no segundo terminal, crie uma conta e peça a página dela imprimindo só os
cabeçalhos:

```
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/register -d '{"name": "ana", "password": "correct horse battery"}'
{"ok": true}
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/login -d '{"name": "ana", "password": "correct horse battery"}' | jq -r .token > ~/ana.token
ana@nft:~/boxoffice$ curl -s -o /dev/null -D - localhost:8001/account --cookie "session=$(cat ~/ana.token)"
HTTP/1.1 200 OK
Server: account
Date: Fri, 16 Oct 2026 00:39:57 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 273
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
```

Leia os cabeçalhos como as linhas da A02 pedem. **O que está lá**: `Server: account`, que não diz
software nem versão; `X-Content-Type-Options: nosniff`, que impede o navegador de adivinhar que um
arquivo é outra coisa que não o tipo declarado; e uma Content-Security-Policy cujo
`frame-ancestors 'none'` mantém a página fora dos frames de outros sites. **O que não está lá**
importa tanto quanto. Nenhum `Cache-Control`, numa página que lista as reservas de alguém, então o
navegador de um computador compartilhado ou um proxy pode guardar uma cópia: esse é o achado F19-1.
E nenhum `Strict-Transport-Security`, o que está certo aqui, porque o cabeçalho só significa algo
sobre HTTPS, e é uma linha para a revisão da implantação.

Agora a sonda da A10: uma requisição cujo `Content-Length` é uma palavra em vez de um número. É uma
requisição quebrada, do tipo que um cliente com defeito ou um proxy descuidado envia, e é
inofensiva:

```
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" -H 'Content-Length: many'
{"error": "something went wrong"}
 500
```

**A resposta não entrega nada**: uma frase e nenhum rastro do código. É a defesa para a qual o
`guarded` da aula 16 foi escrito, e ela se sustenta. O achado é o status: `500` diz que o servidor
falhou, quando quem errou foi a requisição, e um `400` é a resposta de que o cliente precisa. O
terminal do próprio serviço mostra o porquê, e que ele guardou a história inteira para quem o opera:

```
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
2026-10-15 21:39:57,100 ERROR unhandled error on POST /avatar
Traceback (most recent call last):
  File "/home/ana/boxoffice/account.py", line 78, in guarded
    route(urlparse(self.path))
  File "/home/ana/boxoffice/account.py", line 163, in post
    return self.upload(me)
           ^^^^^^^^^^^^^^^
  File "/home/ana/boxoffice/account.py", line 217, in upload
    size = int(self.headers.get("Content-Length", 0))
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ValueError: invalid literal for int() with base 10: 'many'
```

O traceback aponta a linha, 217, onde o `int()` encontrou a palavra `many`. Ele é registrado
inteiro no servidor e nunca enviado, que é a divisão certa; a correção é ler o comprimento onde ele
possa ser recusado com um `400`. Até alguém fazer essa correção, é o achado F19-2.

## Os achados, por escrito

Um achado é escrito para que alguém que não estava lá consiga agir sobre ele:

| | F19-1 | F19-2 | F19-3 |
|---|---|---|---|
| categoria | A02 | A10 | A09 |
| o quê | a página de reservas não envia `Cache-Control: no-store` | um `Content-Length` não numérico em `/avatar` recebe `500` | um login bem-sucedido não escreve linha de log |
| evidência | os cabeçalhos acima | a sonda e o traceback acima | o log em "O que uma linha de log carrega" |
| gravidade | baixa: dados pessoais no cache de um navegador | baixa: falha de forma segura, status errado | média: uma senha roubada não deixa rastro |
| correção | enviar o cabeçalho em toda página com dados pessoais | ler o cabeçalho onde ele possa responder `400` | registrar o sucesso, com a conta |

## O arquivo

Os testes deste arquivo seguram as linhas que nenhum arquivo anterior segura, e seguram os dois
achados que um teste consegue ver. Crie-o em `~/boxoffice` com `nano test_owasp.py`:

```schooling-example
{"language": "python", "file": "boxoffice/test_owasp.py", "parts": [{"code": "# boxoffice/test_owasp.py\n# The rows of lesson 19's test plan that no earlier file holds. Run: python3 -m unittest -v test_owasp\nimport json, unittest\nfrom test_account import call, customer, setUpModule, tearDownModule\n", "note": "Ele pega o servidor e as funções auxiliares do arquivo da aula 16, como fazem o `test_sessions.py` e o `test_vectors.py`, então sobe a sua própria cópia do `account.py` numa porta livre, com um banco só dele. O comentário no fim de cada linha `class` diz que categoria do Top 10 os testes dela seguram."}, {"code": "class Misconfiguration(unittest.TestCase):                                    # A02\n    def test_every_answer_forbids_guessing_its_type(self):\n        for path in (\"/health\", \"/nowhere\", \"/bookings/1\"):\n            _, _, headers = call(\"GET\", path)\n            self.assertEqual(headers[\"X-Content-Type-Options\"], \"nosniff\", path)\n            self.assertEqual(headers[\"Server\"], \"account\", path)\n", "note": "A02, configuração incorreta, vista de fora: toda resposta, um 404 e uma recusa incluídos, traz `nosniff`, e o cabeçalho `Server` não diz software nem versão. Três caminhos, porque um cabeçalho posto numa rota e esquecido em outra é o jeito comum de isso quebrar."}, {"code": "    def test_the_page_cannot_be_framed_by_another_site(self):\n        _, ana = customer()\n        _, _, headers = call(\"GET\", \"/account\", cookie=ana)\n        self.assertIn(\"frame-ancestors 'none'\", headers[\"Content-Security-Policy\"])\n\n    @unittest.expectedFailure                     # open finding F19-1, see the test plan\n    def test_a_page_of_personal_data_is_kept_out_of_caches(self):\n        _, ana = customer()\n        _, _, headers = call(\"GET\", \"/account\", cookie=ana)\n        self.assertEqual(headers[\"Cache-Control\"], \"no-store\")\n", "note": "A página não pode ser posta dentro do frame de outro site, que é o que diz o `frame-ancestors 'none'` da Content-Security-Policy dela. O terceiro teste é o primeiro achado em aberto: a página que lista as reservas de alguém não pede aos caches que não guardem cópia. O `expectedFailure` o marca como conhecido, então a execução continua verde, relata a falha como esperada, e fica vermelha no dia em que alguém corrigir a página sem atualizar o teste."}, {"code": "class Logging(unittest.TestCase):                                             # A09\n    def test_a_failed_sign_in_is_logged_without_the_password(self):\n        name, _ = customer()\n        with self.assertLogs(\"account\", \"WARNING\") as seen:\n            call(\"POST\", \"/login\", {\"name\": name, \"password\": \"not the password\"})\n        self.assertEqual(seen.output, [f\"WARNING:account:failed sign-in for '{name}'\"])\n", "note": "A09: um login errado escreve exatamente uma linha, e a linha traz o nome e não a senha. O `assertLogs` coleta o que o logger `account` escreveu durante o bloco, então o teste lê o log como um operador leria."}, {"code": "    def test_a_refusal_names_the_account_and_what_it_asked_for(self):\n        _, ana = customer()\n        with self.assertLogs(\"account\", \"WARNING\") as seen:\n            call(\"GET\", \"/staff/bookings\", token=ana)\n        self.assertRegex(seen.output[0], r\"refused GET /staff/bookings to account \\d+: staff only\")\n\n    def test_a_name_cannot_start_a_log_line_of_its_own(self):\n        with self.assertLogs(\"account\", \"WARNING\") as seen:\n            call(\"POST\", \"/login\", {\"name\": \"nft\\nWARNING nft-probe\", \"password\": \"x\"})\n        self.assertEqual(len(seen.records), 1)\n        self.assertNotIn(\"\\n\", seen.records[0].getMessage())\n", "note": "Uma recusa diz quem pediu e o quê. O último teste manda um nome com uma quebra de linha e um marcador dentro, a versão de log da aspa simples. O serviço registra nomes com `%r`, então a quebra sai como os dois caracteres `\\n` e não consegue começar uma linha que pareça do próprio serviço."}, {"code": "class ExceptionalConditions(unittest.TestCase):                               # A10\n    def test_a_malformed_body_is_a_400(self):\n        for body in (\"\", \"{\", \"[1, 2]\", json.dumps({\"name\": \"ana\"})):\n            self.assertEqual(call(\"POST\", \"/login\", body)[0], 400, body)\n\n    def test_an_unexpected_error_says_nothing_about_the_code(self):\n        _, ana = customer()\n        _, body, _ = call(\"POST\", \"/avatar\", token=ana, headers={\"Content-Length\": \"many\"})\n        self.assertEqual(json.loads(body), {\"error\": \"something went wrong\"})\n", "note": "A10: quatro corpos quebrados (vazio, cortado, no formato errado, com um campo faltando) recebem cada um um `400`. Depois, uma requisição cujo `Content-Length` é uma palavra: o código que o lê levanta um erro que ninguém previu, e o teste garante que a resposta continua sendo a frase simples do `guarded`, sem rastro do código."}, {"code": "    @unittest.expectedFailure                     # open finding F19-2, see the test plan\n    def test_a_length_that_is_not_a_number_is_the_clients_mistake(self):\n        _, ana = customer()\n        status, _, _ = call(\"POST\", \"/avatar\", token=ana, headers={\"Content-Length\": \"many\"})\n        self.assertEqual(status, 400)\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "O segundo achado em aberto. Essa requisição é erro do cliente e deveria receber `400`; o `account.py` responde `500`, porque o erro é pego pelo tratamento geral e não onde o comprimento é lido. Ele falha de forma segura, continua errado, e o teste diz isso a cada execução até a correção."}]}
```

Rode:

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_owasp
test_a_length_that_is_not_a_number_is_the_clients_mistake (test_owasp.ExceptionalConditions.test_a_length_that_is_not_a_number_is_the_clients_mistake) ... expected failure
test_a_malformed_body_is_a_400 (test_owasp.ExceptionalConditions.test_a_malformed_body_is_a_400) ... ok
test_an_unexpected_error_says_nothing_about_the_code (test_owasp.ExceptionalConditions.test_an_unexpected_error_says_nothing_about_the_code) ... ok
test_a_failed_sign_in_is_logged_without_the_password (test_owasp.Logging.test_a_failed_sign_in_is_logged_without_the_password) ... ok
test_a_name_cannot_start_a_log_line_of_its_own (test_owasp.Logging.test_a_name_cannot_start_a_log_line_of_its_own) ... ok
test_a_refusal_names_the_account_and_what_it_asked_for (test_owasp.Logging.test_a_refusal_names_the_account_and_what_it_asked_for) ... ok
test_a_page_of_personal_data_is_kept_out_of_caches (test_owasp.Misconfiguration.test_a_page_of_personal_data_is_kept_out_of_caches) ... expected failure
test_every_answer_forbids_guessing_its_type (test_owasp.Misconfiguration.test_every_answer_forbids_guessing_its_type) ... ok
test_the_page_cannot_be_framed_by_another_site (test_owasp.Misconfiguration.test_the_page_cannot_be_framed_by_another_site) ... ok

----------------------------------------------------------------------
Ran 9 tests in 1.152s

OK (expected failures=2)
```

Nove testes, sete `ok` e dois **`expected failure`**: os achados, falhando exatamente como o plano
diz que falham, enquanto a execução como um todo dá `OK`. É isso que o `@unittest.expectedFailure`
compra. Um achado em aberto continua visível a cada execução sem deixar o build vermelho por um
defeito que todo mundo já conhece. **No dia em que alguém o corrigir, o teste relata um sucesso
inesperado e a execução falha**, que é o lembrete para tirar a marcação, de modo que o teste segure a
correção dali em diante. Use-o só para um achado com número, escrito; uma falha esperada que ninguém
sabe explicar é um teste que foi desligado.

O F19-3 não tem teste, porque um login bem-sucedido não escreve linha nenhuma para um teste ler. O
teste dele vem junto com a correção.

Com este arquivo, a metade de segurança da suíte são quatro arquivos, e rodar o `unittest` sem nome
roda todos:

```
ana@nft:~/boxoffice$ python3 -m unittest
........x.....x...............
----------------------------------------------------------------------
Ran 30 tests in 6.656s

OK (expected failures=2)
```

Trinta testes, cada `x` um achado em aberto, em 6.656 segundos. Cada linha do plano marcada *um
teste* é um desses pontos.
