---
title: O que tem dentro de uma, e por que ela é comitada
version: 1
---

```toml
[[package]]
name = "certifi"
version = "2026.7.22"
source = { registry = "https://pypi.org/simple" }
sdist = { url = "https://files.pythonhosted.org/.../certifi-2026.7.22.tar.gz",
          hash = "sha256:741e2c3b351ddf…", size = 138112 }
wheels = [
    { url = "https://files.pythonhosted.org/.../certifi-2026.7.22-py3-none-any.whl",
      hash = "sha256:62f22742b58a1a33…", size = 136983 },
]
```

Uma entrada por pacote, para **todo** pacote — os cinco que você pediu e os quarenta que eles
pediram. Uma versão exata, de onde ele veio, e o hash do arquivo. O `uv.lock` de um projeto com
uma dependência e uma ferramenta de desenvolvimento tem duzentas linhas; o `poetry.lock` do mesmo
projeto tem trezentas.

## O que ela garante

Que duas instalações produzem os mesmos bytes. O `pyproject.toml` diz `requests>=2.31`, que era
verdade da 2.31.0 em março e é verdade da 2.34.2 hoje; a trava diz qual, e o hash diz qual
arquivo.

A quinta-feira da aula 18 — uma dependência transitiva se movendo sob uma fixação que parecia
exata — não pode acontecer, porque a metade transitiva também está fixada.

## Ela é comitada, e nunca editada

Ela vai para o git, como qualquer outro fato sobre o projeto. Ela é gerada, então um conflito nela
se resolve regerando e não mesclando — um `uv lock` ou `poetry lock` depois de pegar o
`pyproject.toml` do outro lado.

**Uma edição à mão é a única coisa que quebra a garantia**, porque os hashes deixam de bater com o
que as versões afirmam e nada confere isso até uma instalação falhar em outro lugar.

## `install` contra `sync`

```sh
$ uv sync --no-dev
Uninstalled 5 packages in 4ms
 - pytest==9.1.1
 …
```

O `install` garante que tudo o que está no arquivo está presente. **O `sync` faz o ambiente ficar
igual ao arquivo**, o que quer dizer remover o que não está nele.

A diferença é uma dependência que alguém apagou três meses atrás e que continua instalada numa
máquina — a máquina em que o defeito não se reproduz.

## Atualizar

```sh
uv lock --upgrade-package requests   # um pacote, todo o resto segurado
uv lock --upgrade                    # tudo, dentro das faixas declaradas
```

Atualizar uma coisa é um diff pequeno e revisável. Atualizar tudo é um diff que ninguém lê, e
pertence a um pull request próprio com os testes rodados contra ele.

## Na CI

```sh
uv lock --check        # a trava está coerente com o pyproject.toml?
uv sync --frozen       # instale da trava, não resolva
```

```sh
The lockfile at `uv.lock` needs to be updated, but `--locked` was provided.
```

A primeira é o que pega alguém acrescentando uma dependência e esquecendo de comitar a trava. A
segunda é o que uma implantação roda: ela instala o que foi testado e não pode resolver para outra
coisa no dia em que o índice mudar.

Os equivalentes do Poetry são `poetry check --lock` e `poetry install --sync`.
