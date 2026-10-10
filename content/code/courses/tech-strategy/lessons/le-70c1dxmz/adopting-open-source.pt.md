---
title: Quanto custa adotar código aberto
version: 1
---

"É código aberto, então é de graça" aparece em toda reunião de construir ou comprar, e a planilha
da Coreto responde sem rodeios. **Adotar é a mais cara das três opções**: R$ 579.600 em três anos,
R$ 129.600 a mais do que construir e R$ 146.520 a mais do que comprar. O software não custa nada.
Rodá-lo custa mais do que qualquer outra coisa na mesa.

## Para onde vai o dinheiro

Divida o total de três anos de cada opção por tipo — trabalho feito uma vez, pessoas todo ano,
dinheiro pago a terceiros todo ano — e as três opções se revelam bichos diferentes:

| | trabalho feito uma vez | pessoas, três anos | pago a terceiros, três anos | total |
|---|---|---|---|---|
| construir | R$ 144.000 | R$ 198.000 | R$ 108.000 | R$ 450.000 |
| comprar | R$ 36.000 | R$ 39.600 | R$ 357.480 | R$ 433.080 |
| adotar | R$ 72.000 | R$ 273.600 | R$ 234.000 | R$ 579.600 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 225\" role=\"img\" aria-label=\"Três barras empilhadas, uma por opção, com o total de três anos dividido em trabalho pontual, pessoas todo ano e dinheiro pago a terceiros todo ano. Construir: R$ 144.000, R$ 198.000 e R$ 108.000, total R$ 450.000. Comprar: R$ 36.000, R$ 39.600 e R$ 357.480, total R$ 433.080. Adotar: R$ 72.000, R$ 273.600 e R$ 234.000, total R$ 579.600.\"><text x=\"100\" y=\"49\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Construir</text><rect x=\"110\" y=\"30\" width=\"129.6\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"239.6\" y=\"30\" width=\"178.2\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\"></rect><rect x=\"417.8\" y=\"30\" width=\"97.2\" height=\"28\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"523\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">450.000</text><text x=\"100\" y=\"99\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Comprar</text><rect x=\"110\" y=\"80\" width=\"32.4\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"142.4\" y=\"80\" width=\"35.64\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\"></rect><rect x=\"178.04\" y=\"80\" width=\"321.732\" height=\"28\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"507.772\" y=\"98\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">433.080</text><text x=\"100\" y=\"149\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Adotar</text><rect x=\"110\" y=\"130\" width=\"64.8\" height=\"28\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"174.8\" y=\"130\" width=\"246.24\" height=\"28\" rx=\"0\" fill=\"var(--phosphor)\"></rect><rect x=\"421.04\" y=\"130\" width=\"210.6\" height=\"28\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"639.64\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">579.600</text><rect x=\"110\" y=\"196\" width=\"14\" height=\"14\" rx=\"0\" fill=\"var(--phosphor-dim)\"></rect><text x=\"130\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">trabalho pontual</text><rect x=\"280\" y=\"196\" width=\"14\" height=\"14\" rx=\"0\" fill=\"var(--phosphor)\"></rect><text x=\"300\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pessoas, todo ano</text><rect x=\"470\" y=\"196\" width=\"14\" height=\"14\" rx=\"0\" fill=\"var(--amber)\"></rect><text x=\"490\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pago a terceiros, todo ano</text></svg>", "caption": "Os mesmos totais de três anos, divididos por tipo. Comprar transforma quase todo o custo numa fatura; adotar não paga licença e carrega a maior linha de pessoas das três."}
```

**Adotar não tem licença e tem a maior linha de pessoas das três.** Seus R$ 273.600 são 30% de um
engenheiro e 80 horas de atualizações, todo ano, por três anos. Comprar é o espelho: quase todo o
custo é uma fatura, e a linha de pessoas é a menor. Essa diferença pesa além dos totais, porque
dinheiro numa fatura e horas do time não são igualmente fáceis de achar. Uma fatura precisa de uma
linha no orçamento e de uma assinatura. Horas saem de um time que já tem backlog, e ninguém assina
por elas — a aula 9 trata de por que essa é a linha que se esconde.

## Os três custos que uma licença gratuita não cobre

**Atualizações.** Um motor de código aberto lança versões no ritmo dele. Ficar numa versão antiga é
perder correções de segurança; ir para uma nova é ler as notas de versão, testar as consultas e às
vezes reconstruir todos os índices. A estimativa da Coreto é de 80 horas por ano, e uma versão maior
com mudanças incompatíveis pode consumir boa parte disso de uma vez.

**Operação.** Alguém é acionado quando o cluster fica sem disco de madrugada, e alguém o restaura de um
backup que precisa existir e precisa ter sido testado. Os 30% de engenheiro da Coreto são 528 horas
por ano, e caem em quem conhece melhor o motor. Esse conhecimento costuma ficar com uma ou duas
pessoas, e o dia em que elas saem é um custo que a planilha não consegue guardar.

**A própria licença pode mudar.** Uma licença de código aberto é uma decisão de quem é dono do
projeto, e donos já mudaram de ideia. A Elastic tirou o Elasticsearch da licença Apache 2.0 em
janeiro de 2021. A HashiCorp passou o Terraform para a Business Source License em agosto de 2023. O
Redis saiu da licença BSD em março de 2024. Uma mudança assim vale para as versões novas, e as
cópias já lançadas mantêm a licença com que vieram. Mesmo assim, todo time que as rodava ganhou uma
pergunta nova: as novas condições servem para o nosso uso? Se não servem, ficamos numa versão
antiga, vamos para outro projeto, ou pagamos? **Toda
resposta a essa pergunta custa alguma coisa**, e nada disso está numa planilha feita no ano anterior.

## Quando adotar é a resposta certa

Nada disso faz de adotar um erro. Faz dela uma escolha com preço, e o preço vale a pena quando o
motivo é um que as outras duas opções não atendem:

| motivo | por que as outras duas ficam aquém |
|---|---|
| os dados não podem sair da sua própria infraestrutura | comprar põe uma cópia com o fornecedor; construir é escrever o que o motor já faz |
| você precisa mudar o comportamento do motor | o fornecedor não vai mudá-lo por você, e escrever um motor não é o seu trabalho |
| o time já opera o mesmo motor para outra coisa | a vantagem delas encolhe, porque a linha de operação de adotar já está quase toda paga |

A última linha é a que mais muda a conta. Se outro time da Coreto já rodasse o mesmo motor, a linha
de operação seria dividida com trabalho que já é feito, e as atualizações aconteceriam de qualquer
jeito. Nenhum time da Coreto roda, então os 30% inteiros cairiam no time de Catálogo.

## A resposta da Coreto

Para a busca, nenhum dos três motivos se aplica. Os eventos da Coreto são públicos — são espetáculos
à venda —, então um fornecedor ter uma cópia não preocupa; ninguém precisa mudar o motor; e ninguém
na Coreto roda um hoje. Adotar seria pagar o máximo das três opções para virar operador de algo que é
contexto.

O Davi escreveu uma frase sobre isso na nota para a Helena:

> **Adotar foi considerado e descartado**: custa R$ 146.520 a mais do que comprar em três anos, quase
> metade dos seus R$ 579.600 são horas de pessoas, e faria do time de Catálogo o operador de um motor
> de busca que a Coreto não precisa controlar.

Escreva as opções descartadas numa recomendação, com os números delas. Alguém vai perguntar pela
opção de código aberto no ano que vem, e uma frase com um número responde a pergunta de uma vez.
A aula 17 dá formato a esse hábito: o registro de decisão de arquitetura (ADR).
