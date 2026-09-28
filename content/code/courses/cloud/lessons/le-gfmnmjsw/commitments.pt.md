---
title: "Compromissos: um desconto em troca de uma promessa"
version: 1
---

Sob demanda é o preço de manter todas as opções abertas: você pode parar qualquer máquina a qualquer hora
e não dever mais nada. **Um compromisso é a mesma máquina vendida mais barata em troca da promessa de
pagar por ela, usando ou não**, em geral por um ou três anos. Todo provedor grande vende um. A AWS tem
Reserved Instances, que nomeiam um tipo de máquina numa região, e Savings Plans, que prometem um valor de
gasto por hora valendo para muitos tipos. O Google Cloud tem os committed use discounts, e o Azure tem
reservas e o próprio savings plan.

## Quanto a tabela diz que vale

O segundo bloco da tabela é o preço reservado por 1 ano sem pagamento adiantado, ao lado do preço sob
demanda do primeiro bloco. Duas linhas da coluna `sa-east-1`:

| máquina | sob demanda, por hora | reservada por 1 ano, por hora | desconto |
| --- | --- | --- | --- |
| `m7i.large` | 0.16065 | 0.09956 | 38,0% |
| `t3.medium` | 0.06720 | 0.03860 | 42,6% |

O desconto é um menos a razão: 1 − 0,09956 / 0,16065 = 0,380, e 1 − 0,03860 / 0,06720 = 0,426. Em
dinheiro, uma `m7i.large` economiza 0,06109 por hora, o que num mês de 730 horas dá **44,60 USD por
máquina**. Uma `t3.medium` economiza 0,02860 por hora, 20,88 por mês; as duas máquinas da estimativa
custariam 56,36 por mês em vez de 98,11.

## Quanto custa a promessa

"Sem pagamento adiantado" soa como sem obrigação, e não é. Quer dizer que o pagamento é espalhado pelo
ano em vez de feito no primeiro dia. **Uma reserva de 1 ano de uma `t3.medium` é uma dívida de
0,03860 × 8.760 = 338,14 USD**, paga em parcelas por hora, rodando alguma máquina ou não. Se a aplicação
for reescrita com funções no mês quatro, os oito meses restantes continuam sendo cobrados.

Isso dá um teste simples. A reserva custa 0,03860 por toda hora; sob demanda custa 0,06720, mas só pelas
horas em que a máquina de fato roda. As duas se igualam quando a máquina roda 0,03860 / 0,06720 =
**57,4% das horas**. Uma máquina que roda mais que isso sai mais barata reservada; uma que roda menos,
como um ambiente de teste desligado à noite e nos fins de semana, sai mais barata sob demanda, por maior
que seja o desconto anunciado.

## Comprometa-se com o piso

O uso de uma aplicação de verdade se mexe. O grupo de autoscaling da aula 4 roda duas máquinas à noite
e seis na hora mais cheia do mês mais cheio, e no resto do ano fica em algum ponto entre as duas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Máquinas ligadas ao longo de um ano de uma aplicação inventada. O número nunca cai abaixo de 2, sobe ao longo do ano e chega a 6 uma vez, perto do fim. A faixa de 0 a 2 é o piso comprometido, reservado e usado a toda hora. A linha acima dele é capacidade sob demanda que vem e vai. Uma linha tracejada em 6 marca o pico, onde um compromisso pagaria horas ociosas.\"><defs><marker id=\"flr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"186\" width=\"560\" height=\"64\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">piso comprometido: reservado, usado a toda hora</text><path d=\"M60.0 186.0 L65.4 147.5 L70.9 162.1 L76.3 186.0 L81.7 158.3 L87.2 157.6 L92.6 153.2 L98.1 148.3 L103.5 139.3 L108.9 156.3 L114.4 147.8 L119.8 166.8 L125.2 134.4 L130.7 157.3 L136.1 135.4 L141.6 160.4 L147.0 144.0 L152.4 144.2 L157.9 136.5 L163.3 137.5 L168.7 151.6 L174.2 142.2 L179.6 151.3 L185.0 127.2 L190.5 156.1 L195.9 135.2 L201.4 162.2 L206.8 132.5 L212.2 141.6 L217.7 132.1 L223.1 142.7 L228.5 150.7 L234.0 136.3 L239.4 142.6 L244.9 128.0 L250.3 155.7 L255.7 141.6 L261.2 160.3 L266.6 128.2 L272.0 146.7 L277.5 186.0 L282.9 154.3 L288.3 143.2 L293.8 137.1 L299.2 141.1 L304.7 136.1 L310.1 160.9 L315.5 140.0 L321.0 158.9 L326.4 130.4 L331.8 157.8 L337.3 143.7 L342.7 159.5 L348.2 139.8 L353.6 142.8 L359.0 144.5 L364.5 148.3 L369.9 161.4 L375.3 139.9 L380.8 156.5 L386.2 136.3 L391.7 171.1 L397.1 149.2 L402.5 161.0 L408.0 138.0 L413.4 150.3 L418.8 148.8 L424.3 159.0 L429.7 153.4 L435.1 139.7 L440.6 153.9 L446.0 141.9 L451.5 175.1 L456.9 142.2 L462.3 160.4 L467.8 135.1 L473.2 156.1 L478.6 150.3 L484.1 152.7 L489.5 142.2 L495.0 137.3 L500.4 148.7 L505.8 144.2 L511.3 160.3 L516.7 131.2 L522.1 155.6 L527.6 129.5 L533.0 157.8 L538.4 137.9 L543.9 141.7 L549.3 127.6 L554.8 132.0 L560.2 139.7 L565.6 135.8 L571.1 138.7 L576.5 117.2 L581.9 140.1 L587.4 121.1 L592.8 58.0 L598.3 116.6 L603.7 128.1 L609.1 111.6 L614.6 124.9 L620.0 127.8\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M60 58 L620 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"628\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pico</text><text x=\"628\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o piso</text><text x=\"210\" y=\"93.19999999999999\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">acima do piso: sob demanda, vem e vai</text><path d=\"M60 250 L620 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 250 L60 45.19999999999999\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"50\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"50\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"50\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"50\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"50\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">máquinas ligadas</text><text x=\"60\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">janeiro</text><text x=\"620\" y=\"270\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dezembro</text></svg>", "caption": "Um ano inventado, não uma medição. As duas máquinas que rodam a toda hora são para o que serve um compromisso. Comprometer-se com seis pagaria, a cada hora do ano, por quatro máquinas que foram necessárias em poucos dias."}
```

**Comprometa-se com o piso do seu uso, não com o pico.** As máquinas que rodam todas as horas do ano são
aquelas para as quais um compromisso existe: estão sempre em uso, então cada hora da promessa vale o
desconto. As máquinas acima do piso vêm e vão, e pagar sob demanda por elas é o que compra a liberdade de
tirá-las. Comprometa-se com o pico e as horas entre o pico e o uso real são pagas e desperdiçadas. Com 42,6% de desconto, uma `t3.medium` reservada que fica ociosa mais de 42,6% das horas custou mais do que
teria custado sob demanda.

Mais duas regras decorrem da mesma ideia. Comprometa-se com o que você mediu ao longo de meses, não com a
estimativa, porque a estimativa nunca foi testada contra um mês de verdade. E, na dúvida, prefira o compromisso mais fácil de reaproveitar. Um Savings Plan que acompanha o seu gasto para outro tipo de
máquina dá um desconto menor que uma reserva de um tipo só, e vale muito mais no dia em que você troca de
tipo.
