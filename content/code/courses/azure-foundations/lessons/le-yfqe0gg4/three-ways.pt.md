---
title: Pagamento conforme o uso, reservas e savings plans
version: 1
---

**O Azure vende a mesma máquina ligada a três preços, e a diferença entre eles não é a máquina, e sim
a promessa que você faz sobre ela.** O pagamento conforme o uso não promete nada e paga o máximo por
hora. Uma reserva promete um tipo de máquina, numa região, por um ou três anos. Um savings plan
promete uma quantia de dinheiro por hora, por um ou três anos, onde quer que ela seja gasta. Quanto
mais você promete, menos custa cada hora, e **uma promessa é paga quer você continue usando o que
prometeu, quer não**.

## Três jeitos de pagar

| | com o que você se compromete | a hora é cobrada | o risco é |
|---|---|---|---|
| **pagamento conforme o uso** | nada | só enquanto o recurso roda | o maior preço por hora, por todo o tempo em que você o deixar ligado |
| **reserva** | um produto, tamanho e região, por um ou três anos | toda hora do prazo, usada ou não | a máquina muda, ou para, e a reserva continua cobrando |
| **savings plan** | uma quantia por hora, por um ou três anos | toda hora do prazo, até a quantia | a quantia ser maior do que você acaba gastando; a parte não usada de uma hora se perde |

**Uma reserva é um desconto sobre uma coisa.** A documentação da Microsoft diz que as reservas podem
reduzir custos *em até 72%* em relação ao pagamento conforme o uso, e isso é um teto para o produto e
o prazo mais favoráveis, não um número para planejar. Ela se aplica sozinha ao uso que bate com o que
foi comprado: o tamanho, a região e o **escopo**, que é uma assinatura, um grupo de recursos, um grupo
de gerenciamento, ou todas as assinaturas da conta de cobrança (*compartilhado*). Ela pode ser paga
adiantada ou por mês, e o total é o mesmo dos dois jeitos. Se a carga de trabalho mudar, uma reserva
pode ser trocada por outra do mesmo tipo, e devolvida com reembolso dentro de um limite que a
Microsoft define, quando este curso foi escrito USD 50.000 em doze meses corridos.

**Um savings plan é um desconto sobre um orçamento por hora.** Você se compromete a gastar, digamos,
uma quantia fixa por hora em computação; a cada hora, o Azure aplica preços com desconto ao uso
elegível no escopo do plano e o desconta dessa quantia, e o que passar dela é cobrado ao preço do
pagamento conforme o uso. A Microsoft oferece dois tipos, um para computação e um para bancos de dados.
O desconto é menor que o de uma reserva para a mesma máquina e acompanha o uso entre tamanhos, regiões
e serviços. Duas coisas nele não perdoam: **a parte não usada de uma hora expira e não passa para a
próxima**, e um savings plan, ao contrário de uma reserva, **não pode ser cancelado nem reembolsado**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l14-savings-plan-hours\" aria-label=\"Seis horas sob um savings plan com compromisso de 10 por hora, valor inventado, desenhadas como barras. Nas horas um e dois o uso elegível, ao preço com desconto, é 10 e consome o compromisso exatamente. Na hora três é 14: 10 saem do compromisso e os 4 de uso a mais são cobrados ao preço do pagamento conforme o uso. Nas horas quatro e cinco é 6, e os 4 restantes do compromisso se perdem. Na hora seis nada roda e os 10 inteiros se perdem.\"><path d=\"M60.0 110.0 L560.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"565.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">compromisso: 10 por hora</text><rect x=\"80.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hora 1</text><rect x=\"160.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hora 2</text><rect x=\"240.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"70.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hora 3</text><rect x=\"320.0\" y=\"150.0\" width=\"50.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"320.0\" y=\"110.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"345.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hora 4</text><rect x=\"400.0\" y=\"150.0\" width=\"50.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"400.0\" y=\"110.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"425.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hora 5</text><rect x=\"480.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"505.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hora 6</text><path d=\"M60.0 210.0 L560.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"240.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">coberto pelo plano</text><rect x=\"260.0\" y=\"240.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobrado conforme o uso</text><rect x=\"460.0\" y=\"240.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não usado, e perdido</text></svg>", "caption": "Cada hora vale sozinha: uma parte não usada não passa para a próxima."}
```

## Onde um compromisso deixa de compensar

Se um compromisso economiza dinheiro é aritmética, e a aritmética não precisa de conta. A máquina de
relatórios da loja é o exemplo; **os preços aqui são números redondos inventados para a conta, não os
do Azure**: 1,00 por hora no pagamento conforme o uso, e 0,60 por hora efetivos numa reserva de um
ano. Crie o diretório da lição, e salve este programa nele como `breakeven.py`:

```sh
mkdir -p ~/azure/bill && cd ~/azure/bill
```

```schooling-example
{"language": "python", "file": "breakeven.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"breakeven.py PAYG COMMITTED: what a commitment saves, by how much of the month it is used.\"\"\"\nimport sys\n\nHOURS = 730\n\n", "note": "`HOURS` é o mês que a própria calculadora de preços do Azure usa: 730 horas, as 8.760 de um ano divididas por doze. Todo valor mensal abaixo é um preço por hora vezes isto."}, {"code": "payg, committed = float(sys.argv[1]), float(sys.argv[2])\nprint(f'break-even at {committed / payg:.0%} of the month')\n", "note": "Dois preços por hora: o do pagamento conforme o uso, e o preço efetivo por hora de um compromisso. **O compromisso é pago a cada hora, usada ou não**, então ele só ganha quando a máquina roda por mais que a razão entre os dois preços."}, {"code": "for used in (1.0, 0.8, 0.6, 0.4):\n    on_demand = payg * HOURS * used\n    reserved = committed * HOURS\n    verdict = 'saves' if reserved < on_demand else 'loses'\n    print(f'used {used:4.0%}: pay as you go {on_demand:7.2f}  committed {reserved:7.2f}  '\n          f'{verdict} {abs(on_demand - reserved):6.2f}')\n", "note": "Quatro meses: a máquina ligada o tempo todo, depois por 80%, 60% e 40% das horas. O pagamento conforme o uso cobra só as horas usadas; o compromisso cobra as 730."}]}
```

Depois pergunte a ele sobre o preço de um ano, e sobre um mais fundo, de três anos, a 0,40:

```
ana@laptop:~/azure/bill$ python3 breakeven.py 1.00 0.60
break-even at 60% of the month
used 100%: pay as you go  730.00  committed  438.00  saves 292.00
used  80%: pay as you go  584.00  committed  438.00  saves 146.00
used  60%: pay as you go  438.00  committed  438.00  loses   0.00
used  40%: pay as you go  292.00  committed  438.00  loses 146.00
ana@laptop:~/azure/bill$ python3 breakeven.py 1.00 0.40
break-even at 40% of the month
used 100%: pay as you go  730.00  committed  292.00  saves 438.00
used  80%: pay as you go  584.00  committed  292.00  saves 292.00
used  60%: pay as you go  438.00  committed  292.00  saves 146.00
used  40%: pay as you go  292.00  committed  292.00  loses   0.00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l14-breakeven\" aria-label=\"O custo mensal de uma máquina contra a parte do mês em que ela roda, com os preços inventados da lição. O pagamento conforme o uso sobe em linha reta de 0 a 730 em 100%. Uma reserva de um ano a 0,60 por hora é plana em 438, e cruza a linha do pagamento conforme o uso em 60%. Uma de três anos a 0,40 é plana em 292, e cruza em 40%. À esquerda de um cruzamento a reserva perde dinheiro, à direita ela economiza.\"><path d=\"M90.0 260.0 L640.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 260.0 L90.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"80.0\" y=\"179.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">292</text><text x=\"80.0\" y=\"139.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">438</text><text x=\"80.0\" y=\"59.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">730</text><text x=\"90.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"310.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><text x=\"420.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"640.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"365.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parte do mês em que a máquina roda</text><path d=\"M90.0 260.0 L640.0 59.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"552.0\" y=\"55.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">conforme o uso</text><path d=\"M90.0 139.6 L640.0 139.6\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"640.0\" y=\"129.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">reserva de um ano</text><path d=\"M90.0 179.7 L640.0 179.7\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"640.0\" y=\"193.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reserva de três anos</text><circle cx=\"420.0\" cy=\"139.6\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"310.0\" cy=\"179.7\" r=\"4.5\" fill=\"var(--paper)\"></circle></svg>", "caption": "Preços inventados: a reserva só compensa à direita de onde a sua linha cruza."}
```

**O ponto de equilíbrio é a razão entre os dois preços.** A 0,60 contra 1,00, a reserva vale a pena
se a máquina roda mais de 60% das horas, e perde dinheiro abaixo disso. Em 60% exatos os dois custam o
mesmo, o que o programa relata como perder nada. O preço de três anos move a linha para 40%: um
desconto mais fundo compra tolerância a horas paradas, e cobra por ela em anos de compromisso.

Isso dá a regra que a própria orientação da Microsoft segue, na ordem dela:

1. **Primeiro remova o que não é usado e reduza o que é grande demais.** Um desconto baixa o preço do
   desperdício; não o remove.
2. **Reserve o que roda o tempo todo e não vai mudar**: o servidor de banco de dados que tem o mesmo
   tamanho há um ano, na região onde vai ficar.
3. **Cubra a parte que se move com um savings plan**, dimensionado pelo gasto que existe em toda hora,
   não pela média: uma média inclui as horas quietas, e são exatamente essas as horas que o plano
   desperdiçaria.
4. **Deixe o resto no pagamento conforme o uso**, que é o preço certo para qualquer coisa que pode não
   existir no mês que vem.

## O que este laboratório não consegue mostrar

**Nada nesta seção foi comprado nem cotado.** Uma reserva e um savings plan são compras feitas pela
cobrança do Azure, e os preços reais vêm da Retail Prices API que o `price.py` da lição 1 lê, que esta
máquina não conseguiu alcançar. Aquele programa pede `priceType eq 'Consumption'`; troque a palavra
por `Reservation` e a mesma lista responde com preços de reserva, cada um o total do seu prazo, e o
próprio prazo num campo chamado `reservationTerm`. Divida esse total pelas horas do prazo, 8.760 para
um ano, e o `breakeven.py` recebe os números reais.
