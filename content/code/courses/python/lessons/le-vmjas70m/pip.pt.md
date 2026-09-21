---
title: `python -m pip`, e por que não `pip`
version: 1
---

```sh
python -m pip install requests
python -m pip uninstall requests
python -m pip list
python -m pip show requests
python -m pip install --upgrade requests
```

**Escreva `python -m pip`, não `pip`.** São o mesmo programa alcançado de dois jeitos, e a
diferença é em qual interpretador ele instala.

`pip` é um script pequeno com um caminho de interpretador escrito na primeira linha, e o que o seu
shell acha é o que vier primeiro no `PATH`. `python -m pip` roda o `pip` pertencente ao `python`
que você acabou de rodar — que é o ambiente em que você está, por construção.

A falha que isso evita é silenciosa: a instalação funciona, relata sucesso, e o import falha
porque a biblioteca foi para outro lugar.

## `list` e `show`

```text
$ python -m pip list
Package            Version
------------------ ---------
certifi            2026.7.22
charset-normalizer 3.5.1
idna               3.20
requests           2.31.0
urllib3            2.8.0
```

Cinco pacotes depois de instalar um. Os outros quatro são o de que o `requests` precisa, e esta é
a primeira aparição da distinção de que as duas próximas seções tratam.

```text
$ python -m pip show requests
Location: /tmp/projeto/.venv/lib/python3.11/site-packages
Requires: certifi, charset-normalizer, idna, urllib3
Required-by:
```

`Location` é onde ele de fato caiu, e é a primeira coisa a olhar quando um import acha a cópia
errada. `Requires` e `Required-by` são as duas direções do grafo de dependências; `Required-by`
vazio é como você sabe que o `requests` é algo que você pediu e não algo que veio junto.

## `uninstall` remove uma coisa

```sh
python -m pip uninstall requests
```

Ele remove o `requests` e deixa `certifi`, `idna`, `charset-normalizer` e `urllib3` para trás. Ele
não tem conceito de "não é mais necessário", então um ambiente em que se instalou e desinstalou
por um ano guarda uma camada de coisas que nada usa.

É um dos argumentos para as ferramentas da próxima aula, e nesse meio-tempo a resposta é a de
cima: apague o diretório e reconstrua.

## `--upgrade` e o que ele decide

```sh
python -m pip install --upgrade requests
```

Sem ele, um `install` em algo já presente não faz nada. Com ele, o `pip` pega a versão mais nova
que satisfaz o especificador — e pode atualizar os outros quatro pacotes também, porque as versões
deles têm de satisfazer o que o `requests` novo pede.

Não existe um comando "atualize tudo", de propósito. `pip list --outdated` diz o que se moveu, e
você decide.
