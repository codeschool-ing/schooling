---
title: Fluxo de pacientes: a espera, o retorno e o quadro de leitos da manhã
version: 1
---

Os pacientes passam pelo hospital numa fila: chegam, esperam, são atendidos, são internados ou
mandados para casa, ficam, saem e às vezes voltam. **Fluxo de pacientes é o nome que o hospital dá a
essa fila**, e os dois indicadores desta seção medem as duas pontas dela: quanto tempo as pessoas
esperam na porta, e quantas voltam por ela.

## A espera no pronto-socorro

Dez pacientes chegaram ao pronto-socorro do Jacarandá entre seis e sete da noite de uma segunda.
Os minutos que cada um esperou da chegada até ser atendido por um médico, em ordem:

| | A | B |
|---|---|---|
| 1 | Paciente | Minutos |
| 2 | 1 | 12 |
| 3 | 2 | 18 |
| 4 | 3 | 25 |
| 5 | 4 | 31 |
| 6 | 5 | 38 |
| 7 | 6 | 44 |
| 8 | 7 | 52 |
| 9 | 8 | 70 |
| 10 | 9 | 145 |
| 11 | 10 | 210 |

O resumo óbvio é a média:

```localised
=MÉDIA(B2:B11)      64,5
=MED(B2:B11)      41
```

**A média diz uma hora, e nenhum paciente esperou perto de uma hora.** Sete esperaram menos de 55
minutos e dois esperaram mais de duas horas. As duas esperas longas puxam a média para cima; a
mediana, a espera do paciente do meio, é de 41 minutos e é o que um paciente típico encontrou. As
aulas 3 e 4 de `statistics` destrincham média e mediana direito; aqui o ponto é qual das duas um
hospital deve informar.

A resposta é a mediana e também a ponta longa, porque é na ponta longa que está o dano. **Muitos
serviços de saúde informam a espera dentro da qual nove em cada dez pacientes foram atendidos**, o
percentil 90. Com dez pacientes em ordem, é simplesmente o nono:

```localised
=B10      145
```

Nove dos dez foram atendidos em até 145 minutos, e um esperou 210. A planilha tem uma função de
percentil para o mesmo trabalho em milhares de linhas. Uma meta escrita como "90% atendidos em até
duas horas" é descumprida por essa hora, e uma meta escrita como "média abaixo de 70 minutos" é
cumprida por ela.

## O retorno: reinternação em 30 dias

A taxa de reinternação parece simples: dos pacientes que tiveram alta, a parcela internada de novo
em até 30 dias. O outubro de 2025 do Jacarandá: 1.310 altas, das quais 112 voltaram em até 30
dias. **O denominador decide a resposta, e há pelo menos três defensáveis.** Digite os quatro
números numa coluna:

| | A | B |
|---|---|---|
| 1 | Altas | 1310 |
| 2 | Óbitos no hospital | 41 |
| 3 | Reinternados em 30 dias | 112 |
| 4 | Dos quais programados | 30 |

```localised
=ARRED(B3/B1*100;1)      8,5
=ARRED((B3-B4)/B1*100;1)      6,3
=ARRED((B3-B4)/(B1-B2)*100;1)      6,5
```

8,5% conta todo retorno, inclusive os 30 pacientes que voltaram de propósito, para o próximo ciclo
de quimioterapia ou a segunda etapa de uma cirurgia. 6,3% tira os programados do numerador. 6,5%
também tira do denominador os 41 pacientes que morreram no hospital, porque quem morreu não pode
ser reinternado, e contá-lo no denominador enfeita a taxa. **Cada uma está certa pela sua própria
definição**, e um relatório que compara os 6,5% do Jacarandá com os 8,5% de outro hospital compara
duas definições, não dois hospitais.

A taxa também tem um atraso embutido. A taxa de reinternação de novembro só pode ser conhecida 30
dias depois da última alta de novembro, então chega em janeiro. Um painel que mostra a taxa de
novembro no começo de dezembro mostra um número que ainda está subindo.

## A manhã da gestora de leitos

Toda manhã às sete, a gestora de leitos do Jacarandá, uma enfermeira sênior chamada Cláudia Reis,
decide onde vão dormir os pacientes que esperam no pronto-socorro. A pergunta dela é a da aula 14,
na forma mais crua: o que precisa da minha atenção agora? A tela dela gira em torno de uma conta
por ala: leitos, menos os ocupados, mais os pacientes que devem sair hoje, menos as internações
eletivas já marcadas, menos os pacientes do pronto-socorro que já esperam por aquela ala.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Maquete da tela da gestora de leitos às 07:00 de terça, 2 de dezembro de 2025. Quatro quadros: 7 pacientes no pronto-socorro esperando leito, o mais antigo há 9 horas e 40 minutos; 42 altas previstas hoje; 32 internações eletivas marcadas; leitos de UTI livres à noite: menos 1. Uma tabela por ala, a mais apertada primeiro, mostra leitos, ocupados, saindo hoje, marcados, vindos do pronto-socorro e livres à noite: UTI menos 1, cirúrgica 3, clínica médica 5, pediatria 12, maternidade 13.\" data-fig=\"l19-bed-board\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"380.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Leitos · Hospital Jacarandá</text><text x=\"692.0\" y=\"34.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ter., 02/12/2025, 07:00</text><text x=\"692.0\" y=\"50.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">censo das 06:45, sistema de internação</text><rect x=\"28.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">7</text><text x=\"40.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no PS, esperando leito</text><rect x=\"196.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">42</text><text x=\"208.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">altas previstas hoje</text><rect x=\"364.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"376.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">32</text><text x=\"376.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">eletivas marcadas hoje</text><rect x=\"532.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"544.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">−1</text><text x=\"544.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leitos de UTI livres à noite</text><text x=\"40.0\" y=\"157.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">maior espera no PS por leito: 9 h 40 min</text><text x=\"28.0\" y=\"196.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ala</text><text x=\"250.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">leitos</text><text x=\"340.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ocupados</text><text x=\"430.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">saindo</text><text x=\"520.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">marcados</text><text x=\"600.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">do PS</text><text x=\"692.0\" y=\"196.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">livres à noite</text><path d=\"M28.0 204.0 L692.0 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M20.0 216.0 H24.0 V232.0 H20.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"28.0\" y=\"228.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">UTI</text><text x=\"250.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"340.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"430.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"520.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><text x=\"600.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"692.0\" y=\"228.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">−1</text><text x=\"28.0\" y=\"258.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Cirúrgica</text><text x=\"250.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">64</text><text x=\"340.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">58</text><text x=\"430.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">12</text><text x=\"520.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">14</text><text x=\"600.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"692.0\" y=\"258.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text><text x=\"28.0\" y=\"288.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Clínica médica</text><text x=\"250.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">96</text><text x=\"340.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">94</text><text x=\"430.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">14</text><text x=\"520.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">6</text><text x=\"600.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">5</text><text x=\"692.0\" y=\"288.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">5</text><text x=\"28.0\" y=\"318.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pediatria</text><text x=\"250.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">28</text><text x=\"340.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">18</text><text x=\"430.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">5</text><text x=\"520.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text><text x=\"600.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"692.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">12</text><text x=\"28.0\" y=\"348.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Maternidade</text><text x=\"250.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">32</text><text x=\"340.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">21</text><text x=\"430.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">9</text><text x=\"520.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">7</text><text x=\"600.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"692.0\" y=\"348.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">13</text><text x=\"28.0\" y=\"376.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">livres à noite = leitos − ocupados + saindo − marcados − do PS</text></svg>", "caption": "A tela da gestora de leitos responde a uma pergunta às sete da manhã: onde vão dormir hoje os pacientes que esperam no pronto-socorro? A ala que não consegue recebê-los é a primeira linha."}
```

O hospital como um todo terá 32 leitos livres hoje à noite. **A UTI vai ficar com um a menos**, e
ela é a primeira linha porque é a única que pede uma decisão antes do meio-dia: um paciente
transferido mais cedo para uma enfermaria, uma cirurgia eletiva que precisa de UTI depois adiada
por um dia, ou uma transferência para outro hospital. O quadro da maior espera no pronto-socorro
está ali pelo mesmo motivo. Nove horas e quarenta minutos numa maca é um paciente, e uma média o
enterraria.
