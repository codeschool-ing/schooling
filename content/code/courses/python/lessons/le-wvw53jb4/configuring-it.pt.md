---
title: `pyproject.toml`, e a exceção por módulo
version: 1
---

```toml
[tool.mypy]
python_version = "3.12"
files = ["app"]
strict = true
```

```sh
mypy        # sem argumento: lê a configuração e verifica o que ela nomeia
```

Ajustes num arquivo em vez de numa linha de comando, para que o seu editor, o seu terminal e a CI
rodem a mesma verificação. Uma flag que alguém passa localmente e a CI não passa é um build verde
numa máquina e vermelho na outra, para o mesmo commit.

`python_version` importa mais do que parece: decide em qual sintaxe e em quais assinaturas da
biblioteca padrão o verificador acredita. Ponha o que você implanta.

## A exceção, que é como a adoção realmente acontece

```toml
[tool.mypy]
files = ["app"]
disallow_untyped_defs = true

[[tool.mypy.overrides]]
module = ["app.legacy.*"]
disallow_untyped_defs = false
```

**Estrito em toda parte, frouxo num lugar nomeado.** Sem a exceção a passagem relata
`app/legacy/old.py:1: error: Function is missing a type annotation`; com ela, `Success: no issues
found in 4 source files` — e o resto do pacote continua estrito.

Os colchetes duplos são o array de tabelas do TOML: você escreve o bloco de novo para o próximo
módulo, e `module` recebe uma lista, então um bloco pode nomear vários.

## O terceiro que não tem anotação

```toml
[[tool.mypy.overrides]]
module = ["algumalibvelha.*"]
ignore_missing_imports = true
```

Limitado à biblioteca que é o problema. Um `ignore_missing_imports = true` lá em cima silencia a
mensagem para tudo, inclusive para a importação que você escreveu errado — que é o assunto da
próxima seção.

## O que não pôr nele

`exclude` parece a ferramenta para um diretório para o qual você não está pronto, e é a errada: um
módulo excluído continua sendo IMPORTADO pelos módulos que você verifica, então os erros dele
voltam pela porta da frente e você deixou o relatório confuso em vez de menor. Uma exceção com as
flags afrouxadas o mantém verificado num nível em que ele passa.
