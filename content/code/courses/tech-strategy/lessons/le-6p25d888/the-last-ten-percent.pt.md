---
title: Os últimos dez por cento
version: 1
---

Uma migração estranguladora parece terminada muito antes de terminar. O novo serviço de reservas da
Coreto levava 90% do tráfego de reservas no fim do mês 8. **Os últimos 10% levaram mais quatro
meses**, um terço da migração inteira gasto num décimo do tráfego.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Um gráfico de barras da fatia do tráfego de reservas atendida pelo serviço novo no fim de cada mês, do mês 0 ao mês 12: 0, 5, 12, 25, 40, 58, 71, 83, 90, 94, 97, 99 e 100 por cento. Uma linha tracejada marca 90 por cento, alcançados no mês 8. Uma chave sobre os meses 9 a 12 marca os últimos 10 por cento, que levaram quatro meses.\"><path d=\"M70 290.0 L690 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"294.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><path d=\"M70 232.5 L690 232.5\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"236.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">25%</text><path d=\"M70 175.0 L690 175.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"179.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70 117.5 L690 117.5\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"121.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">75%</text><path d=\"M70 60.0 L690 60.0\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62\" y=\"64.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">100%</text><text x=\"93.8\" y=\"284.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"93.8\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><rect x=\"126.8\" y=\"278.5\" width=\"29.6\" height=\"11.5\" fill=\"var(--phosphor)\"></rect><text x=\"141.5\" y=\"272.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"141.5\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><rect x=\"174.4\" y=\"262.4\" width=\"29.6\" height=\"27.6\" fill=\"var(--phosphor)\"></rect><text x=\"189.2\" y=\"256.4\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"189.2\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><rect x=\"222.1\" y=\"232.5\" width=\"29.6\" height=\"57.5\" fill=\"var(--phosphor)\"></rect><text x=\"236.9\" y=\"226.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">25</text><text x=\"236.9\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><rect x=\"269.8\" y=\"198.0\" width=\"29.6\" height=\"92.0\" fill=\"var(--phosphor)\"></rect><text x=\"284.6\" y=\"192.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">40</text><text x=\"284.6\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><rect x=\"317.5\" y=\"156.6\" width=\"29.6\" height=\"133.4\" fill=\"var(--phosphor)\"></rect><text x=\"332.3\" y=\"150.6\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">58</text><text x=\"332.3\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><rect x=\"365.2\" y=\"126.7\" width=\"29.6\" height=\"163.3\" fill=\"var(--phosphor)\"></rect><text x=\"380.0\" y=\"120.7\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">71</text><text x=\"380.0\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><rect x=\"412.9\" y=\"99.1\" width=\"29.6\" height=\"190.9\" fill=\"var(--phosphor)\"></rect><text x=\"427.7\" y=\"93.1\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">83</text><text x=\"427.7\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><rect x=\"460.6\" y=\"83.0\" width=\"29.6\" height=\"207.0\" fill=\"var(--phosphor)\"></rect><text x=\"475.4\" y=\"77.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">90</text><text x=\"475.4\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><rect x=\"508.3\" y=\"73.8\" width=\"29.6\" height=\"216.2\" fill=\"var(--amber)\"></rect><text x=\"523.1\" y=\"67.8\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">94</text><text x=\"523.1\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><rect x=\"556.0\" y=\"66.9\" width=\"29.6\" height=\"223.1\" fill=\"var(--amber)\"></rect><text x=\"570.8\" y=\"60.9\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">97</text><text x=\"570.8\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><rect x=\"603.7\" y=\"62.3\" width=\"29.6\" height=\"227.7\" fill=\"var(--amber)\"></rect><text x=\"618.5\" y=\"56.3\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">99</text><text x=\"618.5\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><rect x=\"651.4\" y=\"60.0\" width=\"29.6\" height=\"230.0\" fill=\"var(--amber)\"></rect><text x=\"666.2\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">100</text><text x=\"666.2\" y=\"308\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"380.0\" y=\"332\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mês da migração</text><path d=\"M70 83.0 L690 83.0\" stroke=\"var(--paper)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><path d=\"M482.5 44 L482.5 36 L682.8 36 L682.8 44\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"582.7\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">os últimos 10%: quatro meses</text><text x=\"79.5\" y=\"40\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">os primeiros 90%: oito meses</text></svg>", "caption": "Fatia do tráfego de reservas no serviço novo, mês a mês. A curva é íngreme no meio e plana no fim: um terço da migração foi para um décimo do tráfego."}
```

## A forma da curva

Os primeiros meses são lentos porque as primeiras fatias são escolhidas para serem seguras, e não
grandes: 5% no fim do mês 1, 12% no mês 2. O meio é íngreme. Quando a costura funciona e alguns fins
de semana passam sem problema, mover um evento é uma linha numa tabela, e a fatia sobe de 25% no mês 3
para 83% no mês 7. Depois ela achata: 90, 94, 97, 99, e 100 só no mês 12.

A aula 1 deu ao time os seus dois primeiros trimestres no caminho das reservas, começando pelos
travamentos de linha. No fim do mês 6, o serviço novo,
que reserva assentos sem eles, levava 71% do tráfego de reservas, e os outros 29% ainda passavam pelos
travamentos. Um plano escrito como "dois trimestres" era razoável para o grosso do tráfego e não tinha
nada a dizer sobre o fim.

## O que vive na cauda

Os últimos 10% não eram mais eventos do mesmo tipo. Eram os caminhos que ninguém tinha listado quando
a migração foi planejada, cada um pequeno em tráfego e grande em trabalho:

- reservas que a equipe da Bilheteria faz à mão na porta, para um comprador parado no balcão;
- reservas em grupo para escolas, que seguram um bloco de assentos por dias em vez de minutos;
- passes de festival que seguram um assento em vários dias ao mesmo tempo;
- uma integração de parceiro que lê as tabelas antigas de reserva diretamente, sob um contrato que
  ninguém na Coreto podia mudar sozinho;
- os dois relatórios que o trabalho da costura no mês 1 tinha encontrado, ainda lendo as tabelas
  antigas.

**Cada um é raro, cada um precisa do seu próprio trabalho, e a maioria pertence a alguém que não é o
time que faz a migração.** As reservas em grupo precisaram de um tipo novo de reserva no serviço. A
integração do parceiro precisou de uma conversa com o parceiro. Nenhum deles mexeu o gráfico em mais
de um ou dois pontos, o que tornou cada um fácil de adiar.

## Parar nos noventa

A armadilha é parar. Em 90%, o problema urgente parece resolvido: as grandes aberturas rodam no
serviço novo, a taxa de incidentes caiu, o time que fez o trabalho é requisitado em outro lugar. O que
sobra é uma cauda de caminhos incômodos e uma migração que todo mundo considera feita.

**É o lugar mais caro para parar.** A Coreto estaria rodando os dois sistemas de reservas
indefinidamente: a fachada, dois armazenamentos, o caminho de publicação nas tabelas antigas, a
reconciliação noturna, e o código antigo de travamentos ainda vivo para os últimos caminhos. Cada
engenheiro que mexesse em reservas precisaria saber de que lado cai cada caso. E a dívida das reservas
da aula 5 não seria quitada. Os juros dela encolheriam com o tráfego e nunca chegariam a zero, porque
o imposto sobre as mudanças é pago sempre que alguém precisa entender o caminho antigo, por menos
pedidos que ainda passem por ele.

## Apagar o código antigo é a linha de chegada

**A medida de uma migração estranguladora é quanto do código antigo sumiu.** A fatia do tráfego é a medida
que as pessoas olham, porque ela se mexe todo mês e vai para um slide, e ela mostra 90% para um
sistema que ainda roda em dobro. A migração da Coreto terminou quando o código das reservas, as
tabelas de travamento, o caminho de publicação e a rotina de reconciliação foram apagados do
`coreto-core`, depois que o mês 12 levou a fatia a 100%.

Três hábitos fazem o fim acontecer em vez de torcer por ele:

- liste a cauda cedo: por volta da metade do tráfego, escreva cada chamador que resta do caminho
  antigo, com um dono para cada um. Os caminhos da cauda são achados procurando, e procurar é barato
  enquanto o time ainda está no trabalho;
- ponha uma data para apagar o código antigo, e trate uma data perdida como se trata uma entrega
  perdida, com um motivo e uma data nova;
- informe dois números em vez de um: a fatia do tráfego, e as partes do sistema antigo ainda em uso. O
  segundo só cai quando algo é apagado.

A promessa inteira do padrão estrangulador era que a produção continua rodando enquanto o sistema muda
por baixo. Ele cumpre essa promessa até o fim, e pede uma coisa em troca: que alguém o termine.
