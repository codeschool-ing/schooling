---
title: Uma tecnologia não é uma arquitetura
version: 1
---

Peça a um engenheiro que descreva a arquitetura de um sistema e muitos vão listar as tecnologias:
Python e Django, PostgreSQL, RabbitMQ, Kubernetes. **Uma lista de tecnologias quase não diz nada
sobre a arquitetura.** Não diz quais são os elementos, como se relacionam, nem em que o sistema foi
feito para ser bom. Duas empresas com exatamente a mesma lista podem ter arquiteturas opostas, e
duas sem nada em comum podem ter a mesma.

## A mesma ferramenta, duas arquiteturas

Pense num broker de mensagens como o Kafka, que você viu na aula 6 de `architecture`. Um time o usa
como registro de fatos: o Tracking publica "posição registrada", e qualquer serviço interessado lê
no seu tempo, sem que o Tracking saiba que ele existe. Outro time usa o mesmo broker como uma
chamada remota lenta: um serviço publica "por favor, calcule uma cotação", espera a resposta em
outro tópico e falha se nada chegar em dois segundos. O primeiro é um desenho orientado a eventos,
com acoplamento fraco. O segundo é uma cadeia síncrona vestida de broker, com todas as fraquezas da
versão síncrona da aula 1 e um conjunto novo de peças móveis por cima.

Com o PostgreSQL é igual. Um banco por serviço, acessível só por esse serviço, é uma arquitetura; um
banco compartilhado por seis serviços é outra. A Carreto roda PostgreSQL dos dois jeitos hoje. **O
nome da tecnologia não resolve nada disso**; as decisões sobre como ela é usada resolvem.

## "Todo mundo está indo para microsserviços"

Na segunda semana de Renata, um engenheiro do time Shipper manda uma proposta para a lista de
engenharia. O título é *Levando a Carreto para microsserviços*. Ela recomenda quebrar o monólito em
uns vinte serviços, rodá-los em Kubernetes e pôr Kafka entre eles. O argumento cabe num parágrafo: é
assim que as empresas modernas fazem software, a Netflix e a Uber fizeram isso, e os engenheiros
querem trabalhar com essas ferramentas.

Renata não responde se a proposta está certa. Ela pergunta que problema a proposta resolve, e
pergunta isso a quem sentiria o problema. As respostas são específicas:

- implantar o monólito leva uns 40 minutos, e um teste falhando de um time bloqueia a entrega de
  todos os outros;
- dois times mudando a tabela `loads` na mesma semana já quebraram um ao outro duas vezes este ano;
- o time Shipper espera o Matching revisar mudanças que mexem em código compartilhado.

São problemas reais, e nenhum deles é "não temos microsserviços". O primeiro é de facilidade de
implantação, o segundo dos dados compartilhados entre times, o terceiro de propriedade do código.
**Cada um tem várias respostas possíveis, e quebrar em vinte serviços é só uma delas — a mais
cara.** Um pipeline mais rápido e testes que rodam por módulo encolheriam o primeiro. Dar um único
dono aos dados de `loads`, que a aula 1 chamou de a decisão mais cara do sistema, trataria do
segundo. Um monólito modular, com módulos que não podem invadir uns aos outros, trataria do terceiro
sem acrescentar uma única chamada de rede.

A comparação com a Netflix merece uma frase própria. **Uma empresa com milhares de engenheiros tem
problemas que uma empresa com cinquenta não tem**, e as soluções para eles trazem custos pensados
para uma organização que pode pagá-los. A Carreto já roda 14 serviços com um time de Platform
pequeno; a aula 12 conta quanto cada um deles custa para ser mantido, e a resposta pesa contra
acrescentar mais seis porque estão na moda.

## Escolhas guiadas pelo currículo

Há um motivo desconfortável para propostas assim serem escritas, e vale nomeá-lo porque é comum e
ninguém o admite. **Engenheiros gostam de trabalhar com tecnologias que facilitam conseguir o
próximo emprego.** O nome informal para escolher ferramentas por esse critério é *résumé-driven
development*, desenvolvimento guiado pelo currículo. O engenheiro não está sendo desonesto; aprender
Kubernetes tem valor real para a carreira dele. O problema é que a empresa paga o aprendizado com
uma arquitetura de que não precisava e que vai ter de operar por anos.

A defesa de um arquiteto contra isso não é desconfiar de ferramentas novas. É uma pergunta feita
toda vez: **que atributo de qualidade isto melhora, quanto, e quanto custa?** Uma proposta que
responde a isso vale a leitura, recomende o que recomendar. Uma que não responde é um desejo.

## A ordem: atributo de qualidade, estrutura, tecnologia

Uma boa escolha de tecnologia vem no fim de uma cadeia, não no começo:

1. **o atributo de qualidade** de que o sistema precisa, dito com um número, como a aula 6 ensina;
2. **a decisão estrutural** que o entrega — uma fila em vez de uma chamada síncrona, um dono para
   uma tabela, um implantável separado para uma parte;
3. **a tecnologia** que implementa bem essa estrutura para este time.

O serviço de Tracking da Carreto é um bom caso de teste. O app Driver envia a posição de cada
caminhão a cada 30 segundos, e na hora mais movimentada da semana há cerca de 3.000 caminhões na
estrada. São cerca de 100 posições por segundo. Uma proposta de pôr Kafka na frente do Tracking
"para escalar" cai pela aritmética: 100 escritas pequenas por segundo estão folgadamente dentro do
que uma única instância de PostgreSQL aguenta. **O atributo de qualidade não exige a tecnologia.**
Se o número fosse cem vezes maior, a conversa seria outra, e seria uma conversa sobre o número.

## Quando uma tecnologia é uma decisão arquitetural

Nada disso quer dizer que escolhas de tecnologia nunca importam para um arquiteto. O teste da aula 1
vale para elas como para qualquer outra decisão: **uma escolha de tecnologia é arquitetural quando é
cara de desfazer.**

- O motor de banco que guarda os registros financeiros da Carreto é arquitetural: trocá-lo significa
  migrar anos de dados que precisam continuar certos até o centavo.
- Uma fila proprietária de um provedor de nuvem, usada diretamente em quarenta lugares do código, é
  arquitetural: sair dela significa mexer nos quarenta.
- A biblioteca que o Pricing usa para formatar datas não é: substituí-la leva uma tarde.

A diferença não está em quão impressionante a tecnologia soa. Está no custo de mudar de ideia. A
aula 5 trata de tomar decisões de tecnologia de propósito — os critérios, as portas de mão única e
de mão dupla, e registrar a decisão para que a próxima pessoa veja por que ela foi tomada.

## Os sinais de uma proposta que começa pela tecnologia

A resposta de Renata à proposta de microsserviços é cordial e curta. Ela agradece o autor, lista os
três problemas que os times descreveram e pede que ele reescreva a proposta a partir deles. Nos
meses seguintes ela aprende a reconhecer o padrão cedo. **Uma proposta que começa por uma tecnologia
em vez de um problema** tem alguns sinais confiáveis:

- a tecnologia está no título, e o problema não;
- a seção que descreve o problema é mais curta do que a que descreve a solução;
- nenhuma alternativa é considerada, nem mesmo não fazer nada;
- os benefícios são adjetivos — "moderno", "escalável", "robusto" — sem nenhum número;
- os custos mencionam licenças e máquinas, mas não pessoas: quem vai operar, e quem vai aprender.

Nenhum desses sinais prova que uma proposta está errada. Cada um é um motivo para pedir o problema
primeiro.
