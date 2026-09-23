---
title: O que tem dentro de uma, e por que ela é comitada
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 286\" role=\"img\" aria-label=\"Uma faixa declarada é uma pergunta, e a resposta muda conforme o índice muda: a mesma faixa resolve numa versão hoje e numa mais nova daqui a seis meses. Um arquivo de trava registra a versão exata e o hash de cada pacote, então a segunda instalação produz os mesmos bytes da primeira.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <rect x=\"190\" y=\"26\" width=\"340\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pyproject.toml — requests&gt;=2.31</text> <text x=\"300\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">hoje</text> <text x=\"520\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">seis meses depois</text> <text x=\"20\" y=\"113\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem arquivo de trava</text> <rect x=\"220\" y=\"96\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"300\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.31.0</text> <rect x=\"440\" y=\"96\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"520\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.34.2</text> <path d=\"M386 113 L434 113\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"20\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">com uv.lock ao lado</text> <rect x=\"220\" y=\"156\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"300\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.31.0</text> <rect x=\"440\" y=\"156\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"520\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">2.31.0</text> <path d=\"M386 173 L434 173\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">cada pacote fixado, com o hash do arquivo</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A trava guarda os cinco que você pediu E os quarenta que eles pediram.</text> <text x=\"360\" y=\"267\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Essa segunda metade é a que ninguém anota à mão.</text> </svg>", "caption": "A faixa diz o que você aceita. A trava diz o que você de fato recebeu, e é a segunda que um colega precisa."}
```

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
uv lock --upgrade-package requests   # one package, everything else held
uv lock --upgrade                    # everything, within the declared ranges
```

Atualizar uma coisa é um diff pequeno e revisável. Atualizar tudo é um diff que ninguém lê, e
pertence a um pull request próprio com os testes rodados contra ele.

## Na CI

```sh
uv lock --check        # is the lock consistent with pyproject.toml?
uv sync --frozen       # install from the lock, do not resolve
```

```sh
The lockfile at `uv.lock` needs to be updated, but `--locked` was provided.
```

A primeira é o que pega alguém acrescentando uma dependência e esquecendo de comitar a trava. A
segunda é o que uma implantação roda: ela instala o que foi testado e não pode resolver para outra
coisa no dia em que o índice mudar.

Os equivalentes do Poetry são `poetry check --lock` e `poetry install --sync`.
