---
title: Dependency confusion e typosquatting, do lado de quem defende
version: 1
---

Dois dos incidentes desta aula não precisaram de invasão nenhuma. Ninguém roubou uma conta nem mexeu
num servidor de build: alguém publicou um pacote com um nome, e as próprias ferramentas das vítimas
escolheram instalá-lo. **A falha estava em como o instalador escolhe um pacote, e a defesa está no mesmo
lugar.**

### Dependency confusion

Uma empresa com pacotes privados costuma servi-los de um índice próprio, e aponta os instaladores para
esse índice e para o público ao mesmo tempo. A armadilha está no "ao mesmo tempo". **O pip trata todo
índice que recebe como um único conjunto de candidatos e instala a versão mais alta que encontra**, onde
quer que a tenha encontrado. Se o nome de um pacote privado está livre no PyPI, qualquer pessoa pode
registrá-lo lá com um número de versão alto, e todo instalador apontado para os dois índices o prefere.
Foi assim que o `torchtriton` chegou aos usuários do nightly do PyTorch: o nome existia no índice do
PyTorch e ninguém o tinha registrado no PyPI.

Você consegue ver a regra na sua própria máquina sem ninguém publicar nada. Um nome que já existe no
PyPI se comporta exatamente como o seu se comportaria no dia em que alguém o registrasse, então pegue
`packaging` e faça uma versão 0.1 sua, do jeito que um pacote interno seria feito. Dois arquivos bastam.
Salve o primeiro como `~/supply/internal/pyproject.toml`:

```toml
[project]
name = "packaging"
version = "0.1"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

E o próprio módulo, que só precisa existir, como `~/supply/internal/src/packaging/__init__.py`:

```python
"""Our own packaging, version 0.1, on our own index."""
```

Construa a wheel num diretório organizado como índice, um diretório por pacote dentro de `simple/`, e
sirva-o em `127.0.0.1:8081` com `python3 -m http.server 8081 --bind 127.0.0.1 --directory index` num
segundo terminal. O pip lê uma listagem simples de diretório como índice.

```
(supply) ana@vm:~/supply$ uv build -q --wheel -o index/simple/packaging/ internal
(supply) ana@vm:~/supply$ ls index/simple/packaging
packaging-0.1-py2.py3-none-any.whl
```

Aponte o pip **só** para o seu índice, com `--index-url`, e ele só consegue achar o seu pacote:

```
(supply) ana@vm:~/supply$ pip download --no-deps -d got --index-url http://127.0.0.1:8081/simple/ packaging
Looking in indexes: http://127.0.0.1:8081/simple/
Collecting packaging
  Downloading packaging-0.1-py2.py3-none-any.whl (942 bytes)
Saved ./got/packaging-0.1-py2.py3-none-any.whl
Successfully downloaded packaging
```

Agora o arranjo que a maioria dos times de fato escreve, o índice privado **somado** ao PyPI com
`--extra-index-url`:

```
(supply) ana@vm:~/supply$ pip download --no-deps -d got --extra-index-url http://127.0.0.1:8081/simple/ packaging
Looking in indexes: https://pypi.org/simple, http://127.0.0.1:8081/simple/
Collecting packaging
  Downloading packaging-26.3-py3-none-any.whl.metadata (3.5 kB)
Downloading packaging-26.3-py3-none-any.whl (129 kB)
Saved ./got/packaging-26.3-py3-none-any.whl
Successfully downloaded packaging
(supply) ana@vm:~/supply$ ls got
packaging-0.1-py2.py3-none-any.whl
packaging-26.3-py3-none-any.whl
```

O pip olhou nos dois, achou a 0.1 no seu e a 26.3 no PyPI, e ficou com a 26.3. Aqui a 26.3 é o
`packaging` de verdade e inofensivo; no dia em que a versão mais alta for de outra pessoa, é a mesma
decisão. **Nada na saída avisa você**, porque do ponto de vista do pip nada deu errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"sp-l12-confusion\" aria-label=\"Dois índices oferecem um pacote chamado packaging: o seu índice tem a versão 0.1 e o PyPI tem a 26.3. O pip com --extra-index-url põe os dois num só conjunto e instala a versão mais alta, a 26.3 do PyPI. O uv, por padrão, para no primeiro índice que tem o nome, o seu, e instala a 0.1. Com --index-url e um índice só, não há o que escolher.\"><defs><marker id=\"sp-l12-confusion-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l12-confusion-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l12-confusion-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o seu índice</text><text x=\"105.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">packaging 0.1</text><rect x=\"20\" y=\"130\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PyPI</text><text x=\"105.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">packaging 26.3</text><rect x=\"280\" y=\"30\" width=\"220\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pip --extra-index-url</text><text x=\"390.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um conjunto só, vence a versão mais alta</text><rect x=\"280\" y=\"130\" width=\"220\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uv, por padrão</text><text x=\"390.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primeiro índice que tem o nome</text><path d=\"M190 58 L278 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-paper-dim)\"></path><path d=\"M190 158 L278 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-paper-dim)\"></path><path d=\"M190 58 L278 150\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-phosphor)\"></path><rect x=\"570\" y=\"30\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">instala</text><text x=\"635.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26.3</text><rect x=\"570\" y=\"130\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">instala</text><text x=\"635.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M500 58 L568 58\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-amber)\"></path><path d=\"M500 158 L568 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l12-confusion-ah-phosphor)\"></path></svg>", "caption": "Os mesmos dois índices, duas regras. Na do pip, vence quem publica a versão mais alta.", "same": ["PyPI"]}
```

O uv, que este curso usa em todo o resto, decidiu o contrário por padrão. Ele para no primeiro índice
que tem o pacote, e põe o índice extra antes do PyPI:

```
(supply) ana@vm:~/supply$ uv pip install --dry-run --extra-index-url http://127.0.0.1:8081/simple/ packaging
Resolved 1 package in 17ms
Would download 1 package
Would install 1 package
 + packaging==0.1
(supply) ana@vm:~/supply$ uv pip install --dry-run --index-strategy unsafe-best-match --extra-index-url http://127.0.0.1:8081/simple/ packaging
Resolved 1 package in 6ms
Would install 1 package
 + packaging==26.3
```

`--index-strategy unsafe-best-match` devolve o comportamento do pip, e o nome diz o que o uv pensa dele.

### As defesas, da mais forte para a mais fraca

- **Um índice só.** Os instaladores apontam para um único índice que a empresa controla, que faz proxy do
  PyPI e serve os pacotes privados, e decide num lugar só qual nome vem de onde. Produtos como
  Artifactory, Nexus e devpi fazem isso. `--index-url` para esse índice e nada mais.
- **Hashes.** Um lock com o hash de cada arquivo recusa um arquivo que não é o revisado, seja qual for o
  índice que o oferece. A seção anterior mostrou o pip fazendo isso.
- **Registre os seus nomes.** Registre cada nome interno no índice público como um pacote vazio,
  reservando o lugar, como o PyTorch fez com o nome para o qual moveu a dependência depois do incidente.
  Fecha a porta para esses nomes e nenhum outro.
- **Um resolvedor que não mistura índices**, como o padrão do uv, ou um escopo ou namespace onde o
  ecossistema tem um, como os escopos `@empresa/` do npm.

### Typosquatting

O typosquatting conta com uma pessoa em vez de um resolvedor: um pacote com o nome a uma tecla de
distância de um popular, esperando alguém digitar o nome errado uma vez, num terminal ou num arquivo de
requirements. O SLSA o põe na letra H, a escolha do pacote. **Um erro de digitação num arquivo de
requirements é uma dependência que ninguém escolheu**, e as defesas tratam de tornar a escolha visível:

- uma dependência nova chega num pull request, onde o diff do lockfile mostra o nome exato, e quem
  revisa o lê com o mesmo cuidado que código;
- copie o comando de instalação da documentação do próprio projeto em vez de digitá-lo;
- um nome novo para o projeto merece uma olhada na página dele no índice: quem publica, desde quando,
  quantos dependem dele. A aula 15 transforma essa leitura num hábito.

Nem a confusion nem o typosquatting precisam de uma vulnerabilidade no seu código. Os dois só precisam
que um nome chegue ao seu instalador, e os dois são barrados antes de o primeiro byte do pacote rodar.
