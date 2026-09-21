---
title: Ao salvar, no pipeline, e antes do commit
version: 1
---

```json
// o editor
"editor.formatOnSave": true,
"editor.codeActionsOnSave": { "source.organizeImports.ruff": "explicit" }
```

**Formatar ao salvar é onde isto de fato funciona.** Um formatador que você tem de lembrar de
rodar é um formatador por onde metade do repositório não passou, e aí os diffs voltam a ser sobre
disposição.

## O pipeline

```yaml
- run: ruff format --check .
- run: ruff check .
```

`--check` não reescreve nada e sai diferente de zero. É esse o ponto inteiro de ele existir: a CI
relata uma discordância e não comita caladamente um conserto no ramo de outra pessoa.

Ponha o linter depois da checagem do formatador, para um arquivo que está apenas sem formatar
falhar na frase que diz isso e não numa lista de achados `E`.

## O gancho, e para que ele serve

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.16.8
    hooks:
      - id: ruff-check
        args: [--fix]
      - id: ruff-format
```

Fixe o `rev` na versão que você de fato tem, e deixe o `pre-commit autoupdate` movê-lo — um gancho
rodando um `ruff` diferente do da CI é um commit que passa localmente e falha no pipeline. O id
foi `ruff` por anos e agora é `ruff-check`; o nome antigo ainda funciona como apelido, que é por
que configurações velhas seguem rodando e ninguém repara na renomeação.

Um gancho de pre-commit roda as ferramentas antes de o commit ser feito, então o código que chega
ao ramo já está formatado. Vale ter e **não substitui a checagem na CI**: um gancho mora na
máquina de cada pessoa, pode ser pulado com `--no-verify`, e não está instalado na máquina de quem
entrou semana passada.

**A CI é o que é verdade. O gancho é o que é conveniente.**

## A ordem em que adotar isto

1. O formatador em tudo, num commit, com o `.git-blame-ignore-revs` configurado.
2. `--check` do formatador na CI no mesmo dia, ou o repositório volta a derivar em uma semana.
3. O linter com as regras padrão, que já quase passa.
4. Uma família por vez, cada uma no seu próprio pull request.

Fazer ao contrário — as regras interessantes primeiro — produz uma lista de quatro mil achados e
uma equipe que desliga a ferramenta.
