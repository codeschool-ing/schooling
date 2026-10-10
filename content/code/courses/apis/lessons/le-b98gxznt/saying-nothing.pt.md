---
title: Não dizer nada, e registrar isso
version: 1
---

**Uma recusa deve dizer a quem chama que foi recusado, e mais nada.** A recusa tentadora é a prestativa:
"não existe usuário chamado nobody", "senha errada para a ana". Juntas, essas duas mensagens respondem
uma pergunta que ninguém deveria conseguir fazer a uma API: se uma pessoa em particular tem conta aqui.
Numa livraria isso é um vazamento pequeno. Numa clínica ou num site de namoro é o estrago inteiro.

O `keys.py` responde os dois casos com as mesmas palavras e o mesmo código, de novo num servidor
recém-iniciado:

```
ana@api:~/shelf$ curl -s -u ana:wrong-password -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books
{"error": "authentication required"}
401 0.073168s
ana@api:~/shelf$ curl -s -u nobody:wrong-password -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books
{"error": "authentication required"}
401 0.067445s
```

**As palavras são a metade fácil; o tempo é a outra metade.** Um servidor que procura o usuário, não
acha ninguém e recusa na hora responde a um nome desconhecido numa fração do tempo que leva para rodar
o scrypt num conhecido, e um cronômetro lê isso tão claramente quanto uma mensagem. O `check_password`
fecha essa porta com o `DECOY`: a senha de um usuário desconhecido passa pelo scrypt contra o hash da
senha de ninguém, e as duas recusas custam o mesmo trabalho. Acima, uma senha errada para a ana levou
0,073 segundo e o usuário desconhecido 0,067; a senha certa custa o mesmo scrypt e cai na mesma faixa:

```
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 -o /dev/null -w '%{http_code} %{time_total}s\n' localhost:8000/v1/books
200 0.051551s
```

O endpoint de login segue a mesma regra, e um token que o servidor nunca viu também:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "nobody", "password": "river-lamp-42"}'
{"error": "wrong username or password"}
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer not-a-token' localhost:8000/v1/whoami
{"error": "invalid or expired token"}
```

A mesma regra vai além deste arquivo. Um formulário de cadastro que diz "este endereço já está
cadastrado" e uma recuperação de senha que diz "não há conta com esse endereço" também respondem a
pergunta proibida. A saída de costume é dizer a mesma coisa nos dois casos, "se existir uma conta,
enviamos um e-mail", e avisar o dono do endereço, e não quem está no teclado.

## Registrar sem vazar

As recusas não dizem nada a quem chama, e o log do próprio servidor deve dizer muito a quem o opera.
Este é o segundo terminal para as requisições acima:

```
keys on http://127.0.0.1:8000
auth: basic refused user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/books HTTP/1.1" 401 -
auth: basic refused user='nobody'
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/books HTTP/1.1" 401 -
auth: basic ok user='ana'
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/books HTTP/1.1" 200 -
auth: login refused user='nobody'
127.0.0.1 - - [10/Oct/2026 01:26:19] "POST /v1/login HTTP/1.1" 401 -
auth: bearer refused token=ce6f21ae
127.0.0.1 - - [10/Oct/2026 01:26:19] "GET /v1/whoami HTTP/1.1" 401 -
```

Cada decisão tem uma linha, e cada linha foi escrita para ser útil e inofensiva ao mesmo tempo:

- o nome do usuário vai para o log, porque "cinquenta recusas para a ana em um minuto" é a linha que
  alguém procura. É uma troca. Quem digita a senha no campo do nome a põe no log, e por isso o log é
  protegido como o banco;
- o token vai como **impressão digital**, os oito primeiros caracteres do SHA-256 dele. `ce6f21ae` é
  `not-a-token` com hash, o bastante para casar uma recusa com uma linha ou com um chamado, e inútil
  como credencial;
- a chave vai pelo prefixo, que não é secreto e serve exatamente para isso.

O que nunca aparece importa tanto quanto. **Nenhuma senha, nenhum token, nenhuma chave e nenhum
cabeçalho `Authorization`.** O servidor do Python registra só a linha da requisição, e é por isso que a
query string da seção anterior foi o único jeito de uma credencial entrar. O jeito comum de uma entrar
por acidente é uma linha de depuração que imprime todos os cabeçalhos de uma requisição, esquecida ali
quando a depuração acabou. A regra que evita isso é que **uma linha de log nomeia a credencial e nunca
a contém**.
