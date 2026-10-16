---
title: Quando a montagem falha
version: 1
---

**Quase toda montagem que falha falha de um destes três jeitos, e cada um imprime uma mensagem que diz
o nome dele.** Leia a mensagem antes de qualquer outra coisa; o primeiro erro é o que importa, e as
linhas depois dele costumam ser consequências.

## Falta o módulo de ambientes virtuais

No Ubuntu e no Debian, `python3 -m venv` sem o pacote `python3-venv` para na hora:

```
ana@lab:~/roda$ python3 -m venv .venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/roda/.venv/bin/python3
```

A mensagem é especialmente útil: diz o nome do pacote, e o comando. O pacote que ela nomeia,
`python3.12-venv`, é o que o `python3-venv` traz junto, então qualquer um dos dois serve. Instale com
`sudo`, apague o diretório feito pela metade com `rm -rf .venv`, e rode `python3 -m venv .venv` de novo.

## O ambiente não está ativo

A falha mais comum de todas, e a que mais parece defeito. Num terminal em que o ambiente nunca foi
ativado — um aberto antes de as linhas entrarem no `~/.bashrc`, ou qualquer terminal no Windows — o
`python3` é o do sistema, que nunca ouviu falar do pyarrow:

```
ana@lab:~/roda$ python3 -c "import pyarrow"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'pyarrow'
ana@lab:~/roda$ source .venv/bin/activate
ana@lab:~/roda$ python3 -c "import pyarrow"
```

Não havia nada de errado com a instalação. Ativar o ambiente faz a mesma linha não imprimir nada, o que,
para um `import`, quer dizer que funcionou. No Windows, se o PowerShell se recusar a rodar o
`Activate.ps1` com uma mensagem sobre políticas de execução, rodar
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` uma vez libera os scripts feitos por você; esse
caso não foi rodado neste curso.

## A versão não existe para o seu Python

O `pip` responde a uma versão fixa que não encontra com a lista das que encontra:

```
ana@lab:~/roda$ pip install pyarrow==99.0.0 2>&1 | tail -2
ERROR: Could not find a version that satisfies the requirement pyarrow==99.0.0 (from versions: 0.9.0, 0.10.0, 0.11.0, 0.11.1, 0.12.0, 0.12.1, 0.13.0, 0.14.0, 0.15.1, 0.16.0, 0.17.0, 0.17.1, 1.0.0, 1.0.1, 2.0.0, 3.0.0, 4.0.0, 4.0.1, 5.0.0, 6.0.0, 6.0.1, 7.0.0, 8.0.0, 9.0.0, 10.0.0, 10.0.1, 11.0.0, 12.0.0, 12.0.1, 13.0.0, 14.0.0, 14.0.1, 14.0.2, 15.0.0, 15.0.1, 15.0.2, 16.0.0, 16.1.0, 17.0.0, 18.0.0, 18.1.0, 19.0.0, 19.0.1, 20.0.0, 21.0.0, 22.0.0, 23.0.0, 23.0.1, 24.0.0, 25.0.0, 25.0.1, 26.0.0)
ERROR: No matching distribution found for pyarrow==99.0.0
```

Aqui a versão foi digitada errada de propósito. A mesma mensagem aparece para uma versão que existe mas
não tem pacote para o seu Python, e esse é o caso mais provável: o pyarrow 26.0.0 precisa do Python 3.11
ou mais novo, e o Python do próprio Ubuntu 22.04 é o 3.10. Confira `python3 --version` primeiro. Se o
seu for mais antigo, a aula 1 de `python` instala um mais novo.

## Qualquer outra coisa

Dois hábitos resolvem quase tudo o que não está nesta lista. **Copie a última linha do erro num buscador,
entre aspas**: alguém já passou por isso. E **comece de novo do zero**, o que neste laboratório custa um
minuto: `rm -rf ~/roda`, e depois os comandos da seção anterior. Um laboratório que você pode jogar fora
e remontar é um laboratório que você não tem medo de quebrar, e o curso vai quebrá-lo de propósito mais
de uma vez.
