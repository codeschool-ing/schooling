---
title: Quando o código ganha, e quando não ganha
version: 1
---

Duas opiniões sobre o Logic Apps circulam, e as duas erram do mesmo jeito. Uma diz que ele é para
quem não sabe programar, então uma equipe que sabe deveria escrever código. A outra diz que sem
código não há nada para manter, então ele é sempre a escolha mais barata. **As duas julgam a
ferramenta por quem a usa, quando a pergunta é como o trabalho é.** Um workflow que faz seis
chamadas por dia a serviços que já têm conector é umas poucas linhas de definição e mais nada. Um
trabalho que percorre milhares de registros e decide algo sobre cada um é um programa, onde quer que
seja escrito.

Os três desenvolvedores da loja sabem escrever os dois. Quatro propriedades do trabalho decidem.

## Dá para testar antes de rodar?

Uma função é código: o `function_app.py` da lição 15 roda num laptop no host do Functions, e um
teste pode chamá-la com um pedido e conferir o recibo. **Um workflow Consumption não roda em lugar
nenhum além do Azure.** A primeira seção mediu o que o laptop consegue verificar: o recurso em volta
da definição, e nada dentro dela. Um passo escrito errado e uma função escrita errado compilaram
limpo, então o mais cedo que um erro num workflow pode aparecer é no deploy, e o mais tarde é numa
execução às seis da manhã, lida depois no histórico.

Há ajuda, e ela é parcial. Uma definição pode levar **resultados estáticos**, guardados na sua chave
`staticResults`: uma ação marcada para devolver um deles dá uma saída simulada em vez de chamar
qualquer coisa, e assim uma execução pode ser testada sem a API da loja. Um logic app Standard tem
um runtime local, rodado pelo Visual Studio Code com a extensão da Microsoft, que instala para ele o
Azure Functions Core Tools, o .NET e o Node.js; ele pode parar num breakpoint dentro do
`workflow.json`. Este curso não usa nem o Visual Studio Code nem o Core Tools, então esse runtime é
lido, não executado, aqui.

## Dá para revisar uma mudança?

A definição é JSON, então pode morar no git, e `daily-orders.bicep` é um arquivo que um pull request
consegue mostrar. **Duas coisas ficam fora do arquivo.** O designer é onde a maioria das pessoas
edita um workflow, e uma mudança feita ali só chega ao git se alguém a exportar. A conexão com o
Outlook foi autorizada por uma pessoa que entrou com a sua conta, e nenhum diff registra quem, nem
quando o token para de valer. O código tem as mesmas partes de fora em princípio, os segredos e as
configurações, mas a lógica está toda no repositório, e quem revisa lê um laço ou uma condição do
jeito que ele roda.

## Laços e volume

**Um workflow é cobrado e limitado por passo, e um laço multiplica passos.** Suponha que a loja
quisesse uma linha para cada pedido em vez de um CSV: um `foreach` sobre os pedidos, com três ações
dentro. Num dia de 2.000 pedidos, isso é 2.000 × 3 + 1, então 6.001 execuções numa execução do
workflow, onde a exportação da manhã precisava de seis. O laço também tem limites. Por padrão 20
iterações rodam ao mesmo tempo, no máximo 50, e um `foreach` aceita até 100.000 itens num workflow
stateful. Um laço `until` para depois de 60 ciclos ou de uma hora, a menos que se diga outra coisa.
Operações de dados como `Select`, `Query` e `Table` tratam um array inteiro numa ação só, e é por
isso que `daily-orders.bicep` monta o CSV com `Table` e não com um laço.

Uma função que recebe os mesmos 2.000 pedidos os lê numa execução, e o Python decide como. Quando o
trabalho é um cálculo sobre muitos registros, o código o faz num passo que o Logic Apps cobraria
como milhares.

## Trabalho de longa duração

Uma execução stateful do Logic Apps pode durar até 90 dias, e o estado salvo deixa uma execução
interrompida ser reconstruída depois de uma queda. Uma orquestração nas **Durable Functions da lição
17**, escrita em Python, também: um orquestrador que chama atividades, se espalha para muitas ao
mesmo tempo, espera um timer ou um evento, e reconstrói o seu lugar depois de um reinício repetindo
o histórico. A diferença não é a durabilidade. É que uma é uma definição lida num designer e a outra
é código lido num editor, testado chamando-o, com cada laço e cada condição numa linguagem que a
equipe já conhece. Quando os passos são conectores e as decisões são poucas, a definição é mais
curta. Quando os passos são a lógica da própria loja, o código é.

E quando o trabalho não é uma sequência, mas um serviço que responde requisições, não é nenhum dos
dois: a API da própria loja é um contêiner, e as lições 7 e 8 a rodam.

## Os dois se misturam

Um workflow não precisa fazer tudo sozinho. A ação **Function** dele chama uma Azure Function, e
*Execute JavaScript Code* roda um trecho curto ali mesmo. Uma divisão comum é o workflow ficar com a
agenda, os conectores e o histórico de execuções, e uma função fazer o único passo que precisa de um
laço ou de uma biblioteca. As filas da lição 20 são a outra emenda comum: um workflow posta uma
mensagem, e o código segue dali.

## A exportação do financeiro

O trabalho desta própria lição sai do outro lado.

| | a exportação da manhã |
| --- | --- |
| passos | uma agenda, uma chamada HTTP, uma condição, um CSV, um e-mail |
| execuções | seis por dia |
| a parte difícil | mandar e-mail de uma caixa da empresa, o que um conector já faz |
| quem lê | o financeiro, que pode abrir o histórico de execuções e ver o CSV de ontem |
| o que o código acrescentaria | uma função, o plano dela, uma biblioteca de e-mail, credenciais para guardar, e alguém para fazer o deploy |

**Nada nesse trabalho é lógica da própria loja.** É encanamento entre a API da loja e uma caixa de
correio, uma vez por dia. Escrito como função, é um timer trigger, um cliente HTTP, um gerador de
CSV e uma biblioteca de e-mail, mais um segredo para a caixa de correio. Tudo isso fica nas mãos de
três desenvolvedores cujo tempo custa mais que seis execuções por dia. Escrito como workflow, é o
arquivo da primeira seção e uma conexão, e a pessoa que quer saber por que o e-mail de terça veio
vazio acha a resposta sem eles.

A regra prática que sai desta lição, para a lição 21 testar contra números: **use o Logic Apps
quando os passos são conectores e as execuções são poucas, e código quando os passos são seus, os
dados são muitos, ou a lógica precisa de testes.**
