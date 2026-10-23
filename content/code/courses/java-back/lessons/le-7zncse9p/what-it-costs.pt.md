---
title: Quanto custa um contêiner
version: 1
---

"Testes de integração são lentos" é algo muito dito e pouco medido, e a medida muda o conselho. Aqui
estão os dois comandos no mesmo projeto, um depois do outro, com o cache aquecido e as duas imagens já
na máquina:

```
ana@vm:~/bookshop$ mvn -B test 2>&1 | grep -E 'Skipped: 0$|Total time'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] Total time:  2.461 s
```

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E 'Skipped: 0$|Total time|started in PT|Started .*IT in'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
2026-10-22T20:30:14.184-03:00  INFO 31645 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 started in PT0.340325083S
2026-10-22T20:30:15.522-03:00  INFO 31645 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.332489607S
2026-10-22T20:30:18.253-03:00  INFO 31645 --- [bookshop] [           main] [] c.e.bookshop.BookshopApplicationIT       : Started BookshopApplicationIT in 6.186 seconds (process running for 7.01)
2026-10-22T20:30:19.854-03:00  INFO 31645 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.358918883S
2026-10-22T20:30:20.241-03:00  INFO 31645 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : Started BookRepositoryIT in 0.38 seconds (process running for 8.998)
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] Total time:  14.530 s
```

Dois segundos e meio de Maven para os dezessete testes de unidade, e catorze e meio para os mesmos
dezessete mais três testes de integração: cerca de seis vezes mais, por três testes. Os tempos mudam de
uma execução para outra (o mesmo `mvn verify` na seção anterior a esta levou 14.740 s), então leia as
proporções, não os dígitos.

## Para onde foram os segundos

Leia as linhas da segunda execução umas contra as outras. **Os contêineres não são a parte cara.** O
Ryuk subiu em cerca de um terço de segundo e cada PostgreSQL em cerca de 1,3 segundo, incluindo a
espera até aceitar conexões. O que levou a maior parte do tempo foi o Spring: o contexto inteiro da
aplicação, para o `BookshopApplicationIT`, precisou de 6,2 segundos, enquanto a fatia de persistência do
`BookRepositoryIT` ficou pronta em menos de 0,4. Montar o jar também entra no total,
porque `verify` vem depois de `package`.

Então o custo de um teste de integração é, na maior parte, o contexto que ele sobe, e daí saem dois
hábitos.

**Compartilhe um contexto, e o contêiner vem junto.** O framework de testes do Spring guarda um
contexto depois de construído e o entrega a cada classe de teste seguinte com a mesma configuração: as
mesmas anotações, os mesmos perfis, os mesmos imports. Uma segunda classe `@SpringBootTest` com
`@ActiveProfiles("test")` e `@Import(TestcontainersConfiguration.class)` reaproveitaria os seis segundos
e o banco da primeira. Dê a ela outro perfil, ou outra classe para importar, e ela constrói um contexto,
e um contêiner, só dela.

**Um campo `static @Container` é um contêiner por classe.** O `BookRepositoryIT` subiu o próprio
PostgreSQL, um segundo, porque o contêiner dele pertence à classe e não a um contexto. Isso é certo para
uma classe que quer um banco que ninguém mais tocou, e um desperdício para dez classes que ficariam
felizes em dividir um. O estilo do bean compartilha; o do campo isola.

## Quanto custa da primeira vez

Nenhum dos números acima inclui um download. A primeira execução numa máquina nova baixa as imagens, e
elas ficam no disco depois:

```
ana@vm:~/bookshop$ docker image ls --format '{{.Repository}}:{{.Tag}}  {{.Size}}' | grep -E 'postgres|ryuk'
postgres:16-alpine  420MB
testcontainers/ryuk:0.14.0  4.83MB
```

Quanto tempo isso leva depende da conexão, uma vez só. `docker image rm postgres:16-alpine` devolve o
espaço e faz a próxima execução baixar a imagem de novo.

## Qual execução, e quando

Uma suíte de testes que as pessoas param de rodar não protege nada, e a divisão desta aula é o que a
mantém rápida o bastante para ser rodada. **Muitos testes de unidade, com `mvn test`, enquanto você
trabalha**: alguns segundos, sem Docker, a lógica do serviço conferida com mocks. **Menos testes de
integração, com `mvn verify`, antes do commit**: as consultas, as migrações e a configuração, contra o
banco em que rodam em produção. A aula 20 acrescenta HTTP aos testes de integração, e `testing-cicd` faz
um servidor de build rodar `mvn verify` a cada mudança, onde ninguém consegue esquecer.
