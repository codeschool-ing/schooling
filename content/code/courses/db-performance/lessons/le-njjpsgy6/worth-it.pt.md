---
title: Valeu a pena? A conta
version: 1
---

A mudança é real e pequena; o custo dela é real e contínuo. Decidir entre os dois é uma soma, e a
soma tem duas metades quase sempre feitas em unidades diferentes — que é como mudanças assim
sobrevivem. Ponha as duas na mesma unidade e a decisão quase se toma sozinha.

## O que ela devolve, por dia

Os números do próprio servidor, da seção do antes e depois: 0,107 milissegundo por chamada antes,
0,089 depois, então **0,018 milissegundo economizado por chamada**. Na carga, o comando rodou umas
575 vezes por segundo. Então:

| | |
|---|---|
| economizado por segundo de tráfego | 575 × 0,018 ms ≈ 10 ms |
| como fatia de um processador | cerca de 1% |
| num dia, nesse ritmo | 10 ms × 86 400 ≈ 900 s, quinze minutos |

Quinze minutos de servidor por dia parece alguma coisa. Espalhado pelo dia, é um processador um por
cento menos ocupado — o que só importa se faltar tempo de processador ao servidor, e o joelho da
curva da aula 23 é onde essa pergunta se responde.

E o que cada pessoa ganha são **0,046 milissegundo** a menos numa página que abre, a diferença entre
as medianas do pgbench. Ninguém vê isso. Uma pessoa percebe uma demora de cerca de um décimo de
segundo; isto é duas mil vezes menor.

## O que ela custa, por dia

- **60 MB** a mais no disco, em cada backup, e disputando memória com as tabelas de que os comandos
  lentos precisam;
- mais uma entrada de índice em cada pedido gravado, pequena demais para aparecer nesta carga, e não
  zero;
- mais uma coisa que a próxima pessoa precisa entender.

## A mesma conta numa mudança que valeu

O índice em `seller_id` da aula 2 levou o painel do vendedor de uma média de **35,49** milissegundos
para **11,26**, cerca de 24 milissegundos por chamada, e o painel rodava umas 36 vezes por segundo:

| | índice de customer-orders | índice de seller_id |
|---|---|---|
| economizado por chamada | 0,018 ms | 24 ms |
| chamadas por segundo | 575 | 36 |
| economizado por segundo | cerca de 10 ms | cerca de 870 ms |

**O índice do vendedor devolveu quase um processador inteiro; este devolve um centésimo de um.** As
duas mudanças parecem iguais numa revisão de código — uma linha de `CREATE INDEX` cada, as duas
deixando uma consulta mais rápida, as duas justificadas por um plano. A diferença só aparece quando
a economia é multiplicada pela frequência com que a consulta roda, que é a mesma lição que o placar
deu na aula 2: **o que importa é o total, não a melhora por execução.**

## A decisão

Neste banco, com esta carga, o índice novo não vale os seus 60 MB. Ele deixou um pouco mais barato um
comando que já estava entre os mais baratos da aplicação, enquanto a busca por etiqueta e a contagem
de pendentes continuavam tomando a maior parte do tempo do servidor. O tempo gasto nele teria rendido
mais em qualquer uma das duas, e as aulas 8 e 9 mostram como isso fica.

Existe uma versão deste banco em que a resposta é sim: uma em que a lista de pedidos do cliente é o
comando no alto do placar, o servidor está perto do joelho, e os 60 MB cabem na memória com folga. A
conta é a mesma; só mudam os números. **É para isso que se faz a conta no papel**: a decisão pertence
aos números do banco à sua frente, e não ao livro que recomendou o índice.
