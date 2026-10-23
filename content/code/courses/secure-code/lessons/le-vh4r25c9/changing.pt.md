---
title: Uma senha nova encerra toda outra sessão
version: 1
---

Uma paciente troca a senha por um de dois motivos. Ou é rotina, ou ela desconfia de que outra pessoa
a conhece. No segundo caso, **a pessoa que ela quer trancar do lado de fora muito provavelmente já
está logada**, e uma troca de senha que deixa essa sessão viva não muda nada para ela. A paciente
acredita que a trancou do lado de fora; não trancou. A aula 10 pôs isto entre os momentos em que a
aplicação precisa encerrar sessões por conta própria.

A regra: **quando a senha muda, toda outra sessão daquela conta termina.** A sessão que fez a troca
fica, porque a paciente a está usando e acabou de provar que conhece a senha antiga.

```
(.venv) ana@vm:~/sc/passwords$ git diff
diff --git a/app.py b/app.py
index ed8634a..d42a549 100644
--- a/app.py
+++ b/app.py
@@ -71,4 +71,8 @@ def change_password():
     if problem:
         return jsonify(error=problem), 400
     set_password(name, new)
+    mine = request.cookies.get("sid")
+    for sid, owner in list(SESSIONS.items()):
+        if owner == name and sid != mine:
+            del SESSIONS[sid]
     return jsonify(changed=True)
```

```
(.venv) ana@vm:~/sc/passwords$ pytest -q
.........                                                                [100%]
9 passed in 1.31s
```

Nove de nove. Faça o commit das correções, uma por regra, como na aula 10:

```
(.venv) ana@vm:~/sc/passwords$ git commit -qam "End the other sessions when a password changes"
(.venv) ana@vm:~/sc/passwords$ git log --oneline
453bdfe End the other sessions when a password changes
c01686a Ask for length, and refuse guessable passwords
161b4dc Store passwords with Argon2id, and answer a stranger as a wrong password
e154abd Store passwords and check the policy
```

### O que o portal faz agora, e o que falta

A tabela que um dia vaza guarda hashes Argon2id com sal e parâmetros próprios. O formulário de login
responde a um estranho e a uma senha errada com as mesmas palavras, ao mesmo custo. A política pede
comprimento e recusa o que é fácil de adivinhar, e uma senha trocada encerra as sessões que deve.

Três coisas que um portal de verdade acrescenta, cada uma assunto para outra aula no catálogo:

- **Um limite de tentativas**: um formulário de login que responde a mil palpites por minuto é um
  serviço de adivinhação. Atrase as respostas por conta e por endereço, em vez de travar a conta, o
  que deixaria qualquer um trancar qualquer paciente do lado de fora.
- **Um segundo fator**, o único controle que torna uma senha roubada insuficiente sozinha.
- **Uma recuperação que não seja porta dos fundos.** Um link de recuperação é uma senha disfarçada:
  aleatório, de vida curta, de uso único e, como a troca acima, encerra toda sessão quando é usado.
