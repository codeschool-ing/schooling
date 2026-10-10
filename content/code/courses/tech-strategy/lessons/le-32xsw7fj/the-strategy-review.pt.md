---
title: A revisão de estratégia
version: 1
---

A revisão é onde uma estratégia deixa de ser o documento do Davi e vira a decisão da empresa. Ela
dura uma hora, tem duas pessoas que podem dizer não, e **quase toda ela é feita de perguntas**, e
cada uma delas este curso já respondeu em algum lugar. Esta seção acompanha a reunião do começo ao
fim, e serve também de mapa do curso: cada resposta que Davi dá foi produzida numa aula que você já
fez.

É uma quinta-feira de fevereiro, duas semanas antes de o time de Reservas começar. Na sala estão
Helena Prates, a CTO, que pediu a estratégia; Otávio Lins, o CFO, que tem de concordar com o que
ela custa; e Davi Moreira, que a escreveu.

## Os primeiros cinco minutos

Davi põe na tela o slide da seção anterior e lê o título em voz alta: corrigir as reservas de
assento antes da temporada, R$ 48.000 uma vez, contra R$ 364.800 por ano de perda esperada. Depois
para de falar.

A pausa é de propósito. **O slide é feito para que as perguntas comecem na hora**, e as perguntas
são a reunião. Um apresentador que enche a hora percorrendo o anexo está protegendo a estratégia do
único teste que importa: se as duas pessoas que podem barrá-la ainda a querem depois de terem
empurrado contra ela.

## As perguntas, e de onde veio cada resposta

Otávio faz a maioria delas. Helena faz duas, e as dela são mais difíceis.

| a pergunta | a resposta do Davi | de onde veio |
|---|---|---|
| "O que exatamente está quebrado?" | Grandes aberturas falham no código de reserva de assentos do módulo de reservas, umas doze por ano estão em risco, e todo time edita esse código sem que nenhum seja dono dele. | o diagnóstico, aula 1 |
| "Você disse R$ 48.000. Quanto pagamos se esperarmos?" | A dívida cobra 31 horas de juros por sprint, R$ 4.650; 806 horas por ano, R$ 120.900, antes de contar uma única abertura que falha. | juros por sprint, aula 5 |
| "A busca também está no plano. Por que comprar em vez de construir?" | Em três anos, comprar custa R$ 433.080 contra R$ 450.000 para construir, R$ 16.920 a menos, e no primeiro ano são R$ 157.200 contra R$ 246.000. | a comparação de três anos, aula 8 |
| "A licença de observabilidade hospedada é a mais cara. Por que ela?" | Só a licença favorece hospedar por conta própria em R$ 124.200, mas operar é 76% do custo total de propriedade dessa opção; no total, o serviço hospedado sai R$ 174.150 mais barato. | custo total de propriedade, aula 9 |
| "Não estamos nos prendendo ao gateway de pagamento?" | Ali pagamos R$ 24.000 pela portabilidade, porque o custo esperado do aprisionamento é R$ 47.250. No banco de documentos aceitamos: R$ 21.000 esperados, contra R$ 63.000 para evitar. | aprisionamento precificado, aula 10 |
| "E se eu pedisse um corte de 10%?" | São R$ 1.738.400 de um orçamento de R$ 17.384.000 — 6,6 engenheiros, ou 68% da conta de nuvem inteira. 79,0% do orçamento são pessoas, então um corte desse tamanho é sobretudo de pessoas. | o orçamento, aula 11 |
| "A conta de nuvem sobe de novo no ano que vem." | Em 11,3%, enquanto os ingressos crescem mais: o custo por ingresso cai de R$ 0,517 para R$ 0,454. E os ambientes de staging ociosos são R$ 117.600 por ano que deixamos de pagar. | custo unitário e showback, aula 12 |
| "Por que a correção das reservas antes do Pix parcelado, que vendas quer?" | Ordenando por custo de atraso dividido pela duração, a correção vem primeiro, e essa ordem custa R$ 1.632.000 em atraso contra R$ 1.794.000 se o item com maior custo de atraso, o Pix, vier primeiro. | custo de atraso, aula 13 |
| "Daqui a um ano, como alguém vai saber por que escolhemos isso?" | Cada uma dessas decisões é um registro de decisão de arquitetura (ADR), numerado, ao lado do código; os da busca e da observabilidade já estão escritos. | ADRs, aula 17 |

Leia a coluna da direita como uma lista e ela é a maior parte deste curso. **Nenhuma das respostas
é opinião**, e nenhuma foi preparada para a reunião: cada uma já existia, como planilha ou página,
porque a estratégia foi construída a partir delas.

## As duas perguntas da Helena

A primeira pergunta da Helena é sobre as pessoas: "Quais dois líderes de time perdem seus projetos
este ano, e eles ouviram isso de você?" É a pergunta sobre a lista do que não fazer da aula 3 — a
migração para microsserviços e o framework de front-end — feita como pergunta sobre pessoas em vez
de projetos. Davi contou aos dois, pessoalmente, antes da revisão. Uma estratégia cujos perdedores
descobrem o próprio destino num slide tem um segundo problema esperando atrás do primeiro.

A segunda pergunta é a que testa tudo: "O que faria você mudar isto?" Davi responde com condições,
do tipo que a aula 19 pede. Se o teste de carga mostrar o caminho da reserva aguentando uma abertura
antes de a remoção das travas terminar, o congelamento de deploys pode ser relaxado. Se duas grandes
aberturas falharem mesmo assim nesta temporada, o diagnóstico estava errado, e a estratégia volta a
esta sala. **Uma estratégia que diz o que a mudaria é uma em que se pode confiar que vai mudar por
um motivo**, e não por quem pedir mais alto no próximo trimestre.

## A decisão, e onde ela fica escrita

Otávio aprova o time e a correção, e pede uma coisa em troca: o mesmo slide, com números reais no
lugar dos esperados, na revisão depois da temporada de aberturas. Helena concorda que a migração e o
framework esperem um ano, e diz isso ela mesma aos líderes de time.

Davi registra tudo na mesma tarde. A página da estratégia registra a decisão e a data. Um registro
de decisão de arquitetura, no formato da aula 17, registra por que o time de Reservas foi criado e o
que foi decidido contra. E a tabela de ainda-nãos da aula 19 ganha sua primeira linha no instante em
que a revisão termina, porque alguém sempre pede alguma coisa na saída. **O registro é o que deixa a
revisão do ano que vem começar do que foi decidido, e não do que as pessoas lembram.**

## No que o curso deu

Esta é a última aula do curso e da trilha. Os cursos anteriores da trilha deram a você o processo
do time, suas pessoas, suas métricas e sua comunicação. Este deu a parte em que um líder decide para
onde vai o dinheiro da engenharia e defende essa decisão.

Cada ferramenta dele respondeu a um tipo de pergunta. O núcleo de Rumelt decidiu do que trata a
estratégia. Os juros por sprint precificaram a dívida. A planilha de três anos, o custo total de
propriedade e o custo esperado do aprisionamento precificaram o que construir, comprar ou adotar. O
orçamento e o custo unitário puseram o gasto nos termos do negócio, e o custo de atraso ordenou o
trabalho. Os ADRs guardaram os motivos. Dizer não com um custo e uma data manteve a estratégia
inteira entre uma revisão e outra, e a revisão é onde tudo isso é testado por quem pode dizer não.

A Coreto é inventada. A sua empresa não é, e ela tem sua própria abertura de vendas em algum lugar:
o momento em que ganha sua reputação e em que, muito provavelmente, ninguém é dono do código que
falha. Encontre esse momento, escreva o diagnóstico em três frases e ponha um preço nele. O resto
deste curso é o que você faz em seguida.
