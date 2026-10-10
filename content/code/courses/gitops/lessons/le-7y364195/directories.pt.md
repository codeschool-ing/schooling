---
title: Ambientes são pastas, não branches
version: 1
---

**Um jeito óbvio de modelar ambientes no Git é um branch por ambiente**: um branch `staging` e um
`production`, com a promoção sendo um merge de um no outro. Fica bonito num quadro branco e falha na
prática, por motivos que vêm todos do que um merge faz.

- **Um merge leva tudo.** Levar o `staging` para o `production` traz cada commit do `staging`,
  inclusive os que são só do staging de propósito: o log extra de depuração, a referência às
  credenciais de teste, o número menor de réplicas. Mantê-los de fora pede cherry-picks, e um
  histórico de cherry-picks é um que ninguém consegue ler.
- **Os branches se afastam.** Cada branch acumula as próprias correções, e depois de alguns meses um
  diff entre `staging` e `production` mostra centenas de linhas, a maioria escolhida por ninguém. A
  diferença que importa, o release sendo promovido, se perde no meio delas.
- **O que é diferente fica invisível.** Num branch só, a diferença entre dois ambientes são dois
  arquivos lado a lado que quem revisa consegue comparar. Em dois branches é um diff entre branches que
  ninguém roda.

**Um branch, a `main`, e uma pasta por ambiente** evita os três. Promover é um pull request que muda a
pasta da produção para dizer o que a do staging já diz, e o diff dele é exatamente a promoção. O estado
presente de todo ambiente se lê num checkout só, num commit só. O Argo CD e o Flux são feitos para essa
organização: uma Application ou uma Kustomization aponta para um caminho, e todo caminho segue a `main`.
