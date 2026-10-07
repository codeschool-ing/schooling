---
title: Lendo uma execução vermelha
version: 1
---

Uma execução vermelha é informação, e a maior parte do trabalho depois dela é leitura. O hook do
laboratório guarda, para cada execução, o que cada célula produziu, o equivalente ao que serviços
hospedados chamam de **artefatos**: arquivos que um job salva para sobreviverem à máquina em que ele
rodou.

```
ana@laptop:~/shipquote$ ls ~/ci/runs/
1
2
3
4
ana@laptop:~/shipquote$ ls ~/ci/runs/4/
install-3.11.log
install-3.12.log
install-3.13.log
py3.11-America-Sao_Paulo.log
py3.11-America-Sao_Paulo.xml
py3.11-UTC.log
py3.11-UTC.xml
py3.12-America-Sao_Paulo.log
py3.12-America-Sao_Paulo.xml
py3.12-UTC.log
py3.12-UTC.xml
py3.13-America-Sao_Paulo.log
py3.13-America-Sao_Paulo.xml
py3.13-UTC.log
py3.13-UTC.xml
ana@laptop:~/shipquote$ grep -E "^(E |FAILED)" ~/ci/runs/4/py3.13-UTC.log
E       assert datetime.date(2026, 10, 6) == datetime.date(2026, 10, 5)
E        +  where datetime.date(2026, 10, 6) = dispatch_date(1791217800)
E        +  and   datetime.date(2026, 10, 5) = date(2026, 10, 5)
FAILED tests/test_dispatch.py::test_an_order_before_two_leaves_the_same_day
```

A execução 4 é a vermelha. Para cada versão do Python há um log de instalação, e para cada célula o
log de teste e um arquivo JUnit XML. JUnit XML é um formato que quase todo serviço de CI lê: é como um
serviço hospedado mostra uma lista de testes que falharam numa página em vez de uma parede de texto.
O log da célula UTC que falhou nomeia o teste e as duas datas: o código disse 6 de outubro onde o
teste esperava o dia 5.

## Corrigir, depois confirmar

A mudança é revertida em vez de remendada, porque reverter devolve a `main` a um commit que
sabidamente passa, e o colega pode trazer a simplificação de volta depois, com o fuso e um teste que
rode em UTC. A reversão é enviada e a CI confirma:

```
ana@laptop:~/shipquote$ git log --oneline -3
b33d78b Revert "Read the order time in local time, no zone table needed"
1247039 Read the order time in local time, no zone table needed
6b77129 Remove the carrier test until its data is committed
ana@laptop:~/shipquote$ time git push
remote: ci: run 5, commit b33d78b, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.96s        
remote: ci: 3.11  UTC                pass  41 passed, 2 skipped in 1.39s        
remote: ci: 3.12  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.97s        
remote: ci: 3.12  UTC                pass  41 passed, 2 skipped in 1.42s        
remote: ci: 3.13  America/Sao_Paulo  pass  41 passed, 2 skipped in 2.05s        
remote: ci: 3.13  UTC                pass  41 passed, 2 skipped in 1.43s        
remote: ci: run 5 passed        
To /home/ana/ci/shipquote.git
   1247039..b33d78b  main -> main

real	0m13.315s
user	0m6.250s
sys	0m1.046s
```

As seis células passam de novo. **A execução 5 é a prova de que a `main` está saudável**, e o hash do
commit na primeira linha dela, `b33d78b`, amarra essa prova a uma versão exata do código. A aula 11
volta à reversão como forma de rollback.

## Falhar rápido, ou terminar todas as células?

Quando uma célula falha, um serviço de CI pode cancelar as células que ainda estão rodando, o que
economiza tempo de runner, ou deixá-las terminar, o que economiza informação. O GitHub Actions cancela
por padrão, numa configuração chamada `fail-fast`. Na execução 4 esse padrão teria parado na primeira
célula vermelha, e ninguém teria visto que **toda célula UTC falhou e toda célula de São Paulo
passou**, que foi o que apontou o fuso de relance. O hook do laboratório nunca cancela.

Um meio-termo razoável: falhar rápido em pull requests, onde o autor só precisa saber que algo está
errado, e **terminar todas as células na `main`** e nas execuções agendadas, onde o desenho é o que
alguém vai ler. De qualquer jeito, a execução guarda todos os logs como artefatos, porque uma falha
que ninguém consegue ler é uma falha que alguém vai rodar de novo torcendo para sumir.
