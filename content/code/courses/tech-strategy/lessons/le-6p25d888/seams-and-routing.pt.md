---
title: Costuras, roteamento e os dados no meio
version: 1
---

Uma migração estranguladora é uma sequência de movimentos pequenos. Cada movimento tem as mesmas três
perguntas por trás: **onde cortar, como mandar o tráfego através do corte e o que fazer com os
dados dos dois lados.** As reservas de assento da Coreto respondem a cada uma de um jeito que serve
para outros casos.

## Ache a costura, ou faça uma

Uma costura é um lugar onde o comportamento pode ser redirecionado sem reescrever tudo em volta. As
melhores costuras têm uma interface estreita: poucas operações, entradas claras, respostas claras. As
reservas de assento têm uma das mais estreitas do `coreto-core`. O assento de um comprador é
reservado e depois confirmado quando o pagamento dá certo, ou liberado quando falha ou o tempo acaba.
Reservar, confirmar, liberar.

O problema era que nove anos de funcionalidades chamavam o módulo de reservas de todo lado. O
Checkout chamava de um jeito, o aplicativo da Bilheteria de outro, o Mobile por um auxiliar próprio,
e dois relatórios liam as tabelas dele diretamente. **A costura existia num quadro branco, e não no
código.** Então o primeiro mês do time de Reservas foi para torná-la real dentro do monólito: cada
chamador mudou para passar por um ponto de entrada único com as três operações, e nada atrás dele
mudou.

Aquele mês não entregou serviço novo nenhum. Mesmo assim se pagou, porque deu ao time um lugar único
para revisar toda mudança nas reservas — a regra de revisão que a aula 1 pediu — e um lugar para a
fachada ficar.

## Roteie pela coisa que não pode ser dividida

Com a costura no lugar, a fachada decide qual código responde. A escolha que importa é a chave de
roteamento, a coisa que a fachada olha para decidir. Uma porcentagem dos pedidos é o padrão de
costume, e para reservas de assento teria sido um desastre: dois pedidos pelo mesmo assento poderiam
chegar a dois armazenamentos diferentes, e dois compradores poderiam ouvir que o assento era seu.

Então a Coreto roteou por evento. Todas as reservas de um evento ficam de um lado só, e mover um
evento é mudar uma linha na tabela de roteamento da fachada. A ordem dos eventos foi escolhida pelo
risco:

- casas pequenas primeiro, onde um erro tocaria algumas centenas de assentos;
- depois eventos médios, quando alguns fins de semana tinham passado sem problema;
- grandes aberturas de vendas só depois de o serviço novo passar no teste de carga de abertura do
  time de Plataforma, porque a política da aula 1 diz que nada vai para o caminho das reservas sem
  evidência de carga.

**Um evento muda antes de a sua abertura começar, nunca durante uma.** Uma mudança durante a abertura
dividiria as reservas do evento entre dois armazenamentos no meio da meia hora mais movimentada que
ele vai ter. E toda mudança é reversível do mesmo jeito que foi feita: uma linha mudada de volta,
antes da próxima abertura.

## Sombra antes da troca

Antes de um evento ser roteado de verdade, a fachada mandava também uma cópia de cada pedido de
reserva dele ao serviço novo — **tráfego sombra**. O código antigo continuava respondendo ao
comprador; a resposta do serviço novo era registrada e comparada com a antiga, e depois descartada.
As reservas sombra iam para um armazenamento separado que nenhum comprador via.

Comparar as duas respostas achou o que a aula 6 disse que o código antigo esconderia. No começo, o
serviço novo ignorava um limite de quantas meias-entradas de estudante um evento pode vender, uma
regra que vivia como uma única condição no módulo antigo e em nenhum documento. O tráfego sombra pegou
a diferença num evento pequeno, semanas antes de qualquer comprador poder encontrá-la.

## Um dono para cada dado

As reservas em si são fáceis de mover, porque duram minutos: quando um evento muda, as reservas novas
vão para o armazenamento novo e as antigas simplesmente expiram. A parte difícil é tudo o que lê o
resultado. Telas da Bilheteria, o relatório noturno de vendas e os pipelines do time de Dados leem os
assentos confirmados nas tabelas do `coreto-core`, e não dava para todos mudarem no dia em que o
primeiro evento mudou.

A saída tentadora é a escrita dupla: cada confirmação é gravada nos dois armazenamentos no mesmo
pedido. Ela falha no intervalo entre as duas gravações. Uma dá certo, a outra estoura o tempo, e os
dois armazenamentos agora discordam sobre quem é dono de um assento, sem nada que diga qual está certo.

A Coreto usou uma regra mais estrita: **para cada evento, exatamente um armazenamento é a fonte da
verdade em cada momento**, e a outra cópia é derivada dele. Para um evento movido, o serviço novo é
dono das reservas e das confirmações, e publica cada confirmação nas tabelas antigas para que os
leitores existentes continuem funcionando. Uma rotina de reconciliação compara as duas cópias toda
noite e aponta qualquer assento em que elas discordem. Uma diferença é um bug a corrigir, e a cópia do
dono vence.

## As técnicas, lado a lado

| técnica | o que ela compra | o que ela custa |
|---|---|---|
| uma costura dentro do sistema antigo | um lugar para cortar e para revisar | um mês sem nada novo para mostrar |
| roteamento por evento | reservas de um evento nunca divididas | uma tabela de roteamento para manter e auditar |
| tráfego sombra | diferenças achadas antes dos compradores | carga dobrada no serviço novo, um armazenamento para descartar |
| uma fonte da verdade, uma cópia derivada | leitores continuam funcionando enquanto migram | um caminho de publicação e uma reconciliação noturna |

Cada uma dessas técnicas é um andaime provisório, feito para ser desmontado. A próxima seção é sobre
desmontá-lo, o que acabou levando um terço da migração.
