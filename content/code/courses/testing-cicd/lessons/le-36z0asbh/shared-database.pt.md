---
title: Quando o banco é compartilhado
version: 1
---

O `shipquote` consegue dar a cada teste o próprio arquivo SQLite porque o SQLite é um arquivo. Um
servidor PostgreSQL é diferente: subir um por teste leva segundos, então uma suíte costuma dividir um
servidor, e muitas vezes um banco, entre todos os testes. Aí o isolamento deixa de ser de graça e
precisa ser desenhado. Há três desenhos comuns, e o repositório onde este curso é publicado usa o
terceiro.

## Uma transação por teste, desfeita no fim

A fixture abre uma transação antes do teste e faz rollback depois, então nada que o teste gravou
sobrevive:

```python
@pytest.fixture
def db(connection):
    tx = connection.begin()
    yield connection
    tx.rollback()
```

Este esboço não faz parte do `shipquote`, e mostra a forma, não uma biblioteca específica. É rápido,
porque um rollback quase não custa. Quebra quando o código testado faz commit por conta própria,
abre uma segunda conexão que não enxerga as linhas não confirmadas, ou depende de algo que só
acontece no commit, como uma restrição adiada.

## Um esquema novo por execução

Crie um banco vazio, ou um esquema com nome aleatório, quando a suíte começa, rode as migrações e
apague no fim. Todos os testes da execução o dividem, e as execuções não dividem nada entre si. É
simples e pega o comportamento do commit, ao preço de os testes de uma mesma execução verem as
linhas uns dos outros.

## Testes que só olham as próprias linhas

O terceiro desenho aceita que o banco é compartilhado e escreve cada teste de modo que **não
importe quem mais está lá**. O `CLAUDE.md` deste repositório diz isso em três regras, sob o título
*A test does not own the database* (um teste não é dono do banco), porque o `go test` roda pacotes
em paralelo contra um só PostgreSQL:

> - **Never `TRUNCATE` a shared table.** It is not tidying up, it is deleting another package's
>   rows halfway through its run.
> - **Never seed a fixed unique value.** Two packages inserting the school `code` collide on the
>   unique index, and which one loses is a matter of timing.
> - **Scope every assertion to the rows the test wrote** — `WHERE tenant_id = $1`, not
>   `count(*)`.

Ou seja: nunca dar `TRUNCATE` numa tabela compartilhada, porque isso apaga as linhas de outro pacote
no meio da execução dele; nunca inserir um valor único fixo, porque dois pacotes colidem no índice
único e qual perde é questão de tempo; e restringir cada verificação às linhas que o teste gravou. O
mesmo arquivo conta como as regras foram aprendidas: uma chave duplicada levantada em dois pacotes
ao mesmo tempo na CI, depois de passar localmente só por sorte no tempo. **Uma suíte que passa por
sorte é pior do que uma que falha**, porque a sorte acaba no push de outra pessoa.

## Como isso se aplica ao shipquote

`test_recent_lists_the_newest_first`, da aula 1, já segue a terceira regra sem precisar: afirma
`recent(2) == [second, first]`, usando os ids que recebeu de volta, em vez de afirmar quantas linhas
a tabela tem. O teste que falhou na seção 03, `recent(10) == []`, quebrava a regra, e quebrou
exatamente quando o banco passou a ser compartilhado. Um teste escrito sobre as próprias linhas
sobrevive a uma mudança de escopo da fixture; um teste escrito sobre a tabela inteira não.

As fábricas da próxima seção ajudam com a segunda regra também: um valor que precisa ser único é
gerado, não digitado.
