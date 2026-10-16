---
title: Onde termina o papel do arquiteto
version: 1
---

**O arquiteto não gerencia pessoas, não é dono das prioridades do produto, não aprova cada pull
request e não está no caminho crítico da entrega de nenhum time.** Cada uma dessas coisas é um
trabalho de verdade que alguém na Carreto faz bem, e cada uma delas, assumida pelo arquiteto,
prejudica a parte do trabalho que é dele. As fronteiras ficam mais fáceis de defender quando o
prejuízo fica visível, então esta seção passa por elas uma de cada vez, com o que custa cruzar cada
uma.

A ideia errada por baixo das quatro é que a influência do arquiteto cresce com o número de coisas
que ele controla. A aula 3 argumentou o contrário: a autoridade que torna um arquiteto útil é
conquistada, e é gasta cada vez que ele toma algo que pertence a outra pessoa.

## Não é gestor de pessoas

Renata não gerencia ninguém. Contratação, avaliações de desempenho, promoções e mudanças de time
pertencem aos gestores de engenharia da Carreto, e a tabela de direitos de decisão da seção anterior
dá a eles essa linha de forma explícita.

O motivo não é que gestores sejam maus arquitetos. É o que acontece com a discordância. **Quando a
pessoa cujo desenho você está questionando também escreve a sua avaliação de desempenho, discordar
do desenho fica caro, e as pessoas param de discordar.** O conselho vira ordem sem que ninguém
queira, e o arquiteto perde aquilo que pega decisões ruins cedo: um desenvolvedor que diz "isso não
vai funcionar, e o motivo é este". Ícaro avisar Renata de que a política de retentativa que ela
propôs cobraria um embarcador duas vezes num timeout vale mais para a Carreto do que qualquer
avaliação que ela pudesse escrever sobre ele, e ele tem muito mais chance de dizer isso a alguém que
não decide o salário dele.

Numa empresa pequena uma pessoa pode acumular as duas coisas, e a seção anterior disse o que fazer
nesse caso: dizer com que chapéu. Um gestor que toma uma decisão arquitetural pode deixar isso claro,
pedir conselho como qualquer outra pessoa e aceitar ser contestado. O que não funciona é fingir que a
combinação não muda nada.

## Não é dono das prioridades do produto

Helena Prado, a diretora de produto, decide o que a Carreto constrói e por quê. A parte do arquiteto
é tornar visível o **custo estrutural** de cada opção antes que ela decida, e depois aceitar a
decisão.

Um caso real: Helena quer que os motoristas recebam por Pix no momento em que chega o comprovante de
entrega, em vez de em até 24 horas depois da entrega, como faz hoje o fluxo da aula 4. Para os
motoristas, muitos dos quais esperam esse dinheiro para abastecer antes da próxima carga, é uma
funcionalidade forte. A parte de Renata não é dizer sim ou não. É dizer o que muda por baixo:

- O Payments passaria a agir sobre o comprovante de entrega do Tracking assim que ele chegasse,
  então um comprovante errado ou contestado pagaria um motorista antes de alguém olhar, e **uma
  transferência por Pix é muito difícil de reaver depois de enviada**.
- A janela de 24 horas hoje absorve os atrasos do Tracking; sem ela, uma queda do Tracking para os
  pagamentos em vez de atrasá-los.
- A estimativa dela, como faixa, do jeito da aula 14, é de **9 a 14 semanas-engenheiro**, a maior
  parte em verificações que hoje acontecem esperando.

Então Helena decide, talvez pelo pagamento instantâneo apenas para motoristas com um longo histórico
limpo. O arquiteto que atrasa em silêncio uma funcionalidade de que discorda, ou que se recusa a
estimá-la até ela ser abandonada, tomou uma decisão de produto por outros meios. A aula 10 trata de
fazer bem esse lado do trabalho, e a aula 13 de `architect-communication` de negociá-lo.

## Não é quem aprova cada pull request

A conta resolve esta mais rápido do que qualquer argumento. A Carreto faz merge de cerca de 320 pull
requests por semana. A dez minutos cada, revisar todos levaria 3.200 minutos de Renata, ou seja,
**53 horas e 20 minutos por semana** — mais do que a semana inteira de trabalho dela, antes de uma
única reunião ou de uma linha de código dela mesma. E, como ela seria uma pessoa diante de 50, cada
um desses pull requests esperaria pela agenda dela.

O que ela faz em vez disso é pôr o julgamento dela onde ele escala:

- **Padrões verificados por máquinas.** A fitness function da aula 9 quebra o build quando um módulo
  importa outro que não deveria, em cada pull request, sem custo para a semana dela.
- **Revisões de desenho, antes do código.** A revisão de desenho da aula 11 pega um erro estrutural
  quando ele custa uma conversa, e não uma reescrita.
- **Ler uma amostra de pull requests**, alguns por semana, de times diferentes. É assim que a aula 15
  diz que um arquiteto se mantém calibrado, e é leitura, não aprovação: ninguém espera que ela
  termine.

Os tech leads e os engenheiros sêniores dos times revisam o código uns dos outros, que é onde está o
conhecimento necessário para revisá-lo.

## Não está no caminho crítico

A aula 15 argumentou que o arquiteto precisa continuar escrevendo código e disse qual código: nunca
a tarefa pela qual a entrega de um time está esperando. A Carreto aprendeu por quê do jeito difícil,
na sprint em que Renata pegou o ticket do adaptador de pagamento por Pix.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Duas linhas do tempo ao longo de treze dias úteis. Planejado: Renata constrói o adaptador Pix nos dias 1 a 4, o time roda os testes de integração nos dias 5 a 7 e a entrega é no dia 8. O que aconteceu: Renata trabalha no adaptador no dia 1, passa os dias 2 a 6 no novo layout do CT-e e termina o adaptador nos dias 7 a 9; os testes de integração rodam nos dias 10 a 12 e a entrega é no dia 13, cinco dias úteis depois do previsto.\"><text x=\"12\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">planejado</text><text x=\"132\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">adaptador Pix (Renata)</text><rect x=\"140\" y=\"40\" width=\"168\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testes de integração</text><rect x=\"308\" y=\"68\" width=\"126\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"434\" y=\"68\" width=\"42\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">entrega</text><text x=\"12\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que aconteceu</text><text x=\"132\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">adaptador Pix (Renata)</text><rect x=\"140\" y=\"140\" width=\"42\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"392\" y=\"140\" width=\"126\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outro trabalho</text><rect x=\"182\" y=\"168\" width=\"210\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"287.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o novo layout do CT-e</text><text x=\"132\" y=\"206\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">testes de integração</text><rect x=\"518\" y=\"196\" width=\"126\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"644\" y=\"196\" width=\"42\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"665.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">entrega</text><path d=\"M455.0 92 L455.0 134\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><path d=\"M665.0 92 L665.0 192\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></path><text x=\"560.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a entrega atrasou cinco dias úteis</text><path d=\"M140 232 L686 232\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"161.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"203.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"245.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"287.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"329.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"371.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"413.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">7</text><text x=\"455.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"497.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9</text><text x=\"539.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"581.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11</text><text x=\"623.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"665.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13</text><text x=\"686\" y=\"268\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia útil</text></svg>", "caption": "Ninguém no time foi lento. A entrega esperou pela única tarefa que estava com a pessoa que tinha mais outras demandas na semana."}
```

O plano era razoável e o adaptador estava bem dentro da capacidade dela. O que o plano não levou em
conta foi que **a semana do arquiteto é a que tem mais chance de ser tomada por outra coisa**. No
dia 2 foi anunciado um novo layout do CT-e, e o trabalho de decidir como a Carreto o atenderia (a
aula 13 segue essa história) era dela. O adaptador parou por cinco dias, os testes de integração não
podiam começar sem ele, e a entrega passou do dia 8 para o dia 13. Ninguém no time ficou parado por
escolha, e ninguém conseguiria pegar o ticket pela metade sem começar de novo.

As alternativas estavam ali o tempo todo. Renata poderia ter **pareado com Ícaro no adaptador
enquanto ele ficava com o ticket**, o que dá a ela a mesma sensação do código e deixa a tarefa com
alguém cuja semana é previsível. Ou poderia ter pegado um trabalho pelo qual nada espera: um spike, a
fitness function para os imports do Payments, uma ferramenta que o time queria e não tinha tempo de
fazer.

## O que fica dentro da fronteira

Tiradas as quatro, o trabalho do arquiteto ainda enche uma semana:

- as decisões estruturais que atravessam times, e os seus registros (aulas 5 e 6);
- os atributos de qualidade e os requisitos por trás deles (aula 7);
- os padrões, e a automação que os mantém verdadeiros (aula 9);
- os riscos técnicos, escritos e acompanhados (aula 14);
- o fórum em que os times e o arquiteto discutem as questões entre times (aula 10).

Numa frase: **o arquiteto responde pelas decisões que atravessam as fronteiras entre times ou custam
caro para mudar, e torna as consequências delas visíveis para as pessoas que decidem todo o resto.**
A aula 17 trata do que acontece quando um arquiteto cruza essas fronteiras em qualquer das duas
direções: tomando demais, ou deixando as decisões estruturais sem dono.
