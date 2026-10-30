---
title: Escolhendo, comprando e acompanhando um compromisso
version: 1
---

**Um compromisso é escolhido a partir do histórico, comprado uma vez, e acompanhado durante todo o prazo.** O
histórico diz qual é de fato a base; a compra a fixa; o acompanhamento diz se a base mudou. Cada passo acontece numa
conta de faturamento e nada disso pode rodar aqui; esta seção vem da documentação do Google.

## Escolhendo pelo histórico

A base não é "quantas máquinas costumamos ter"; é o mínimo dos últimos meses, hora a hora. Dois lugares a dão:

- **A exportação de faturamento** (lição 23), consultada para as máquina-horas de cada hora dos últimos 90 dias: as
  horas mais baixas são a base.
- **As recomendações de compromisso do Google**, que fazem o mesmo cálculo sobre o uso recente e propõem um
  compromisso por região, com a economia esperada. São um ponto de partida, calculado a partir do passado; não sabem
  nada da migração planejada para o próximo trimestre.

**Comprometa abaixo da base medida, não em cima dela.** Uma base de quatro máquinas medida em três meses é uma base
de quatro até o dia em que alguém ajustar o tamanho delas (lição 22) para tipos menores, e aí um compromisso de quatro
do tamanho antigo cobre um uso que não existe mais. Comprometer três deixa espaço para isso.

## Comprando

```sh
gcloud compute commitments create shop-batch-1y \
  --region=southamerica-east1 --plan=12-month \
  --resources=vcpu=12,memory=48GB
```

Não executado: compromissos são compras. Dois detalhes deste comando decidem se ele economiza alguma coisa. **A
região**: um compromisso por recursos cobre uso numa região só, então um compromisso em São Paulo não faz nada por uma
máquina em Iowa. **Os recursos são vCPUs e memória, não máquinas**: doze vCPUs e 48 GB cobrem quatro máquinas de
quatro vCPUs e 16 GB cada, ou qualquer outra combinação da mesma família que some isso.

## Acompanhando

Dois números, todo mês, durante todo o prazo:

| número | o que diz | onde |
|---|---|---|
| **utilização** | a fração dos recursos comprometidos de fato usada | o relatório de compromissos do console de faturamento, ou a exportação de faturamento |
| **cobertura** | a fração do uso elegível que o compromisso pagou | o mesmo relatório |

Utilização abaixo de 100% é dinheiro pago por nada: o compromisso é maior que o uso. Cobertura bem abaixo de 100% é
dinheiro deixado na mesa: a base cresceu e um compromisso a mais economizaria. **Nenhum dos dois números é conferido
por nada a não ser que alguém os ponha num painel**, e a lição 25 faz da própria fatura algo que um alerta consegue
ler.
