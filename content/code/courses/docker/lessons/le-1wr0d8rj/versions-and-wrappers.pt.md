---
title: A versão certa, toda vez
version: 1
---

**A versão de uma ferramenta faz parte da tag da imagem, então rodar duas versões lado a lado é
escolher duas tags.** Isso vale mais do que parece: "funciona com o meu Python" deixa de ser uma
conversa quando a versão está escrita no comando.

## Dois Pythons, um script

Um colega da Ana escreveu um script curto que usa o `copy.replace`, uma função acrescentada à
biblioteca padrão no Python 3.13:

```python
import copy
from dataclasses import dataclass

@dataclass(frozen=True)
class Loan:
    book: str
    days: int

first = Loan("Dom Casmurro", 14)
renewed = copy.replace(first, days=28)
print(renewed)
```

A Ana o roda no 3.13 e no 3.12, sem instalar nenhum dos dois para isso:

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work python:3.13-slim python stats.py
Loan(book='Dom Casmurro', days=28)
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work python:3.12-slim python stats.py
Traceback (most recent call last):
  File "/work/stats.py", line 10, in <module>
    renewed = copy.replace(first, days=28)
              ^^^^^^^^^^^^
AttributeError: module 'copy' has no attribute 'replace'
```

**O mesmo arquivo, duas respostas**, e a segunda é o relato de bug que alguém rodando o 3.12 na
própria máquina teria mandado. A tag `python:3.12-slim` é o ambiente inteiro: ninguém precisa
perguntar qual Python o outro tem.

## Os arquivos que a ferramenta escreve pertencem ao usuário do container

A aula 8 mostrou isso para um container de vida longa, e vale ainda mais para ferramentas, porque
elas rodam o dia todo nos seus próprios diretórios:

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work python:3.13-slim python -c "open('out.txt', 'w').write('x')"
ana@vm:~/ops$ ls -l out.txt
-rw-r--r-- 1 root root 1 Oct  6 13:52 out.txt
ana@vm:~/ops$ rm -f out.txt
ana@vm:~/ops$ docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/work -w /work python:3.13-slim python -c "open('out.txt', 'w').write('x')"
ana@vm:~/ops$ ls -l out.txt
-rw-r--r-- 1 ana ana 1 Oct  6 13:52 out.txt
```

O primeiro arquivo pertence ao `root`, porque a imagem `python` roda como root. Com o `--user`
definido como os números de usuário e grupo da própria Ana, o segundo é dela. **Qualquer ferramenta
que escreva no seu diretório deve receber `--user "$(id -u):$(id -g)"`**; ferramentas que só leem,
como os linters acima, não precisam.

## Fazendo parecer instalada

Digitar o `docker run` inteiro toda vez cansa rápido. Uma função de shell com o nome da ferramenta o
esconde, e a Ana guarda as dela num arquivo:

```schooling-example
{"language": "sh", "file": "tools.sh", "parts": [{"code": "# Tools that run in containers. Source this file from ~/.bashrc to keep them.\n", "note": "Um comentário para quem abrir o arquivo depois: para que ele serve e como é carregado."}, {"code": "yq() {\n  docker run --rm -i \\\n", "note": "Uma função de shell com o nome da ferramenta, para que digitar `yq` a rode. O `--rm` limpa, o `-i` mantém a entrada padrão aberta para dar para mandar um arquivo por pipe."}, {"code": "    -v \"$PWD\":/work -w /work \\\n", "note": "O diretório atual, montado e transformado em diretório de trabalho, para que caminhos relativos se comportem como no host."}, {"code": "    --user \"$(id -u):$(id -g)\" \\\n", "note": "O container roda com o usuário e o grupo da própria Ana, então todo arquivo que o `yq` escrever é dela."}, {"code": "    mikefarah/yq:4 \"$@\"\n}\n\n", "note": "A imagem, com a versão principal fixada, e o `\"$@\"`: cada argumento que a Ana digitou, repassado exatamente como foi digitado."}, {"code": "shellcheck() {\n  docker run --rm -v \"$PWD\":/mnt -w /mnt \\\n    koalaman/shellcheck:stable \"$@\"\n}\n", "note": "O mesmo padrão para o ShellCheck. Ele só lê arquivos, então não precisa de `--user` nem de `-i`."}]}
```

```
ana@vm:~/ops$ . ./tools.sh
ana@vm:~/ops$ yq ".database.pool" config.yaml
10
ana@vm:~/ops$ shellcheck --severity=warning backup.sh; echo "exit status $?"
exit status 0
```

Depois de carregar o arquivo, `yq` e `shellcheck` são funções, e se comportam como comandos
instalados sobre arquivos do diretório atual. O `--severity=warning` esconde o nível `info` do
ShellCheck, onde estava o SC2086, então desta vez ele não informa nada e sai com 0. Pôr
`. ~/ops/tools.sh` no `~/.bashrc` mantém as funções em todo shell novo.

Dois detalhes tornam as funções confiáveis. **A tag está escrita**, `yq:4` e `shellcheck:stable`,
então a ferramenta não muda de versão sem aviso; para uma ferramenta de cuja saída um pipeline
depende, fixe a versão exata, como a aula 16 recomenda. E **o `"$@"` repassa cada argumento intacto**,
com aspas e espaços, que é a diferença entre um invólucro e uma fonte de bugs estranhos.
