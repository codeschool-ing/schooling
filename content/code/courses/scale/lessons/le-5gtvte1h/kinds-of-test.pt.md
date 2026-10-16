---
title: Quatro perguntas, quatro testes
version: 1
---

A aula 11 terminou com um plano: quatro cópias, 24 vagas cada, para 1.000 leituras e 100 vendas por
segundo. Um plano é um conjunto de medidas de uma cópia, multiplicadas, mais suposições sobre tudo o
que a multiplicação deixou de fora. Esta aula o testa do único jeito que testa alguma coisa:
**mandando a carga e olhando o que acontece**.

"Teste de carga" é usado para vários testes diferentes, e cada um responde uma pergunta diferente:

| teste | o que manda | o que responde |
|---|---|---|
| **teste de carga** | o pico esperado, por um tempo | o plano aguenta a carga que esperamos? |
| **teste de estresse** | cada vez mais, até algo quebrar | onde está o limite, e o que quebra primeiro? |
| **teste de pico** | um salto repentino de calmo para o pico | sobrevive aos primeiros dez segundos de uma abertura? |
| **teste de resistência** | carga comum, por horas | algo vaza, enche ou fica lento com o tempo? |

Os dois primeiros são esta aula. Um teste de pico (*spike test*) é um teste de estresse com uma forma:
o primeiro minuto de uma abertura de vendas é um pico, e caches frios, cópias ainda subindo e
conjuntos de conexões ainda enchendo são o que ele encontra. Um teste de resistência (*soak test*)
encontra o que se acumula: memória que cresce, um disco que enche de logs, uma tabela que incha sem
vacuum, o assunto da aula 6. Os dois usam as mesmas ferramentas que os outros dois.

Todo teste precisa de três coisas escritas **antes** de rodar: a carga, o que é medido e o que conta
como passar. Um teste sem nota de corte produz números que todo mundo lê como boa notícia.
