---
title: O que significa um sistema escalar
version: 1
---

**Um sistema escala quando a próxima unidade de carga custa mais ou menos o que a anterior
custou.** É uma afirmação sobre custo, não sobre velocidade. Uma bilheteria que vende cem
ingressos por segundo numa máquina e duzentos em duas escala; uma que vende cem numa máquina e
cento e dez em quatro não escala, por mais rápida que seja cada venda.

A imagem comum é outra: que um sistema escalável é um sistema rápido, ou um feito com a tecnologia
certa. Nenhuma das duas é verdade. Um programa pode responder em um milissegundo e ainda assim cair
nos primeiros mil usuários, e o mesmo banco de dados roda sistemas que escalam e sistemas que não
escalam. O que decide é **onde o trabalho espera quando há mais dele**, e isso é uma propriedade do
desenho, medida e não escolhida.

## Dois números

Tudo neste curso volta a duas medidas:

- **Vazão** (*throughput*) é quanto trabalho termina por unidade de tempo: pedidos por segundo,
  ingressos vendidos por minuto, linhas gravadas por hora.
- **Latência** é quanto tempo um pedaço de trabalho leva desde o momento em que é pedido até o
  momento em que é respondido.

Não são duas vistas de uma mesma grandeza. Um caixa que leva um minuto por cliente atende sessenta
por hora; dez caixas que levam um minuto cada atendem seiscentos, e cada cliente continua esperando
um minuto. **Somar capacidade aumenta a vazão e deixa a latência como está, até que alguma coisa
seja compartilhada.** Quando os dez caixas dividem uma única maquininha de cartão, a fila da
maquininha é onde todo cliente espera, e um décimo primeiro caixa não acrescenta nada.

Essa coisa compartilhada é o **gargalo**: o único recurso que está totalmente ocupado enquanto os
outros esperam por ele. Um sistema tem um a cada momento, e só um, porque por definição ele é o
ponto mais estreito. Deixar qualquer outra coisa mais rápida não muda nada que se possa medir.
Deixar o gargalo mais rápido o move para outro lugar, e achar o próximo é a maior parte do
trabalho.

## As duas direções

Há duas maneiras de dar mais capacidade a um sistema, e elas são o assunto desta aula:

- **Escala vertical** (*scaling up*): uma máquina maior. Mais processadores, mais memória, discos
  mais rápidos, para o mesmo programa.
- **Escala horizontal** (*scaling out*): mais máquinas, ou mais cópias do programa, com o trabalho
  dividido entre elas.

A escala vertical não pede nada ao programa e se esgota no tamanho da maior máquina que alguém
vende. A escala horizontal não tem esse teto e pede muito ao programa: as cópias precisam conseguir
dividir o trabalho sem perguntar umas às outras. As seções 07 e 08 medem as duas na mesma
bilheteria, e a seção 09 encontra o trabalho que não pode ser dividido de jeito nenhum.

## O que este curso não é

`architecture` deu nome aos padrões: replicação e sharding na aula 10, o circuit breaker na aula
11, backpressure na aula 12. Este curso **mede os limites que os tornam necessários**. Cada aula
roda alguma coisa na sua própria máquina, força até ela não dar mais conta e lê o que ela diz
quando isso acontece. Essa é também a segunda metade do título do curso: **observabilidade** é
conseguir responder, de fora, o que um sistema em funcionamento está fazendo e por quê. As aulas
7 e 8 constroem isso; todas as outras usam.
