---
title: Janelas, congelamentos e o calendário
version: 1
---

Joana chegou com uma imagem de disponibilidade em que todo sistema quer estar no ar o tempo todo e
falha por acidente. Na Serra Alta, metade do tempo fora do ar que importa é de propósito. O SAP para
todo domingo de madrugada. O financeiro toma conta do ERP nos cinco primeiros dias úteis de cada
mês. A máquina do Coleta faz o seu salvamento noturno. **Os momentos em que um sistema para de
propósito fazem parte da arquitetura dele, tanto quanto as caixas e as setas**, e um projeto que não
os conhece falha com hora marcada.

## A janela semanal

Como a aula 1 contou, o SAP fica fora do ar todo domingo da 01:00 às 05:00. A equipe de Edson usa
essas quatro horas para o trabalho que precisa do sistema só para si: pacotes de suporte e patches do
kernel, os transportes que levam mudanças de configuração para produção, manutenção do banco de
dados. Quatro horas de uma semana de 168 horas são 2,38%.

Se essas horas contam depende de quem conta. Os 99,0% do SAP na seção anterior as deixavam de fora,
porque são planejadas, e para quem as planeja isso é razoável. Uma padaria que abre o carrinho às
02:00 de um domingo vê um sistema fora do ar. Contado o relógio inteiro, o SAP fica disponível 0,99 ×
(164 ÷ 168) = 96,64% do tempo, e a cadeia da consulta de estoque cai de 98,41% para 0,98406 ×
0,97619 = 96,06%. **Uma janela planejada é tempo fora do ar para todo mundo que depende do sistema de
forma síncrona.** Planejá-la só significa que todos podem saber com antecedência.

A integração mais antiga da empresa mostra como é saber com antecedência. O Coleta grava o arquivo de
coletas do dia por volta das 23:30 e o SAP o carrega às 02:00. No domingo, 02:00 está dentro
da janela. O arquivo carrega mesmo assim, porque anos atrás alguém da equipe de Edson passou a
execução de domingo do job de carga para as 06:00. Essa regra vivia no agendador de jobs e em nenhum
outro lugar; Joana só a encontrou porque perguntou por que as entradas de mercadoria de domingo sempre
tinham um horário mais tarde do que as do resto da semana. Funciona, e é o tipo de projeto que
funciona até alguém arrumar o agendamento.

**Uma integração é projetada para a janela do outro lado, não pega de surpresa por ela.** As formas
de fazer isso são poucas, e as próximas seções as levam adiante:

- quem envia segura o trabalho e entrega depois da janela, que é o que fazem tanto um arquivo num
  diretório quanto uma fila na frente do SAP;
- quem recebe declara a sua janela no contrato de interface, para que a equipe que envia não tenha
  de descobri-la num agendador;
- quem chama de forma síncrona tem uma resposta degradada para as horas que a janela dura, como o
  último número de estoque do portal com o horário ao lado.

## Janelas numa cadeia se somam

A consulta de estoque atravessa dois sistemas com janelas próprias. A equipe de Rui fazia a
manutenção do barramento no sábado à noite, das 22:00 às 24:00, então uma padaria que consultasse no
fim de semana perdia a consulta por duas horas no sábado e mais quatro no domingo. **O tempo fora do
ar planejado de uma cadeia é a união das janelas dos seus membros**, e duas janelas que não se
sobrepõem custam a soma das duas. Rui passou a janela do barramento para domingo da 01:00 às 03:00,
dentro da do SAP, e o tempo fora do ar planejado da cadeia por semana foi de seis horas para quatro
sem ninguém trabalhar mais rápido.

## O fechamento do mês e o congelamento

Nos cinco primeiros dias úteis de todo mês, os controllers de Marcos fecham o mês anterior: os
últimos lançamentos, as provisões, a valoração do estoque, a conciliação dos bancos e os relatórios
que vão para o conselho e para os bancos que emprestam à Serra Alta. Duas coisas decorrem disso para
todo sistema perto do SAP.

O SAP fica sob carga. Os jobs de fechamento rodam ao lado do dia normal, e os tempos de resposta se
esticam. O incidente de setembro na seção anterior foi isso: a consulta de estoque estourou o tempo
no segundo dia útil do fechamento. Uma integração síncrona que vai bem na terceira semana pode falhar
na primeira, então os timeouts e o objetivo dela têm de ser definidos para a primeira semana.

E nada muda. Uma mudança que quebra algo durante o fechamento atrasa a contabilidade, e um fechamento
atrasado é uma conversa entre o CFO e o conselho. Por isso a equipe do SAP sempre congelou mudanças
nessa semana. Um **congelamento de mudanças** é um período em que nada muda em produção exceto
correções de emergência, e essas só com a aprovação de uma pessoa nomeada. Não é um período sem
risco: **um congelamento empurra as mudanças para as semanas dos lados**, e a semana depois de um
congelamento é quando a fila de mudanças adiadas entra toda junta.

O calendário de Joana alargou o congelamento para os dois lados. Ele começa nos dois últimos dias
úteis do mês, quando as últimas notas do período estão sendo emitidas e um fluxo de NF-e quebrado
perderia vendas do mês que está sendo fechado. E vai até o dia 10, porque os produtores recebem no
dia 10. O Coleta calcula os pagamentos, o financeiro os aprova, e o arquivo do banco para 1.900
fazendas sai no dia útil anterior. Uma mudança que quebra essa cadeia na semana do pagamento
significa 1.900 fazendas pagas com atraso, e uma fazenda paga com atraso vende o leite para outro.

## O mês como figura

Novembro de 2026 é o primeiro mês que o calendário dela cobriu, e ele mostra por que o calendário
precisa ser desenhado em vez de descrito. O dia 2 de novembro é feriado nacional, então o fechamento
de outubro começa no dia 3 e o seu quinto dia útil é o dia 9. O pagamento aos produtores é no dia 10,
o dia seguinte. O congelamento que começou em 29 de outubro corre sem intervalo até a noite do dia 10.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-month\" aria-label=\"Novembro de 2026 como uma faixa de 30 dias, começando no domingo, dia 1º. Os fins de semana estão sombreados, e os feriados nacionais dos dias 2, 15 e 20 estão marcados. Linha um: a janela de domingo do SAP, das 01:00 às 05:00, nos dias 1, 8, 15, 22 e 29. Linha dois: o fechamento de outubro, nos cinco dias úteis de 3 a 9. Linha três: o pagamento dos produtores no dia 10. Linha quatro: o congelamento de mudanças, que começou em 29 de outubro e vai até o dia 10, e recomeça no dia 27. Entre os dois, onze dias úteis, de 11 a 26, ficam abertos para mudanças.\"><rect x=\"150.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"158.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"168.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"176.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><rect x=\"187.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"195.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"205.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"213.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"224.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"232.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"242.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"250.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"261.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"269.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"279.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"287.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"298.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"306.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"316.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"324.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"335.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"343.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11</text><rect x=\"353.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"361.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">12</text><rect x=\"372.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"380.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">13</text><rect x=\"390.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"398.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">14</text><rect x=\"409.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"417.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">15</text><rect x=\"427.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"435.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">16</text><rect x=\"446.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"454.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17</text><rect x=\"464.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"472.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">18</text><rect x=\"483.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"491.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">19</text><rect x=\"501.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"509.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">20</text><rect x=\"520.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"528.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">21</text><rect x=\"538.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"546.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">22</text><rect x=\"557.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"565.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">23</text><rect x=\"575.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"583.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24</text><rect x=\"594.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"602.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">25</text><rect x=\"612.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"620.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">26</text><rect x=\"631.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"639.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">27</text><rect x=\"649.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"657.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">28</text><rect x=\"668.0\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676.2\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">29</text><rect x=\"686.5\" y=\"44.0\" width=\"16.5\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"694.8\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">30</text><text x=\"427.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">novembro de 2026: dias sombreados são fins de semana e feriados nacionais (2, 15, 20)</text><text x=\"142.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">janela do SAP, dom 01–05</text><text x=\"142.0\" y=\"110.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fechamento de outubro</text><text x=\"142.0\" y=\"146.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pagamento aos produtores</text><text x=\"142.0\" y=\"182.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">congelamento</text><rect x=\"152.0\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"281.5\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"411.0\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"540.5\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"670.0\" y=\"65.0\" width=\"12.5\" height=\"18.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"188.0\" y=\"101.0\" width=\"70.0\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"299.0\" y=\"101.0\" width=\"14.5\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"317.5\" y=\"137.0\" width=\"14.5\" height=\"18.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"173.0\" width=\"181.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"632.0\" y=\"173.0\" width=\"70.0\" height=\"18.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"156.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">← desde 29 de outubro</text><text x=\"637.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">até dez</text><path d=\"M336.0 218.0 L336.0 224.0 L628.0 224.0 L628.0 218.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"483.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">aberto para mudanças: 11 dias úteis, de 11 a 26</text></svg>", "caption": "Novembro de 2026 numa faixa. O feriado do dia 2 empurra o fechamento até o dia 9, o pagamento vem logo no dia 10, e o congelamento vem de outubro sem intervalo."}
```

Novembro tem 19 dias úteis depois de tirados os feriados dos dias 2 e 20. Seis deles estão no
congelamento que começou em outubro. O próximo congelamento começa no dia 27, o penúltimo dia útil do
mês. Sobram 11 dias úteis, do dia 11 ao dia 26, em que uma mudança no SAP, nos fluxos do barramento
que o alimentam ou no checkout do portal pode ir para produção. **Onze dias é a capacidade real de
mudança em novembro**, e um plano de projeto que conta os 21 dias de semana do mês está planejando
quase o dobro do que o calendário permite.

## O resto do calendário

O mês é o ciclo mais curto. O ano tem o seu.

As obrigações fiscais mensais dependem de um mês fechado, e as datas delas são fixadas pelas
autoridades federais e estaduais, não pela Serra Alta. Quando o fechamento escorrega, são as
obrigações que ficam em risco, e é por isso que o financeiro defende os cinco dias com tanta firmeza.

O leite tem estações. Mais ou menos de outubro a março, a estação das chuvas em Minas Gerais, os
pastos crescem e as fazendas mandam mais leite. Na Serra Alta a captação diária sobe de cerca de 2,3
milhões de litros para cerca de 2,6 milhões no pico, e os caminhões, as fábricas e o Coleta trabalham
no limite. Uma mudança no Rota ou no Coleta em janeiro carrega mais risco do que a mesma mudança em
julho.

As vendas também têm estações. Dezembro é o pico do ano para creme de leite, manteiga e queijo nos
supermercados, e a Serra Alta congela os sistemas de vendas, os fluxos de EDI e o portal de 15 de
dezembro a 5 de janeiro.

## O calendário é um artefato

Nada disso era segredo. Cada equipe conhecia as próprias janelas, os próprios congelamentos e os
próprios picos. O que não existia era **um calendário com todos eles**, para que uma mudança num
sistema pudesse ser conferida contra as janelas de tudo aquilo em que ela toca. Joana o pôs ao lado
do registro de contratos de interface, com as janelas de cada sistema, cada congelamento e o seu
motivo, e cada pico. Um pedido de mudança agora diz a data que quer, e o calendário responde se essa
data está aberta para todos os sistemas no caminho da mudança.

É o artefato menos técnico que ela produziu naquele ano, e o que as outras equipes mais abriram.
