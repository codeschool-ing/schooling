---
title: Para onde foi a senha
version: 1
---

**Autenticação** responde quem está pedindo; se a pessoa pode fazer o que pede é a aula 12. Todos os
jeitos de responder isso nesta aula partem de uma senha, então a primeira pergunta é o que o servidor
guarda dela. A aula 5 prometeu a resposta. O `passwords.py`, rodado no shell do Django a partir de
`~/agenda`:

```python
# passwords.py
import time

from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import User

stored = User.objects.get(username="bruno").password
print(stored)

started = time.perf_counter()
print(check_password("m4-orchard-copper-17", stored))
print(check_password("m4-orchard-copper-18", stored))
print(f"{(time.perf_counter() - started) / 2:.2f} s per check")

print(make_password("m4-orchard-copper-17"))
print(make_password("m4-orchard-copper-17"))
```

```
ana@vm:~/agenda$ uv run python manage.py shell -v 0 < passwords.py
pbkdf2_sha256$1500000$ThSmE6yd8BxIxoEfR8ik8s$st1kRGk9p3uHVvw7MhoUatBSCVQ9lzker2DNeaX0v9M=
True
False
0.29 s per check
pbkdf2_sha256$1500000$XGYh6aIiIU2KSIPxVW3AD0$027TmNXqBceQo7xBDBt8WhKlgqQGbd2+Tq040rul+VU=
pbkdf2_sha256$1500000$M3BZbzP1pqT7nrdWUXaJx6$5jVKnqY+kSBVNeDn0Qoq4kFn7kDJjFMY3A2fZ4+XXZg=
```

A primeira linha é o que a tabela `auth_user` guarda para o Bruno. **Não é a senha dele**, e a senha
não pode ser calculada de volta a partir dela. São quatro campos, separados por `$`:

| campo | valor | significado |
|---|---|---|
| algoritmo | `pbkdf2_sha256` | como o hash foi feito |
| iterações | `1500000` | SHA-256 aplicado um milhão e meio de vezes |
| salt | `ThSmE6yd8BxIxoEfR8ik8s` | aleatório, diferente para cada hash |
| hash | o resto | o resultado |

O `check_password` faz o hash do que foi digitado com o mesmo algoritmo, iterações e salt, e compara.
**As duas últimas linhas fizeram o hash da mesma senha duas vezes e chegaram a duas strings
diferentes**: isso é o salt, e quer dizer que duas pessoas com a mesma senha têm linhas diferentes, e
uma tabela de hashes pré-calculados não serve de nada contra elas.

**E 0,3 segundo por conferência é de propósito.** Um hash para senhas é feito lento para que quem
roubar a tabela pague esse preço a cada palpite, enquanto uma pessoa entrando paga uma vez. Um hash
rápido, como um único SHA-256, é a ferramenta errada aqui exatamente por isso, e guardar a própria
senha é a ferramenta errada por todos os motivos.

O padrão do Django é o PBKDF2. O **Argon2** venceu a Password Hashing Competition em 2015 e também é
caro em memória, o que encarece os palpites em placas de vídeo. O Django o usa se o `argon2-cffi`
estiver instalado e o `Argon2PasswordHasher` vier primeiro em `PASSWORD_HASHERS`, e o agenda-api o usa
desde o começo mais adiante nesta aula. O prefixo de cada hash diz que algoritmo o fez, então um site
pode trocar o padrão e continuar conferindo hashes antigos, atualizando cada um no próximo login da
pessoa.
