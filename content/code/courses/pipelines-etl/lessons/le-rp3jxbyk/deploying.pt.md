---
title: Merge, tag, deploy
version: 1
---

Antes de a mudança sair da branch dela, a bateria da lição 17 roda sobre ela — os testes de unidade, e
o teste de integração contra o seu próprio warehouse:

```
ana@vm:~/etl$ python -m pytest -q tests
..........                                                               [100%]
10 passed in 9.85s
```

Depois a mudança é commitada com uma mensagem que diz por quê, juntada à `main` e ganha uma versão:

```
ana@vm:~/etl$ git add shop && git commit -q -m "stg_books: categories start with a capital, whatever the publisher sends" && git switch -q main && git merge -q --ff-only initcap-categories && git log --oneline
b0fa055 stg_books: categories start with a capital, whatever the publisher sends
cdef2c0 The nightly as it runs today
ana@vm:~/etl$ git tag -a v1.1.0 -m "Categories start with a capital" && git tag -n
v1.0.0          The nightly as it runs today
v1.1.0          Categories start with a capital
```

`v1.1.0` e não `v2.0.0`, e o número é uma mensagem. Uma convenção comum, o **versionamento
semântico**, lê uma versão como *maior.menor.correção*. A correção é para um conserto que não muda
nenhuma saída, a menor para uma mudança que acrescenta ou muda comportamento sem quebrar quem lê o
resultado, e a maior para uma que quebra: uma coluna renomeada, uma tabela removida, um grão
diferente. Com a primeira tentativa, que renomeava cinco categorias que os relatórios filtram, esta
teria sido uma versão maior. Isso dá um bom teste de se uma mudança foi intencional: *eu chamaria isto
de 2.0 sem problema?*

Fazer o deploy é mover a produção para a tag nova e construí-la:

```
ana@vm:~/etl-prod$ git checkout -q v1.1.0 && git describe --tags
v1.1.0
ana@vm:~/etl-prod$ dbt build --project-dir shop --target prod 2>&1 | grep -E "stg_books|daily_sales |Done"
07:37:31  1 of 16 START sql view model dbt_staging.stg_books ............................. [RUN]
07:37:31  1 of 16 OK created sql view model dbt_staging.stg_books ........................ [CREATE VIEW in 0.27s]
07:37:32  13 of 16 START sql table model dbt_marts.daily_sales ........................... [RUN]
07:37:32  13 of 16 OK created sql table model dbt_marts.daily_sales ...................... [INSERT 0 7298 in 0.22s]
07:37:32  Done. PASS=14 WARN=1 ERROR=0 SKIP=0 NO-OP=1 REUSED=0 TOTAL=16
```

O `git describe --tags` diz em que versão a produção está, que é a primeira pergunta a fazer quando um
número parece errado de manhã. O build rodou o projeto inteiro com o target `prod`, e os dois modelos
que a mudança tocou estão entre os dezesseis nós. O único aviso é o dos clientes apagados da lição 12,
ainda conhecidos e ainda lícitos.

Numa equipe, os mesmos passos são dados por uma máquina. Os testes e a comparação rodam quando uma
mudança é proposta; o merge espera por eles; a tag e o build vêm depois. Essa maquinaria — integração e
entrega contínuas — não está montada no laboratório, e cada passo que ela rodaria é um comando que
esta seção já mostrou.
