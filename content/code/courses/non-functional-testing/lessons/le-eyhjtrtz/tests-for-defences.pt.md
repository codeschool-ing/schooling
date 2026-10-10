---
title: Testes que seguram uma defesa
version: 1
---

Um teste funcional pergunta se o sistema faz o que deve para alguém que quer que ele funcione. Um
teste de segurança faz a pergunta oposta ao mesmo código: **ele recusa o que deve recusar**, a
alguém pedindo algo que não pode ter? O teste tem a mesma cara, uma requisição e uma asserção sobre
a resposta. O que muda é quem manda a requisição, e que resposta conta como aprovação.

Isso faz da maior parte do trabalho de segurança de um testador um teste de regressão comum. Uma
defesa são algumas linhas de código, e algumas linhas de código somem: numa refatoração, num merge
que ficou com o lado errado, numa mudança de alguém que não sabia por que a linha estava ali. **Um
teste que falha no dia em que a defesa some é o controle de segurança mais barato que existe**,
porque não custa nada em todos os dias em que a defesa continua lá.

## A suíte

Cada teste abaixo é uma sonda que um testador tentaria à mão, escrita para rodar a cada mudança.
Nenhum deles ataca coisa alguma: um segundo cliente pedindo a reserva do primeiro, uma aspa simples
numa caixa de busca, um marcador inofensivo onde deveria haver um nome, um formulário enviado sem o
token que a página deu, um arquivo de texto mandado como imagem. Crie-a com `nano test_account.py`.

```schooling-example
{"language": "python", "file": "boxoffice/test_account.py", "parts": [{"code": "# boxoffice/test_account.py\n# One test for each defence in account.py. Run: python3 -m unittest -v test_account\nimport http.client, json, logging, os, re, tempfile, threading, unittest\nfrom http.server import ThreadingHTTPServer\nfrom urllib.parse import quote, urlencode\n\nHOME = tempfile.mkdtemp()                 # a database of its own, thrown away\nos.environ.update(ACCOUNT_DB=f\"{HOME}/account.db\", ACCOUNT_UPLOADS=f\"{HOME}/uploads\")\nimport account\nlogging.getLogger(\"account\").addHandler(logging.NullHandler())\nPASSWORD = \"correct horse battery\"\nPNG = b\"\\x89PNG\\r\\n\\x1a\\n\" + bytes(64)\n", "note": "A suíte nunca toca em `data/account.db`. Ela cria um diretório temporário, aponta as duas variáveis de ambiente para ele e só então importa `account`, que as lê quando carrega. `PASSWORD` pertence a contas que só existem dentro desta execução, e `PNG` são os oito bytes da assinatura PNG seguidos de zeros."}, {"code": "def setUpModule():\n    global server\n    account.init()\n    server = ThreadingHTTPServer((\"127.0.0.1\", 0), account.Account)\n    threading.Thread(target=server.serve_forever, daemon=True).start()\n\ndef tearDownModule():\n    server.shutdown()\n", "note": "Antes do primeiro teste, o servidor sobe numa thread do próprio processo de teste, na porta 0, que pede ao sistema qualquer porta livre. Nada mais precisa estar rodando, e a suíte não esbarra num servidor que você deixou aberto na 8001."}, {"code": "def call(method, path, body=None, token=None, cookie=None, form=None, headers=None):\n    \"\"\"One request to the server under test: (status, body, headers).\"\"\"\n    headers = dict(headers or {})\n    if token:\n        headers[\"Authorization\"] = f\"Bearer {token}\"\n    if cookie:\n        headers[\"Cookie\"] = f\"session={cookie}\"\n    if form is not None:\n        body, headers[\"Content-Type\"] = urlencode(form), \"application/x-www-form-urlencoded\"\n    elif isinstance(body, dict):\n        body = json.dumps(body)\n    conn = http.client.HTTPConnection(\"127.0.0.1\", server.server_address[1], timeout=10)\n    conn.request(method, path, body, headers)\n    answer = conn.getresponse()\n    result = answer.status, answer.read().decode(errors=\"replace\"), answer.headers\n    conn.close()\n    return result\n", "note": "`call` envia uma requisição e devolve o status, o corpo e os cabeçalhos. Ela nunca levanta exceção num 403 ou num 404, porque para estes testes uma recusa é a resposta esperada, não um erro."}, {"code": "made = 0\ndef customer():\n    \"\"\"A new account, signed in. Its token is also its session cookie.\"\"\"\n    global made\n    made += 1\n    name = f\"customer{made}\"\n    call(\"POST\", \"/register\", {\"name\": name, \"password\": PASSWORD})\n    status, body, _ = call(\"POST\", \"/login\", {\"name\": name, \"password\": PASSWORD})\n    assert status == 200, body\n    return name, json.loads(body)[\"token\"]\n\ndef book(token, holder=\"Ana Lima\"):\n    status, body, _ = call(\"POST\", \"/bookings\", {\"show_id\": 990, \"seat\": 12, \"holder\": holder},\n                           token=token)\n    assert status == 201, body\n    return json.loads(body)[\"id\"]\n", "note": "`customer` cadastra uma conta nova com um nome que nenhum outro teste usa e faz o login. Cada teste cria as suas pessoas, então nenhum depende do que outro deixou. `book` faz uma reserva e devolve o id."}, {"code": "class Defences(unittest.TestCase):\n    def test_a_customer_cannot_read_another_customers_booking(self):\n        _, ana = customer()\n        _, bia = customer()\n        booking = book(ana)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 200)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=bia)[0], 404,\n                         \"a second customer's token read the first customer's booking\")\n\n    def test_logout_ends_the_session(self):\n        _, ana = customer()\n        booking = book(ana)\n        self.assertEqual(call(\"POST\", \"/logout\", token=ana)[0], 200)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 401,\n                         \"the token still worked after logout\")\n", "note": "O primeiro teste é a promessa da aula 1, em código: dois clientes, uma reserva do primeiro e o token do segundo pedindo essa reserva. O `200` antes do `404` é o controle: prova que a reserva existe e que a rota funciona, para que o `404` signifique recusado e não quebrado."}, {"code": "    def test_a_quote_in_the_search_is_only_text(self):\n        _, ana = customer()\n        book(ana)\n        status, body, _ = call(\"GET\", \"/account?q=\" + quote(\"'\"), cookie=ana)\n        self.assertEqual(status, 200, \"a single quote in the search broke the query\")\n        self.assertNotIn(\"<li>\", body)\n\n    def test_markup_in_a_booking_comes_back_escaped(self):\n        _, ana = customer()\n        book(ana, holder=\"<em>nft-probe</em>\")\n        status, body, headers = call(\"GET\", \"/account\", cookie=ana)\n        self.assertIn(\"&lt;em&gt;nft-probe&lt;/em&gt;\", body)\n        self.assertNotIn(\"<em>nft-probe</em>\", body, \"the page sent the markup as markup\")\n        self.assertIn(\"default-src 'none'\", headers[\"Content-Security-Policy\"])\n", "note": "As duas sondas de texto. Uma aspa simples na busca tem de ser uma busca comum, sem resultados. Um marcador inofensivo como nome no ingresso tem de voltar como `&lt;em&gt;`, o texto de uma tag e não uma tag, numa página que leva Content-Security-Policy."}, {"code": "    def test_a_form_without_its_token_is_refused(self):\n        _, ana = customer()\n        booking = book(ana)\n        status, _, _ = call(\"POST\", \"/account/cancel\", cookie=ana, form={\"booking\": booking})\n        self.assertEqual(status, 403, \"a form with no CSRF token cancelled a booking\")\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 200)\n\n    def test_the_same_form_with_its_token_works(self):\n        _, ana = customer()\n        booking = book(ana)\n        csrf = re.search(r'name=\"csrf\" value=\"([^\"]+)\"', call(\"GET\", \"/account\", cookie=ana)[1])\n        form = {\"booking\": booking, \"csrf\": csrf.group(1)}\n        self.assertEqual(call(\"POST\", \"/account/cancel\", cookie=ana, form=form)[0], 303)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 404)\n", "note": "A sonda do formulário e o seu controle. Sem o token CSRF, o cancelamento é recusado e a reserva continua lá; com o token tirado da página, o mesmo formulário funciona."}, {"code": "    def test_an_upload_that_is_not_an_image_is_refused(self):\n        _, ana = customer()\n        self.assertEqual(call(\"POST\", \"/avatar\", b\"name,seat\\nana,12\\n\", token=ana)[0], 415)\n        self.assertEqual(call(\"POST\", \"/avatar\", bytes(300_000), token=ana)[0], 413)\n        self.assertEqual(call(\"POST\", \"/avatar\", PNG, token=ana)[0], 201)\n        for name in os.listdir(f\"{HOME}/uploads\"):\n            self.assertRegex(name, r\"^[0-9a-f]{32}\\.png$\")\n\n    def test_an_error_says_nothing_about_the_software(self):\n        status, body, headers = call(\"POST\", \"/register\", \"{not json\")\n        self.assertEqual(status, 400)\n        self.assertNotIn(\"Traceback\", body)\n        self.assertEqual(headers[\"Server\"], \"account\")\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "Texto fingindo ser imagem é recusado com 415, um corpo acima do limite com 413, e uma assinatura PNG de verdade é aceita e guardada com 32 caracteres hexadecimais aleatórios. O último teste manda um corpo quebrado e confere que a resposta é um 400 simples, de um servidor que não diz o que roda."}]}
```

Dois hábitos dela valem copiar para qualquer suíte de segurança que você escreva. **Toda recusa tem
um controle ao lado**: o pedido do próprio dono pela reserva funciona, o formulário com o token
funciona, um PNG de verdade é aceito. Um teste que só confere um `403` passa igualmente feliz quando
a rota está quebrada para todo mundo, e uma rota quebrada não é uma defesa. E **toda asserção que
segura uma defesa carrega uma mensagem** dizendo, numa frase, o que deu errado, porque essa frase é o
que quem desenvolve lê quando o teste falha.

Rode:

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_account
test_a_customer_cannot_read_another_customers_booking (test_account.Defences.test_a_customer_cannot_read_another_customers_booking) ... ok
test_a_form_without_its_token_is_refused (test_account.Defences.test_a_form_without_its_token_is_refused) ... ok
test_a_quote_in_the_search_is_only_text (test_account.Defences.test_a_quote_in_the_search_is_only_text) ... ok
test_an_error_says_nothing_about_the_software (test_account.Defences.test_an_error_says_nothing_about_the_software) ... ok
test_an_upload_that_is_not_an_image_is_refused (test_account.Defences.test_an_upload_that_is_not_an_image_is_refused) ... ok
test_logout_ends_the_session (test_account.Defences.test_logout_ends_the_session) ... ok
test_markup_in_a_booking_comes_back_escaped (test_account.Defences.test_markup_in_a_booking_comes_back_escaped) ... ok
test_the_same_form_with_its_token_works (test_account.Defences.test_the_same_form_with_its_token_works) ... ok

----------------------------------------------------------------------
Ran 8 tests in 1.532s

OK
```

Oito testes, verdes, em 1.532 segundos. A maior parte disso foi com o scrypt, que é lento de
propósito e calculou o hash da senha de cada conta que os testes criaram, duas vezes: uma no
cadastro, outra no login.

## Provando que o teste vale a pena

Uma execução verde diz que as defesas se sustentam hoje. Não diz que os testes perceberiam se uma
deixasse de se sustentar, e um teste de segurança que não consegue falhar é pior que nenhum, porque
as pessoas acreditam nele. Então confira do jeito que você conferiria qualquer teste de regressão:
**tire a defesa e veja o teste ficar vermelho.**

Faça uma cópia do serviço em outro diretório com uma linha comentada, a que termina em
`# owner check`. Dá para fazer no `nano`, pondo `# ` na frente dessa linha; o `sed` faz o mesmo num
comando só, e o `diff` mostra que nada mais mudou:

```
ana@nft:~/boxoffice$ mkdir -p ~/unguarded && cp test_account.py ~/unguarded/
ana@nft:~/boxoffice$ sed '/# owner check$/s/^ */&# /' account.py > ~/unguarded/account.py
ana@nft:~/boxoffice$ diff account.py ~/unguarded/account.py
121c121
<             if row[0] != me[0]: return self.refuse(404, "no such booking", me)  # owner check
---
>             # if row[0] != me[0]: return self.refuse(404, "no such booking", me)  # owner check
ana@nft:~/unguarded$ python3 -m unittest test_account
F.......
======================================================================
FAIL: test_a_customer_cannot_read_another_customers_booking (test_account.Defences.test_a_customer_cannot_read_another_customers_booking)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/unguarded/test_account.py", line 64, in test_a_customer_cannot_read_another_customers_booking
    self.assertEqual(call("GET", f"/bookings/{booking}", token=bia)[0], 404,
AssertionError: 200 != 404 : a second customer's token read the first customer's booking

----------------------------------------------------------------------
Ran 8 tests in 1.463s

FAILED (failures=1)
ana@nft:~/boxoffice$ rm -r ~/unguarded
```

Um teste falhou, o que foi escrito para aquela linha, com a frase que recebeu: o token de um segundo
cliente leu a reserva do primeiro. Os outros sete continuam passando, porque as outras defesas
continuam lá. **Essa é a propriedade a procurar: uma defesa removida, um teste vermelho.** Uma defesa
cuja remoção não deixa nada vermelho não tem teste, diga o nome da suíte o que disser. Rodar a suíte
inteira contra cópias alteradas de propósito como esta, automaticamente e para cada linha, se chama
teste de mutação, e existem ferramentas que fazem isso; uma cópia feita à mão por defesa basta para
confiar numa suíte deste tamanho.

A cópia some de novo com o último comando. **Nunca deixe uma cópia enfraquecida onde um servidor
possa subi-la**: esta morou num diretório próprio, só os testes a rodaram, e foi apagada.
