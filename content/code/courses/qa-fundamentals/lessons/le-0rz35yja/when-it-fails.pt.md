---
title: Quando a instalação falha
version: 1
---

**A maioria das instalações que falham falha de um de três jeitos, e cada um imprime uma mensagem que
diz qual é.** Leia a mensagem antes de qualquer outra coisa. O primeiro erro é o que importa; as linhas
depois dele costumam ser consequências. Este também é o primeiro trabalho de teste do curso: uma
mensagem é evidência, e evidência se lê antes de chutar.

## Falta o módulo de ambientes virtuais

No Ubuntu e no Debian, `python3 -m venv` sem o pacote `python3-venv` para na hora:

```
lia@lab:~/aurora$ python3 -m venv .venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/lia/aurora/.venv/bin/python3
```

A mensagem diz o pacote e o comando. O pacote que ela cita, `python3.12-venv`, é o que o `python3-venv`
puxa, então qualquer um dos dois serve. Instale com `sudo`, apague o diretório criado pela metade com
`rm -rf .venv` e rode `python3 -m venv .venv` de novo.

## O ambiente não está ativo

A falha mais comum de todas, e a que mais parece coisa quebrada. Num terminal em que o ambiente nunca
foi ativado — um aberto antes de as linhas entrarem no `~/.bashrc`, ou qualquer terminal no Windows — o
`python3` é o do sistema, que nunca ouviu falar do behave:

```
lia@lab:~/aurora$ python3 -c "import behave"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'behave'
lia@lab:~/aurora$ source .venv/bin/activate
lia@lab:~/aurora$ python3 -c "import behave"
```

Não havia nada de errado com a instalação. Ativar o ambiente faz a mesma linha não imprimir nada, o que
num `import` quer dizer que funcionou. No Windows, se o PowerShell se recusar a rodar o `Activate.ps1`
com uma mensagem sobre políticas de execução, rodar `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
uma vez libera scripts feitos por você; esse caso não foi executado para este curso.

## A versão não existe

O `pip` responde a uma versão fixada que ele não encontra com a lista das que encontra:

```
lia@lab:~/aurora$ pip install behave==1.3.9 2>&1 | tail -2
ERROR: Could not find a version that satisfies the requirement behave==1.3.9 (from versions: 1.0.0, 1.1.0, 1.2.0, 1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6, 1.2.7.dev6, 1.2.7.dev8, 1.3.0, 1.3.1, 1.3.2, 1.3.3)
ERROR: No matching distribution found for behave==1.3.9
```

Aqui a versão foi digitada errado de propósito, `1.3.9` no lugar de `1.3.3`. A lista é a parte útil:
mostra o que existe, então um erro de digitação aparece de relance. Se o seu Python é mais velho que o
3.10, o `pip` pode oferecer um behave mais antigo ou nenhum, e a correção é um Python mais novo, não
outra versão da ferramenta; `python3 --version` diz qual você tem.

## Qualquer outra coisa

Dois hábitos resolvem quase tudo o que não está nesta lista. **Copie a última linha do erro num buscador,
entre aspas**: alguém já passou por isso. E **recomece do zero**, o que neste laboratório custa um
minuto: `rm -rf ~/aurora` e depois os comandos da seção anterior. Um laboratório que você pode jogar fora
e montar de novo é um laboratório que você não tem medo de quebrar, e testar é, na maior parte, quebrar
coisas de propósito.
