---
title: O Unified Catalog, e quanto custa o mapa
version: 1
---

**Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.**

**O Data Map é o que uma máquina encontrou; o Unified Catalog é o que as pessoas combinaram.** O
catálogo atual da Microsoft organiza os dados por **domínios de governança**, uma área do negócio como
vendas ou logística, cada um com **produtos de dados**: um conjunto de ativos publicados juntos para
um fim, como "pedidos da Quitanda, diários, para o financeiro", com um responsável, uma descrição, os
termos de uso e um jeito de pedir acesso. Os **termos do glossário** dão a palavras do negócio um
significado só, para que "cliente ativo" seja definido uma vez e ligado às colunas que o implementam,
e as regras de **qualidade de dados** pontuam os ativos de um produto contra expectativas como
"nenhum id de pedido nulo". Os ativos do Data Map são a matéria-prima; o catálogo é onde alguém assume
a responsabilidade por eles.

**É também a parte que nenhuma ferramenta preenche sozinha.** Uma varredura consegue produzir cem mil
ativos numa noite; não consegue escrever o que "cliente ativo" quer dizer nem decidir quem é dono da
tabela de pedidos. Um catálogo cujos produtos não têm responsáveis e cujos termos não têm definições é
a saída da varredura com uma caixa de busca mais bonita, e é no que a maioria dos catálogos se
transforma quando o trabalho de curadoria não tem ninguém designado.

## Quanto custa

**O Data Map é cobrado por capacidade, por hora, e as varreduras pelo processamento que usam**: o mapa
precisa de pelo menos uma unidade de capacidade enquanto a conta existir, mais quando guarda muitos
ativos ou é muito consultado, e cada varredura é cobrada pelo tempo de computação em que roda. Os
recursos mais novos do catálogo têm medidores próprios, que mudaram à medida que o produto mudou; a
tabela de preços da lição 1 lista o que vale no dia em que você olhar. A conta abaixo usa preços
ilustrativos, números redondos para a soma e não os do Azure: 0,40 USD por unidade de capacidade-hora
para o mapa, e 0,60 USD por vCore-hora de varredura.

| item | quantidade num mês de 30 dias | preço ilustrativo | mês |
|---|---|---|---|
| Data Map, uma unidade de capacidade, sempre ligado | 730 unidades-hora | 0,40 USD | 292,00 USD |
| uma varredura noturna do lake usando 4 vCore-horas | 30 × 4 = 120 vCore-horas | 0,60 USD | 72,00 USD |
| | | | **364,00 USD** |

**O mapa é um custo fixo e as varreduras são o variável.** A capacidade do mapa é paga haja busca ou
não, o que faz de uma conta do Purview algo a ter uma vez para a empresa e não uma por equipe. As
varreduras acompanham o agendamento: varrer o lake toda noite em vez de toda semana multiplica essa
linha por sete, e uma varredura incremental, que lê só o que mudou, é o que mantém um agendamento
noturno acessível. Se uma varredura noturna vale a pena depende de quão rápido dados pessoais novos
aparecem em lugares que ninguém esperava, que a seção de classificação mostrou ser justamente o caso
em que ela é mais fraca.

Para os preços reais, com rede; não foi executado para este curso:

```sh
python prices.py "Microsoft Purview"
```

Como com todo serviço deste curso, o nome com que a lista de preços arquiva um serviço é escolha da
Microsoft, e uma resposta vazia quer dizer que o filtro não encontrou serviço nenhum, e não que o
serviço é de graça.
