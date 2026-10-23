---
title: Argon2id, e a mesma resposta para um estranho
version: 1
---

A biblioteca é a `argon2-cffi`, que embrulha a implementação de referência do Argon2. Instale no
ambiente do curso:

```
(.venv) ana@vm:~/sc/passwords$ pip install --progress-bar off argon2-cffi==25.1.0
Collecting argon2-cffi==25.1.0
  Downloading argon2_cffi-25.1.0-py3-none-any.whl.metadata (4.1 kB)
Collecting argon2-cffi-bindings (from argon2-cffi==25.1.0)
  Downloading argon2_cffi_bindings-26.1.0-cp310-abi3-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl.metadata (7.5 kB)
Collecting cffi>=1.0.1 (from argon2-cffi-bindings->argon2-cffi==25.1.0)
  Downloading cffi-2.1.1-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl.metadata (2.5 kB)
Collecting pycparser (from cffi>=1.0.1->argon2-cffi-bindings->argon2-cffi==25.1.0)
  Downloading pycparser-3.12-py3-none-any.whl.metadata (9.7 kB)
Downloading argon2_cffi-25.1.0-py3-none-any.whl (14 kB)
Downloading argon2_cffi_bindings-26.1.0-cp310-abi3-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl (26 kB)
Downloading cffi-2.1.1-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.whl (221 kB)
Downloading pycparser-3.12-py3-none-any.whl (62 kB)
Installing collected packages: pycparser, cffi, argon2-cffi-bindings, argon2-cffi
Successfully installed argon2-cffi-25.1.0 argon2-cffi-bindings-26.1.0 cffi-2.1.1 pycparser-3.12
```

Antes de mudar o portal, veja o que ela produz. Um hash, conferido duas vezes, uma com a senha
certa e outra com uma errada:

```
(.venv) ana@vm:~/sc/passwords$ python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash("lilac river morning tea"); print(h); print(ph.verify(h, "lilac river morning tea")); ph.verify(h, "lilac river morning coffee")'
$argon2id$v=19$m=65536,t=3,p=4$4HJC9CeSC34a0n2vdU4Flg$QIVRFS2aU3S1j5Has7CprxeqHmlo0ik6m27ampYeSw0
True
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash("lilac river morning tea"); print(h); print(ph.verify(h, "lilac river morning tea")); ph.verify(h, "lilac river morning coffee")
                                                                                                                                                                ~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/argon2/_password_hasher.py", line 258, in verify
    return verify_secret(
        hash, _ensure_bytes(password, self.encoding), hash_type
    )
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/argon2/low_level.py", line 204, in verify_secret
    raise VerifyMismatchError(error_to_str(rv))
argon2.exceptions.VerifyMismatchError: The password does not match the supplied hash
```

O valor guardado é uma string só, e leva tudo o que é preciso para conferir uma senha depois:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" data-fig=\"l11-phc\" aria-label=\"Um hash Argon2id no formato de string PHC, separado em partes. argon2id é o algoritmo. v=19 é a versão do Argon2. m=65536 é a memória em KiB, 64 MiB. t=3 é o número de passadas sobre essa memória. p=4 é o número de faixas rodando em paralelo. Depois o sal, aleatório e diferente para cada hash, e por último o próprio hash. Tudo o que é preciso para conferir uma senha está na string.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">$argon2id$v=19$m=65536,t=3,p=4$&lt;salt&gt;$&lt;hash&gt;</text><rect x=\"20\" y=\"60\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"66.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">argon2id</text><text x=\"66.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">algoritmo</text><rect x=\"120\" y=\"60\" width=\"62\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"151.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">v=19</text><text x=\"151.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">versão</text><rect x=\"190\" y=\"60\" width=\"92\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"236.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">m=65536</text><text x=\"236.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memória, KiB</text><rect x=\"290\" y=\"60\" width=\"52\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"316.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">t=3</text><text x=\"316.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passadas</text><rect x=\"350\" y=\"60\" width=\"52\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"376.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">p=4</text><text x=\"376.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">faixas</text><rect x=\"410\" y=\"60\" width=\"142\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"481.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">salt</text><text x=\"481.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aleatório, por hash</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">hash</text><text x=\"630.0\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o resultado</text></svg>", "caption": "Os parâmetros viajam com o hash, então o custo pode subir depois sem quebrar nenhuma senha guardada."}
```

Este é o **formato de string PHC**. Como o algoritmo, os parâmetros e o sal ficam escritos ao lado de
cada hash, **aumentar o custo depois não quebra nada**. Hashes antigos continuam sendo conferidos com os parâmetros com que foram feitos, e cada um é atualizado na próxima vez que o dono entra. Um custo
guardado como constante no código, ao contrário, faz com que aumentá-lo invalide toda senha já
guardada, o que na prática quer dizer que ninguém nunca o aumenta.

Uma senha errada não é `False`: é uma exceção, `VerifyMismatchError`. O código que confere senhas
captura exatamente essa, para que um hash corrompido ou um bug estoure alto em vez de passar por
senha errada.

### Quanto mais lento

```
(.venv) ana@vm:~/sc/passwords$ python3 -m timeit -s 'import hashlib' 'hashlib.sha256(b"lilac river morning tea").hexdigest()'
1000000 loops, best of 5: 380 nsec per loop
(.venv) ana@vm:~/sc/passwords$ python3 -m timeit -s 'from argon2 import PasswordHasher; ph = PasswordHasher()' 'ph.hash("lilac river morning tea")'
5 loops, best of 5: 62 msec per loop
```

A mesma senha, com os dois hashes, na máquina que gravou esta aula: 380 nanossegundos para o
SHA-256, 62 milissegundos para o Argon2id, cerca de 160.000 vezes mais. Essas duas linhas são o
argumento inteiro da primeira seção, medido: o que é um incômodo para um login é um muro para quem
tenta candidatos um atrás do outro.

### A mesma resposta para um estranho

A primeira versão respondia `404 no such patient` para um nome que não conhecia e `401 wrong
password` para um nome conhecido. Isso transforma o formulário de login num jeito de perguntar se
alguém é paciente da Vereda, o que num portal de fisioterapia é uma pergunta sobre a saúde dessa
pessoa. **A correção responde aos dois casos com o mesmo status e as mesmas palavras.**

Responder igual é metade. A outra metade é **levar o mesmo tempo**. Se o portal pulasse o hash para um
nome desconhecido, responderia a um estranho numa fração de milissegundo e a um paciente conhecido em
dezenas de milissegundos, e a diferença é fácil de medir de fora. Por isso um nome desconhecido é
conferido contra um **chamariz**, o hash de uma senha que ninguém tem, feito uma vez na partida. Os
dois caminhos fazem uma verificação Argon2.

### A correção

Troque o SHA-256 por um `PasswordHasher`, confira contra o chamariz quando o nome for desconhecido,
refaça o hash quando os parâmetros tiverem mudado, e dê uma só resposta para as duas falhas:

```
(.venv) ana@vm:~/sc/passwords$ git diff
diff --git a/app.py b/app.py
index 353ae1a..b8ce3c5 100644
--- a/app.py
+++ b/app.py
@@ -1,20 +1,31 @@
 # app.py
-import hashlib
 import secrets
 
+from argon2 import PasswordHasher
+from argon2.exceptions import VerifyMismatchError
 from flask import Flask, abort, jsonify, request
 
 app = Flask(__name__)
 USERS = {}
 SESSIONS = {}
+HASHER = PasswordHasher()
+DECOY = HASHER.hash("a password nobody has")
 
 
 def set_password(name, password):
-    USERS[name] = hashlib.sha256(password.encode()).hexdigest()
+    USERS[name] = HASHER.hash(password)
 
 
 def password_is_right(name, password):
-    return USERS[name] == hashlib.sha256(password.encode()).hexdigest()
+    try:
+        HASHER.verify(USERS.get(name, DECOY), password)
+    except VerifyMismatchError:
+        return False
+    if name not in USERS:
+        return False
+    if HASHER.check_needs_rehash(USERS[name]):
+        set_password(name, password)
+    return True
 
 
 def policy_problem(password):
@@ -39,10 +50,8 @@ def current_patient():
 @app.post("/sign-in")
 def sign_in():
     name = request.form.get("name", "")
-    if name not in USERS:
-        return jsonify(error="no such patient"), 404
     if not password_is_right(name, request.form.get("password", "")):
-        return jsonify(error="wrong password"), 401
+        return jsonify(error="wrong name or password"), 401
     sid = secrets.token_urlsafe(32)
     SESSIONS[sid] = name
     response = jsonify(patient=name)
```

```
(.venv) ana@vm:~/sc/passwords$ pytest -q --tb=no
....FFF.F                                                                [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_password_policy[lilac river morning tea-True] - ...
FAILED test_app.py::test_the_password_policy[Vereda2026!-False] - AssertionEr...
FAILED test_app.py::test_the_password_policy[Vereda@2026Vereda!-False] - Asse...
FAILED test_app.py::test_changing_the_password_ends_the_other_sessions - asse...
4 failed, 5 passed in 1.32s
(.venv) ana@vm:~/sc/passwords$ git commit -qam "Store passwords with Argon2id, and answer a stranger as a wrong password"
```

**Três falhas a menos**: as duas sobre armazenamento e a da resposta. O `check_needs_rehash` ainda
não aparece num teste, porque todo hash aqui foi feito com os parâmetros de hoje. É a linha que deixa
você aumentá-los no ano que vem.

### E o bcrypt

O bcrypt é mais antigo, está em todo lugar, e continua uma escolha sólida. Duas coisas sobre ele valem
saber antes de encontrá-lo em outro código. O custo é um número só, o logaritmo do trabalho: `12` quer
dizer 2¹² rodadas. E **ele lê só os primeiros 72 bytes de uma senha**. Versões antigas do pacote
Python ignoravam o resto em silêncio; a versão 5.0.0 recusa:

```
(.venv) ana@vm:~/sc/passwords$ pip install --progress-bar off bcrypt==5.0.0
Collecting bcrypt==5.0.0
  Downloading bcrypt-5.0.0-cp39-abi3-manylinux_2_34_x86_64.whl.metadata (10 kB)
Downloading bcrypt-5.0.0-cp39-abi3-manylinux_2_34_x86_64.whl (278 kB)
Installing collected packages: bcrypt
Successfully installed bcrypt-5.0.0
(.venv) ana@vm:~/sc/passwords$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"lilac river morning tea", bcrypt.gensalt())); bcrypt.hashpw(b"x" * 73, bcrypt.gensalt())'
b'$2b$12$FkXAJ8bOJ45R2gCB0i3GoOltQRUuksGObKznc0RuJ5.qP90AYWiJ2'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import bcrypt; print(bcrypt.hashpw(b"lilac river morning tea", bcrypt.gensalt())); bcrypt.hashpw(b"x" * 73, bcrypt.gensalt())
                                                                                       ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
ValueError: password cannot be longer than 72 bytes, truncate manually if necessary (e.g. my_password[:72])
```

Setenta e dois bytes são menos caracteres do que parece quando uma frase tem acentos, porque `ç` e `ã`
ocupam dois bytes cada em UTF-8. O Argon2 não tem esse limite, e esse é um dos motivos de esta aula
usá-lo.
