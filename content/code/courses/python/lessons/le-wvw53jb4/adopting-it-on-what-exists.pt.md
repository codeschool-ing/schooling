---
title: Vinte mil linhas sem anotação nenhuma
version: 1
---

O conselho é sempre "ligue o `--strict`", e numa base existente isso produz quatro mil erros, uma
tarde de desespero e um `# type: ignore` no topo de cada arquivo. Esta é a ordem que funciona no
lugar dele.

## 1. Ponha na CI no primeiro dia, frouxo

```toml
[tool.mypy]
files = ["app"]
```

Nada mais. Ele vai relatar quase nada, e **é esse o ponto**: o pipeline agora tem um passo que pode
ficar vermelho, e tudo o que vem depois disto é subir a régua numa coisa que já roda.

## 2. Ligue `check_untyped_defs`

```toml
check_untyped_defs = true
```

O ganho real mais barato que existe. Ele não pede anotação a ninguém e começa a verificar dentro
dos corpos de função que já existem, então os erros que ele acha são defeitos em vez de papelada.
Espere uma primeira leva, conserte, e ele fica quieto depois disso.

## 3. Impeça a metade sem anotação de crescer

```toml
[tool.mypy]
files = ["app"]
check_untyped_defs = true
disallow_untyped_defs = true

[[tool.mypy.overrides]]
module = ["app.legacy.*", "app.reports.*", "app.jobs.*"]
disallow_untyped_defs = false
```

**Este é o passo importante e é fácil de pular.** Estrito por padrão, com os módulos que não estão
prontos listados como exceções — então todo módulo NOVO é verificado direito desde a primeira linha,
e a lista de exceções só pode encolher.

Escrito ao contrário — frouxo por padrão, estrito numa lista de módulos prontos — a metade sem
anotação cresce toda semana e ninguém repara, porque nada muda de cor quando isso acontece.

## 4. Apague uma linha da lista de cada vez

Pegue o módulo do topo, anote, apague a linha dele e deixe a CI dizer o que quebrou. A lista agora é
uma lista de tarefas com um comprimento, que é uma coisa bem diferente de "a gente devia pôr tipos
um dia".

Anote assinaturas antes de locais: uma função com parâmetros e retorno anotados dá ao verificador
quase tudo de que ele precisa, e os locais em grande parte são inferidos.

## 5. `--strict` por último, se for o caso

Quando a lista de exceções estiver vazia você já tem a maior parte do que o `--strict` dá.
Acrescente o resto — `warn_return_any`, `disallow_any_generics`, `warn_unused_ignores` — uma flag
por pull request, cada uma com o seu próprio conserto pequeno.

## A regra do processo inteiro

**Nunca aceite um merge com um silêncio novo sem um motivo ao lado.** O estado que você está
tentando evitar não é "parte do código não é verificada" — é de onde você partiu. É uma base cheia
de comentários mandando um verificador ficar quieto, em que ninguém lembra quais deles sustentam
alguma coisa.
