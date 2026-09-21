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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"As mesmas duas ferramentas em três momentos: o editor formata ao salvar, o gancho formata o que está sendo commitado, e a CI confere sem reescrever e recusa. Só a última tem permissão de dizer não.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"132\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o editor, ao salvar</text> <text x=\"132\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">formata e organiza os imports</text> <text x=\"132\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">você nunca pensa nisso</text> <rect x=\"256\" y=\"34\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"368\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o gancho, no commit</text> <text x=\"368\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o mesmo, sobre o que está no stage</text> <text x=\"368\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada sem formatação é commitado</text> <path d=\"M246 52 L252 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"492\" y=\"34\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"604\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a CI, no push</text> <text x=\"604\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">--check: não reescreve, sai diferente de zero</text> <text x=\"604\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">e esta é a que recusa</text> <path d=\"M482 52 L488 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Ponha o linter DEPOIS da conferência do formatador, para que um arquivo apenas sem formatação</text> <text x=\"360\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">reprove na frase que diz isso em vez de numa lista de achados.</text> </svg>", "caption": "Formatar ao salvar é onde isto de fato funciona. Um formatador que você tem de lembrar de rodar é um por onde metade do repositório não passou."}
```

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
