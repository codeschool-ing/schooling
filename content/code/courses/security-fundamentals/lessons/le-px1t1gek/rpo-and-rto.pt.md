---
title: Quanto perder, e quanto tempo ficar parado
version: 1
---

Dois números transformam "temos backup" numa promessa que alguém consegue conferir. Os dois são
decididos pelo negócio, como o apetite a risco da aula 3, e depois a TI projeta para cumpri-los.

```schooling-figure
{"svg": "<svg id=\"sf-rpo-rto\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo. O último backup bom é feito; depois, acontece o desastre; mais tarde, o serviço volta. O trecho do último backup ao desastre são os dados perdidos, limitados pelo objetivo de ponto de recuperação. O trecho do desastre até o serviço voltar é o tempo fora do ar, limitado pelo objetivo de tempo de recuperação.\"><defs><marker id=\"sf-rpo-rto-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 100 L700 100\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#sf-rpo-rto-ah-paper-dim)\"></path><text x=\"700\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><path d=\"M140 80 L140 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"140\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">último backup bom</text><path d=\"M400 80 L400 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"400\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">desastre</text><path d=\"M620 80 L620 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><text x=\"620\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">serviço de volta</text><rect x=\"142\" y=\"56\" width=\"256\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dados perdidos: no máximo o RPO</text><rect x=\"402\" y=\"56\" width=\"216\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fora do ar: no máximo o RTO</text><text x=\"270\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a frequência do backup</text><text x=\"510\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a rapidez da restauração</text></svg>", "caption": "O RPO olha para trás a partir do desastre; o RTO, para a frente."}
```

**Objetivo de ponto de recuperação (RPO)**, de *recovery point objective*: quanto dado, medido em
tempo, o negócio pode perder. Se o RPO é de 24 horas, depois de um desastre é aceitável voltar com os
dados de ontem e perder o trabalho de hoje. O RPO decide **com que frequência** fazer backup: um backup
noturno não cumpre um RPO de uma hora.

**Objetivo de tempo de recuperação (RTO)**, de *recovery time objective*: quanto tempo o negócio pode
ficar parado. Se o RTO é de quatro horas, então a partir do momento do desastre a loja tem de estar
vendendo de novo em quatro horas. O RTO decide **com que rapidez** a restauração precisa ser, o que quer
dizer onde fica o backup, qual o tamanho dele, e se alguém já praticou.

Para a livraria, os sócios decidiram:

| | meta | o que exige |
|---|---|---|
| pedidos e clientes | RPO de 24 horas, RTO de 8 horas | um backup noturno; uma restauração ensaiada que leve menos de um dia útil |
| o site público | RPO de uma semana, RTO de 2 horas | o site muda pouco; um segundo servidor ou um serviço de hospedagem que assuma depressa |

Repare na segunda linha. Os dados do site quase não mudam, então perder uma semana tudo bem, mas cada
hora fora do ar perde vendas, então ele precisa voltar rápido. Os pedidos são o contrário. **Os dois
números são independentes**, e tratá-los como um só leva a pagar por velocidade onde ela não é
necessária e a faltar onde é.

### O que os números custam

Metas mais baixas custam mais, mais ou menos na mesma proporção. Um RPO zero quer dizer que nenhum dado
pode se perder nunca, o que exige toda mudança escrita em dois lugares ao mesmo tempo; um RTO de minutos
exige um sistema reserva pronto para assumir. As duas coisas são possíveis, e as duas são caras. É por
isso que essas são decisões de negócio: quem é dono dos pedidos sabe quanto custa um dia perdido, e a
conta da aula 3 diz se a meta mais barata vale a pena.

### Testar é a única prova

Um RTO de oito horas é uma alegação até alguém restaurar os dados em menos de oito horas. A primeira
restauração de verdade é uma péssima hora para descobrir que o backup está num disco que ninguém acha,
que a chave de cifra está no servidor que acabou de morrer, ou que a restauração leva dois dias. Então
restaurações são **praticadas**, com agenda, e cronometradas. A próxima seção é a primeira da loja.
