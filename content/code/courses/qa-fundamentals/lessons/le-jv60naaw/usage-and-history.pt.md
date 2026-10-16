---
title: Com que frequência é usado, e onde já houve defeitos
version: 1
---

**Probabilidade e impacto são julgamentos. Uso e histórico de defeitos são dados, e corrigem os julgamentos.** Duas
áreas com a mesma nota de risco não são iguais se uma é usada por todo cliente e a outra por um por mês, ou se uma
falhou três vezes este ano e a outra nunca.

## Uso: teste o que as pessoas de fato fazem

O estrago de um defeito é o impacto *por uso* vezes *quantos usos*. Um preço errado numa combinação rara prejudica um
cliente; um preço errado no pedido mais comum prejudica centenas antes de alguém perceber. John Musa, trabalhando com
software de telefonia na Bell Labs, chamou o retrato de como um sistema é de fato usado de **perfil operacional**, e
defendia que o teste o seguisse: as jornadas mais comuns primeiro e com mais cuidado.

Os registros de pedidos do Cine Aurora de setembro dão um perfil aproximado:

| o que os clientes fazem | parte dos pedidos |
|---|---|
| compram um ou dois ingressos inteiros para uma sessão da noite | 58% |
| compram com ao menos uma meia-entrada | 31% |
| usam o mapa de assentos no site | 64% |
| usam um cupom | 6% |
| pedem reembolso | 1% |

Duas coisas nessa tabela mudam o plano da Lia. O mapa de assentos, com nota baixa de probabilidade, é usado por quase
dois pedidos em cada três, então um defeito ali seria visto por centenas de clientes numa semana: ele ganha mais tempo
do que a nota de risco sozinha dava. Os cupons, com nota alta de probabilidade, são usados por um pedido em dezessete:
ainda importantes, porque o código é novo, mas não antes da regra de preço.

Dados de uso têm um ponto cego próprio. Mostram o que as pessoas fazem com o sistema atual, não o que vão fazer com uma
funcionalidade nova. Na primeira quarta depois de uma promoção, um cupom usado por 6% dos pedidos pode ser usado por
60%. Um perfil é um guia do presente, e quem testa pergunta o que está para mudá-lo.

## Histórico: defeitos se agrupam

Defeitos não se espalham por igual. Eles se juntam em algumas partes de um sistema, as complexas, as feitas às
pressas, as escritas por alguém que já saiu, e essas partes continuam produzindo defeitos. É um dos padrões mais
consistentemente observados no teste de software, e muitas vezes é descrito com a razão de Pareto: uma pequena parte
dos módulos concentra uma grande parte dos defeitos.

Os próprios registros do Cine Aurora ao longo deste curso mostram isso:

| área | defeitos achados até aqui | onde |
|---|---|---|
| regra de preço | 4 | a linha da idade, a sessão das 9:30, o empilhamento da quarta, entradas que ninguém mencionou |
| pedidos | 1 | pedidos recusados gravados no banco |
| cupons | 1 | códigos colados com espaços |
| mapa de assentos, reembolsos, relatório | 0 | |

Quatro de seis defeitos numa função. Mesmo com a última correção no lugar, o histórico diz que é ali que o próximo é
mais provável, e a verificação de relações da aula 19 acabou de mostrar que um dos quatro, a sessão das 9:30, continua
lá.

## A armadilha do histórico

O histórico de defeitos tem uma falha conhecida: **o paradoxo do pesticida**. Boris Beizer deu o nome: um campo
pulverizado todo ano com o mesmo pesticida acaba cheio dos insetos que ele não mata. Rode os mesmos testes na mesma área
entrega após entrega, e eles param de achar coisas, não porque a área está limpa mas porque só olham onde já olharam.

Então o histórico decide *onde* testar, nunca *como*. A regra de preço recebe mais horas, e parte delas vai para casos
novos e exploração, não só para rodar de novo o esboço da aula 17. Um histórico de zero defeitos no botão de reembolso
quer dizer que ninguém olhou ainda, não que não há nada ali.
