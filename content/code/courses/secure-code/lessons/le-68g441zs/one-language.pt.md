---
title: Uma linguagem, dita na primeira página
version: 1
---

Codificação segura é questão de **chamada exata**. "Use consulta parametrizada" é um conselho; a
diferença entre `cursor.execute(sql % name)` e `cursor.execute(sql, (name,))` é a aula, e ela é uma
vírgula e um par de parênteses. Pseudocódigo não mostra essa diferença, então este curso escolhe uma
linguagem e diz aqui qual é: **Python 3, com o framework web Flask, SQLite como banco de dados e
pytest para os testes.**

Python porque é o que mais se parece com pseudocódigo para quem escreve outra linguagem, e porque as
bibliotecas de que o curso precisa vêm com ele ou estão a um `pip install` de distância. Flask porque
é pequeno o bastante para cada linha de uma aplicação caber na página, e nada acontece que você não
tenha escrito. SQLite porque faz parte da biblioteca padrão do Python, então não há servidor de banco
para instalar.

::: track security
Na sua trilha o curso `python` vem depois deste. Você não precisa dele antes: todo programa aqui é
curto, mostrado inteiro e explicado linha a linha, e ler basta para acompanhar o argumento. Digitar e
rodar é o que faz o argumento ficar.
:::

::: track devsecops
Sua trilha pediu que você escolhesse uma linguagem de automação antes deste curso. Se escolheu
Python, esta é a sua linguagem. Se escolheu Go ou JavaScript, leia os programas daqui como uma
segunda língua que você entende mas não escreve todo dia; a tabela abaixo diz como cada chamada
segura se chama na sua.
:::

::: track *
Se Python não é a sua linguagem, você ainda acompanha todas as aulas: cada programa é curto, mostrado
inteiro e explicado linha a linha. A tabela abaixo diz como as chamadas seguras se chamam em outras
linguagens.
:::

### O que se leva para outras linguagens

**As falhas são as mesmas em toda linguagem, e as defesas também.** Só muda a grafia. A tabela
associa as chamadas que este curso usa aos equivalentes em Go e em JavaScript no Node.js. É um
vocabulário para consulta, não um conjunto de gravações: nada em Go ou JavaScript foi executado para
este curso.

| o que você precisa | Python (este curso) | Go | JavaScript (Node.js) |
|---|---|---|---|
| uma consulta com parâmetros | `cur.execute("… WHERE id = ?", (pid,))` | `db.Query("… WHERE id = $1", pid)` | `db.query("… WHERE id = $1", [pid])` (pg) |
| HTML escapado por padrão | templates Jinja2 no Flask | `html/template` | os templates do framework (o React escapa texto) |
| rodar um programa sem shell | `subprocess.run([prog, arg])` | `exec.Command(prog, arg)` | `child_process.execFile(prog, [arg])` |
| um token aleatório | `secrets.token_urlsafe(32)` | `crypto/rand` | `crypto.randomBytes(32)` |
| um hash de senha | `argon2-cffi`, `bcrypt` | `golang.org/x/crypto/argon2` | pacotes `argon2`, `bcrypt` |
| comparar segredos em tempo constante | `hmac.compare_digest` | `subtle.ConstantTimeCompare` | `crypto.timingSafeEqual` |

### O que não se leva

Os frameworks diferem **no que fazem por você sem que você peça**, e essa metade não se traduz. O
Flask escapa HTML nos templates e não protege formulários contra falsificação de requisição entre
sites; o Django faz as duas coisas; o Express não faz nenhuma. Cada aula diz que metade de uma defesa
o Flask entrega e que metade você escreve, para que em outro framework você saiba que pergunta fazer
à documentação dele.
