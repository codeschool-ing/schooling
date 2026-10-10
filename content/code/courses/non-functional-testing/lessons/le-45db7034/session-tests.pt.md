---
title: Os testes de sessão
version: 1
---

Cada teste desta aula até aqui foi digitado uma vez, à mão, e lido por uma pessoa. É assim que um
testador descobre quais são as respostas; não é assim que uma defesa continua defendida. **Cada teste
manual vira um teste que roda a cada mudança**, ao lado dos oito da aula 16, num segundo arquivo que
usa os mesmos auxiliares. Crie-o com `nano test_sessions.py`, em `~/boxoffice`, ao lado do
`test_account.py`.

```schooling-example
{"language": "python", "file": "boxoffice/test_sessions.py", "parts": [{"code": "# boxoffice/test_sessions.py\n# Who may do what, for how long. Run: python3 -m unittest -v test_sessions\nimport sqlite3, time, unittest\nfrom test_account import HOME, PASSWORD, book, call, customer, setUpModule, tearDownModule\nimport account                  # after test_account, which points it at a database of its own\n\ndef database():\n    return sqlite3.connect(f\"{HOME}/account.db\")\n", "note": "Ele toma emprestados o servidor, `call`, `customer` e `book` do `test_account.py`, então precisa desse arquivo ao lado. A ordem dos imports importa: o `test_account` define as duas variáveis de ambiente, e o `account` as lê quando é importado pela primeira vez, então importar `account` antes apontaria a suíte para o `data/account.db` de verdade. `database` abre a cópia da própria suíte, para os testes que olham o que foi guardado."}, {"code": "class Privilege(unittest.TestCase):\n    def test_a_customer_cannot_open_the_staff_list(self):\n        _, ana = customer()\n        self.assertEqual(call(\"GET\", \"/staff/bookings\", token=ana)[0], 403,\n                         \"a customer's token opened a staff-only route\")\n\n    def test_a_member_of_staff_can(self):\n        sam, token = customer()\n        with database() as db:\n            db.execute(\"UPDATE accounts SET role = 'staff' WHERE name = ?\", (sam,))\n        self.assertEqual(call(\"GET\", \"/staff/bookings\", token=token)[0], 200)\n\n    def test_a_token_in_the_address_is_not_accepted(self):\n        _, ana = customer()\n        booking = book(ana)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}?token={ana}\")[0], 401)\n", "note": "Escalonamento vertical e o seu controle: o token de um cliente é recusado na lista da equipe, e o mesmo pedido de uma conta promovida a equipe no banco funciona. Não existe rota que torne alguém equipe, então o teste faz isso como um operador faria. O terceiro teste põe um token válido no endereço, onde o serviço nunca olha."}, {"code": "class Sessions(unittest.TestCase):\n    def test_a_session_ends_when_it_expires(self):\n        self.addCleanup(setattr, account, \"SESSION_SECONDS\", account.SESSION_SECONDS)\n        account.SESSION_SECONDS = 1\n        _, ana = customer()\n        booking = book(ana)\n        time.sleep(1.5)\n        self.assertEqual(call(\"GET\", f\"/bookings/{booking}\", token=ana)[0], 401,\n                         \"the token still worked after its session expired\")\n\n    def test_the_cookie_is_out_of_reach_of_scripts_and_other_sites(self):\n        name, _ = customer()\n        _, _, headers = call(\"POST\", \"/login\", {\"name\": name, \"password\": PASSWORD})\n        cookie = headers[\"Set-Cookie\"]\n        self.assertIn(\"HttpOnly\", cookie)\n        self.assertIn(\"SameSite=Lax\", cookie)\n\n    def test_the_database_holds_no_live_token(self):\n        _, ana = customer()\n        with database() as db:\n            stored = [row[0] for row in db.execute(\"SELECT token FROM sessions\")]\n        self.assertNotIn(ana, stored)\n", "note": "Os testes de sessão. `addCleanup` devolve `SESSION_SECONDS` ao valor original quando o teste acaba, passe ou falhe, para que uma sessão de um segundo não vaze para o teste seguinte. O teste do cookie lê o cabeçalho `Set-Cookie`; o último confere que o que o banco guarda não é o token que o cliente tem na mão."}, {"code": "class Passwords(unittest.TestCase):\n    def test_the_same_password_is_stored_two_different_ways(self):\n        ana, _ = customer()\n        bia, _ = customer()\n        with database() as db:\n            hashes = [db.execute(\"SELECT hash FROM accounts WHERE name = ?\", (n,)).fetchone()[0]\n                      for n in (ana, bia)]\n        self.assertNotIn(PASSWORD, hashes)\n        self.assertNotEqual(hashes[0], hashes[1], \"two accounts share a hash: no salt\")\n\n    def test_sign_in_stops_after_five_failures(self):\n        ana, _ = customer()\n        wrong = {\"name\": ana, \"password\": \"not the password\"}\n        for attempt in range(5):\n            self.assertEqual(call(\"POST\", \"/login\", wrong)[0], 401)\n        right = {\"name\": ana, \"password\": PASSWORD}\n        self.assertEqual(call(\"POST\", \"/login\", right)[0], 429,\n                         \"a sixth attempt was let through after five failures\")\n\n    def test_an_unknown_name_is_answered_like_a_wrong_password(self):\n        ana, _ = customer()\n        wrong = call(\"POST\", \"/login\", {\"name\": ana, \"password\": \"not the password\"})\n        nobody = call(\"POST\", \"/login\", {\"name\": \"nobody\", \"password\": \"not the password\"})\n        self.assertEqual(wrong[:2], nobody[:2])\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "Os testes de senha: a mesma senha, duas contas, dois hashes diferentes, nenhum deles a senha. Cinco senhas erradas e depois a certa têm de ser recusadas com 429. E um nome desconhecido tem de receber exatamente o status e o corpo que uma senha errada recebe."}]}
```

Rode-o sozinho:

```
ana@nft:~/boxoffice$ python3 -m unittest -v test_sessions
test_an_unknown_name_is_answered_like_a_wrong_password (test_sessions.Passwords.test_an_unknown_name_is_answered_like_a_wrong_password) ... ok
test_sign_in_stops_after_five_failures (test_sessions.Passwords.test_sign_in_stops_after_five_failures) ... ok
test_the_same_password_is_stored_two_different_ways (test_sessions.Passwords.test_the_same_password_is_stored_two_different_ways) ... ok
test_a_customer_cannot_open_the_staff_list (test_sessions.Privilege.test_a_customer_cannot_open_the_staff_list) ... ok
test_a_member_of_staff_can (test_sessions.Privilege.test_a_member_of_staff_can) ... ok
test_a_token_in_the_address_is_not_accepted (test_sessions.Privilege.test_a_token_in_the_address_is_not_accepted) ... ok
test_a_session_ends_when_it_expires (test_sessions.Sessions.test_a_session_ends_when_it_expires) ... ok
test_the_cookie_is_out_of_reach_of_scripts_and_other_sites (test_sessions.Sessions.test_the_cookie_is_out_of_reach_of_scripts_and_other_sites) ... ok
test_the_database_holds_no_live_token (test_sessions.Sessions.test_the_database_holds_no_live_token) ... ok

----------------------------------------------------------------------
Ran 9 tests in 3.246s

OK
```

Nove testes, verdes, em 3.246 segundos, dos quais um e meio são o teste de expiração dormindo enquanto
uma sessão de um segundo vence. Um teste que espera é lento, e **este espera de propósito em vez de
mexer no banco para antedatar uma linha**: ele confere a expiração do jeito que um cliente a
encontra, pelo relógio. Com os dois arquivos no lugar, `python3 -m unittest` sem nome roda os dois
juntos, os dezessete testes que agora são a metade de segurança da suíte.

## Tirando a verificação de papel

O mesmo movimento da aula 16, no outro tipo de escalonamento: uma cópia do serviço com a linha que
termina em `# role check` comentada, e os testes de sessão rodados contra ela.

```
ana@nft:~/boxoffice$ mkdir -p ~/unguarded && cp test_account.py test_sessions.py ~/unguarded/
ana@nft:~/boxoffice$ sed '/# role check$/s/^ */&# /' account.py > ~/unguarded/account.py
ana@nft:~/boxoffice$ cd ~/unguarded
ana@nft:~/unguarded$ python3 -m unittest test_sessions
...F.....
======================================================================
FAIL: test_a_customer_cannot_open_the_staff_list (test_sessions.Privilege.test_a_customer_cannot_open_the_staff_list)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/unguarded/test_sessions.py", line 13, in test_a_customer_cannot_open_the_staff_list
    self.assertEqual(call("GET", "/staff/bookings", token=ana)[0], 403,
AssertionError: 200 != 403 : a customer's token opened a staff-only route

----------------------------------------------------------------------
Ran 9 tests in 3.385s

FAILED (failures=1)
ana@nft:~/unguarded$ cd ~/boxoffice
ana@nft:~/boxoffice$ rm -r ~/unguarded
```

Uma falha, o teste vertical, com a sua frase: o token de um cliente abriu uma rota só da equipe. Os
outros oito passam, entre eles o controle da equipe, porque alguém da equipe continua podendo entrar;
o que sumiu foi a recusa de todos os outros. **Os dois tipos de escalonamento têm um teste cada, e
cada teste responde só pela sua linha**: a cópia da aula 16 sem a verificação de dono reprovou só o
teste dos dois clientes, e esta reprova só o teste da equipe. Uma suíte montada assim diz a quem a
quebra qual defesa quebrou, na primeira linha da falha.
