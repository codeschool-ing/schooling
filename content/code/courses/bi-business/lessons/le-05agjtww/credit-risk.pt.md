---
title: Risco de crédito: por que uma carteira que cresce parece segura
version: 1
---

O número que o conselho de uma financeira mais acompanha é a taxa de inadimplência: a parte do dinheiro
emprestado que está inadimplente. Na Ipê, um empréstimo está **inadimplente quando uma parcela está com
90 dias ou mais de atraso**, a definição que ela também reporta para fora. O problema não é a definição.
É o denominador, e é a armadilha que a primeira seção desta aula nomeou.

## Um empréstimo não fica inadimplente no primeiro dia

A primeira parcela de um empréstimo pessoal vence um mês depois de o dinheiro ser pago. Se nunca for
paga, chega a 90 dias de atraso três meses depois disso. **Então um empréstimo feito no mês passado não
pode estar inadimplente ainda, por pior que seja**, e um feito há quatro meses teve uma chance só.
Quanto mais novos os empréstimos de uma carteira, menor a inadimplência dela, qualquer que seja a
qualidade.

A Ipê lançou o empréstimo pessoal em janeiro de 2024 e o fez crescer rápido: R$ 20 milhões emprestados
no primeiro trimestre, R$ 105 milhões no último trimestre de 2025. Em 31 de dezembro de 2025 o produto
inteiro tinha emprestado R$ 394 milhões, e **R$ 185 milhões, 47%, tinham sido emprestados nos últimos
seis meses**. A inadimplência dessa carteira é uma taxa cujo denominador é metade feito de empréstimos
jovens demais para estar no numerador.

## Safras

A saída é parar de perguntar sobre a carteira inteira e agrupar os empréstimos por quando foram feitos.
Um grupo de empréstimos feitos no mesmo período é uma **safra**, palavra emprestada do vinho, e cada
safra é acompanhada enquanto envelhece. Comparar safras na mesma idade elimina o problema da juventude,
porque todas são comparadas no ponto em que tiveram o mesmo tempo para dar errado. É a coorte da aula 9
de `analytics-bi` aplicada a empréstimos.

Digite as safras da Ipê numa aba nova a partir de A1. A coluna B é o valor emprestado em cada trimestre,
em milhões de reais; C, D e E são a porcentagem dele com 90 dias ou mais de atraso aos 6, 9 e 12 meses
de carteira, contados do fim do trimestre, com 12 valendo doze ou mais. **Deixe a célula vazia onde a
safra ainda não chegou àquela idade**:

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Safra | Emprestado | M6 | M9 | M12 |
| 2 | 2024 T1 | 20 | 2,0 | 3,4 | 4,5 |
| 3 | 2024 T2 | 24 | 2,1 | 3,5 | 4,6 |
| 4 | 2024 T3 | 28 | 2,2 | 3,6 | 4,8 |
| 5 | 2024 T4 | 32 | 2,3 | 3,8 | 5,0 |
| 6 | 2025 T1 | 45 | 2,9 | 4,7 | |
| 7 | 2025 T2 | 60 | 3,4 | | |
| 8 | 2025 T3 | 80 | | | |
| 9 | 2025 T4 | 105 | | | |

O triângulo vazio no canto de baixo à direita é o ponto da tabela: é tudo o que a carteira ainda não
contou à Ipê.

## A taxa da manchete

Primeiro, a taxa que o relatório de risco mostra, da carteira inteira hoje. Cada safra entra com a taxa
da idade que já alcançou. Em F1 digite `Agora`, e em F2 a última célula preenchida da linha, ou 0 se não
houver nenhuma:

```localised
=SE(E2<>"";E2;SE(D2<>"";D2;SE(C2<>"";C2;0)))      4,5
```

Copie até F9: as duas safras mais novas ficam com 0. Depois a taxa da carteira, pesando cada safra pelo
dinheiro emprestado:

```localised
=ARRED(SOMARPRODUTO(B2:B9;F2:F9)/SOMA(B2:B9);2)      2,31
```

**2,31%, contra um apetite de risco de 4% aprovado pelo conselho.** Sozinho, o número diz que a Ipê tem
espaço para emprestar mais, e a clientes mais arriscados. Diz isso porque R$ 185 milhões dos R$ 394
milhões contribuem com zero.

## A mesma idade

Agora compare igual com igual. A média da taxa aos seis meses das quatro safras de 2024, e das duas de
2025 que já têm uma:

```localised
=ARRED(MÉDIA(C2:C5);1)      2,2
=ARRED(MÉDIA(C6:C7);1)      3,2
```

**Na mesma idade, os empréstimos de 2025 estão estragando cerca de uma vez e meia mais rápido que os de
2024.** A safra 2025 T2 chegou aos seis meses com 3,4%, 61,9% acima dos 2,1% da 2024 T2. E as safras de
2024 que já chegaram aos doze meses estão em 4,76% do dinheiro emprestado, com o mesmo peso: acima do
apetite de 4%, antes de as safras piores de 2025 envelhecerem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 440\" role=\"img\" aria-label=\"Um esboço da visão mensal de risco da Ipê em dezembro de 2025, empréstimo pessoal. Três blocos: parcela do valor emprestado hoje com 90 dias ou mais de atraso, 2,31%, contra um apetite de risco de 4,0%; custo do risco da carteira toda, 9,0% em 2025 contra 7,0% em 2024; e a parcela do valor emprestado com menos de seis meses, 47,0%, que ainda não consegue mostrar atrasos. Abaixo, curvas de safra: a parcela com 90 dias ou mais de atraso aos 6, 9 e 12 meses de carteira, uma linha por trimestre de concessão. As quatro linhas de 2024 ficam juntas, de 2,0 a 2,3% aos seis meses e 4,5 a 5,0% aos doze. As linhas de 2025 ficam acima delas: 2,9 e 3,4% aos seis meses.\" data-fig=\"l17-risk\"><rect x=\"8.0\" y=\"8.0\" width=\"704.0\" height=\"424.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24.0\" y=\"36.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Ipê Crédito · visão de risco · empréstimo pessoal · dez. 2025</text><rect x=\"24.0\" y=\"52.0\" width=\"216.0\" height=\"86.0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38.0\" y=\"72.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">90+ dias de atraso, carteira toda</text><text x=\"38.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">2,31%</text><text x=\"38.0\" y=\"124.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">apetite de risco 4,0%</text><rect x=\"252.0\" y=\"52.0\" width=\"216.0\" height=\"86.0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"266.0\" y=\"72.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">custo do risco, empresa toda</text><text x=\"266.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">9,0%</text><text x=\"266.0\" y=\"124.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2024: 7,0%</text><rect x=\"480.0\" y=\"52.0\" width=\"216.0\" height=\"86.0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"494.0\" y=\"72.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">emprestado nos últimos 6 meses</text><text x=\"494.0\" y=\"102.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"24\" font-weight=\"600\" fill=\"var(--paper)\">47,0%</text><text x=\"494.0\" y=\"124.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">novo demais para mostrar atraso</text><text x=\"24.0\" y=\"164.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Safras: parcela com 90+ dias de atraso, por meses de carteira</text><path d=\"M74.0 400.0 L80.0 400.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"70.0\" y=\"404.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><path d=\"M74.0 328.7 L80.0 328.7\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"70.0\" y=\"332.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2%</text><path d=\"M74.0 257.3 L80.0 257.3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"70.0\" y=\"261.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4%</text><path d=\"M74.0 186.0 L80.0 186.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"70.0\" y=\"190.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6%</text><path d=\"M80.0 182.0 L80.0 400.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M80.0 400.0 L438.0 400.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"80.0\" y=\"416.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 meses</text><text x=\"255.0\" y=\"416.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">9 meses</text><text x=\"430.0\" y=\"416.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">12 meses</text><path d=\"M80.0 257.3 L430.0 257.3\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></path><text x=\"442.0\" y=\"261.3\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">apetite</text><path d=\"M80.0 328.7 L255.0 278.7 L430.0 239.5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M77.0 325.7 H83.0 V331.7 H77.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M252.0 275.7 H258.0 V281.7 H252.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M427.0 236.5 H433.0 V242.5 H427.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M80.0 325.1 L255.0 275.2 L430.0 235.9\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M77.0 322.1 H83.0 V328.1 H77.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M252.0 272.2 H258.0 V278.2 H252.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M427.0 232.9 H433.0 V238.9 H427.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M80.0 321.5 L255.0 271.6 L430.0 228.8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M77.0 318.5 H83.0 V324.5 H77.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M252.0 268.6 H258.0 V274.6 H252.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M427.0 225.8 H433.0 V231.8 H427.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M80.0 318.0 L255.0 264.5 L430.0 221.7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><path d=\"M77.0 315.0 H83.0 V321.0 H77.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M252.0 261.5 H258.0 V267.5 H252.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M427.0 218.7 H433.0 V224.7 H427.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M80.0 296.6 L255.0 232.4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M77.0 293.6 H83.0 V299.6 H77.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M252.0 229.4 H258.0 V235.4 H252.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M77.0 275.7 H83.0 V281.7 H77.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"66.0\" y=\"276.7\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2025 T2</text><text x=\"241.0\" y=\"230.4\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2025 T1</text><text x=\"442.0\" y=\"217.7\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2024, quatro trimestres</text><text x=\"540.0\" y=\"250.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2025 T3 e T4: R$ 185 milhões</text><text x=\"540.0\" y=\"270.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">emprestados, sem ponto no</text><text x=\"540.0\" y=\"290.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">gráfico ainda</text><text x=\"540.0\" y=\"310.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Aos seis meses, cada safra</text><text x=\"540.0\" y=\"330.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">de 2025 está acima de</text><text x=\"540.0\" y=\"350.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todas as de 2024.</text></svg>", "caption": "A visão de risco da Ipê. A taxa da manchete fica bem abaixo do apetite, e o bloco ao lado diz por que isso quer dizer pouco: quase metade do dinheiro foi emprestada recentemente demais para ter atrasado. As curvas de safra, comparadas na mesma idade, mostram os empréstimos novos estragando mais rápido."}
```

Isso responde à pergunta que a seção anterior deixou aberta. O custo do risco subiu de 7,0% para 9,0% em
parte porque os empréstimos de 2024 chegaram à idade de atrasar, e em parte porque os de 2025 são piores.
A taxa da manchete também subiu, de 1,14% no fim de 2024 para 2,31% um ano depois, e os dois números
ficaram abaixo do apetite, então nenhum assustou ninguém.

## O que a visão de risco faz com isso

A visão mensal de risco da Fernanda mantém a taxa da manchete, porque o conselho e o regulador a pedem,
e põe ao lado dela duas coisas que impedem que seja lida sozinha: **a parcela da carteira jovem demais
para mostrar atraso**, e as curvas de safra, cada safra nova desenhada contra as antigas na mesma idade.
Uma safra que começa acima das mais velhas aos seis meses é o aviso mais cedo que uma financeira tem, um
ano antes de chegar ao resultado.

As safras não dizem por que os empréstimos de 2025 são piores. Uma financeira que passa de R$ 20 milhões
para R$ 105 milhões por trimestre raramente encontra tantos clientes a mais da mesma qualidade, e os
suspeitos de costume são uma regra de aprovação afrouxada, um canal novo de aquisição ou uma mudança na
economia. Conferir cada um é o trabalho diagnóstico da aula 7. A simplificação desta planilha também
precisa ser dita: as taxas aqui são partes do valor emprestado, ignorando as parcelas já pagas, o que
muda os níveis que uma equipe de risco de verdade reporta, e não o padrão.
