---
title: Cobertura, e o que ela não mede
version: 1
---

**A cobertura relata quais linhas do código rodaram enquanto os testes rodavam; ela não diz nada
sobre se alguma coisa conferiu o que essas linhas fizeram.** É um mapa do que não foi testado, e uma
nota ruim do que foi. O Vitest a mede pelo V8, o motor de JavaScript dentro do Node, com mais um
pacote na mesma versão do Vitest:

```
ana@dev:~/planner$ npm install --save-exact -D @vitest/coverage-v8@5.0.5

added 12 packages, and audited 89 packages in 2s

found 0 vulnerabilities
```

```
ana@dev:~/planner$ npx vitest run --coverage

 RUN  v5.0.5 /home/ana/planner
      Coverage enabled with v8


 Test Files  3 passed (3)
      Tests  25 passed (25)
   Start at  19:53:15
   Duration  936ms (environment 66%, transform 15%, worker 8%, tests 7%, import 5%)

 % Coverage report from v8
No files with missing coverage.
3 files fully covered.

=============================== Coverage summary ===============================
Statements   : 100% ( 71/71 )
Branches     : 100% ( 26/26 )
Functions    : 100% ( 17/17 )
Lines        : 100% ( 62/62 )
================================================================================
```

**Cada linha, cada desvio e cada função: 100%.** Vinte e cinco testes alcançam todo o `planner.ts` e
todo o `view.ts`, e os únicos arquivos contados são os que algum teste importou. Agora leia o que ela
deixa de fora. O `main.ts` nem é contado, porque nenhum teste o importa: ele busca, espera, escuta o
`hashchange`, e nada disso é alcançável a partir do Node. E o `view.ts` a 100% ainda tem um campo sem
rótulo e um cinza que ninguém consegue ler, que as aulas 3 e 10 acham, porque nenhuma linha dele está
errada do jeito que uma linha pode estar errada.

O `main.ts` não é uma lacuna a preencher com um teste unitário mais esperto. É a parte do app que só
existe num navegador, e a aula 4 o testa lá.

## Por que não uma meta

Faça dos 100% uma regra e a suíte se enche de testes que rodam linhas sem conferir nada, já que esse é
o jeito mais barato de subir o número. **Uma linha pode rodar num teste e estar errada**: antes da
correção desta aula, um teste que chamasse o `weekOf` e conferisse só que ele devolve dois textos
teria coberto todas as linhas dele e não achado nada. O número seria perfeito e o planner, errado.

Então a regra que este curso segue é a que um teste vermelho ensina: escreva o teste que teria pegado
a falha que você acabou de achar, e o da falha que você consegue nomear antes de ela acontecer. A
cobertura diz onde ninguém olhou ainda; ela não consegue dizer quem olhou com cuidado.

O relatório vai para `coverage/`, que é saída e não fonte. Deixe-o fora do Git:

```
ana@dev:~/planner$ echo coverage >> .gitignore
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Unit and component tests with Vitest"
ana@dev:~/planner$ git log --oneline
9a0eaac Unit and component tests with Vitest
925ced3 Test the week, and compute it in UTC
050e2d3 The study planner
```
