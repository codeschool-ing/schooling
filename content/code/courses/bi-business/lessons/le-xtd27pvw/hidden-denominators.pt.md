---
title: Denominadores escondidos
version: 1
---

"Reclamações sobem 40%" é uma frase que prende a atenção de uma reunião, e foi com ela que o relatório
de atendimento da Varanda abriu em dezembro de 2025, comparando novembro com o novembro anterior.
Antes de alguém agir, uma pergunta precisa ser feita: **40% mais reclamações em quantas chances de
reclamar?** Uma contagem sem denominador diz quanto existe de alguma coisa, não com que frequência ela
acontece, e as duas podem andar em sentidos opostos.

## Uma tabela, três respostas

O novembro da loja online em cada ano, com os pedidos, os clientes que os fizeram e as reclamações.
Digite numa planilha nova a partir de A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Mês | Pedidos | Clientes | Reclamações |
| 2 | nov 2024 | 5000 | 4000 | 150 |
| 3 | nov 2025 | 8000 | 4400 | 210 |

Primeiro, quanto cada coluna cresceu:

```localised
=ARRED((B3/B2-1)*100;1)      60
=ARRED((C3/C2-1)*100;1)      10
=ARRED((D3/D2-1)*100;1)      40
```

As reclamações subiram 40%, mas os pedidos subiram 60%. **As reclamações por pedido caíram**:

```localised
=ARRED(D2/B2*100;1)      3
=ARRED(D3/B3*100;1)      2,6
```

De 3,0 reclamações por cem pedidos para 2,6. Nessa leitura a operação melhorou: cada pedido teve menos
chance de dar errado. Agora as mesmas reclamações por cliente:

```localised
=ARRED(D2/C2*100;1)      3,8
=ARRED(D3/C3*100;1)      4,8
```

De 3,8 por cem clientes para 4,8. **Nessa leitura as coisas pioraram.** As mesmas três colunas dos
mesmos dois meses dão "reclamações sobem 40%", "taxa de reclamação cai" e "taxa de reclamação sobe", e
as três são aritmética correta.

## Qual denominador, então

As duas taxas discordam porque os clientes fizeram mais pedidos cada um em novembro de 2025: 1,82
contra 1,25 no ano anterior, depois de uma campanha de Black Friday que os trouxe de volta várias
vezes. Mais pedidos por cliente quer dizer mais chances de cada cliente ter um problema.

```localised
=ARRED(B2/C2;2)      1,25
=ARRED(B3/C3;2)      1,82
```

**O denominador certo é o que conta as chances da coisa que você está perguntando.** Se a pergunta é
se o depósito e as transportadoras tratam bem um pedido, cada pedido é uma chance de falhar, e
reclamações por pedido é a medida: ela melhorou. Se a pergunta é quantas pessoas tiveram uma
experiência ruim com a Varanda neste novembro, cada cliente é uma chance, e isso piorou, em parte
porque cada um deu mais chances à loja. As duas entram no relatório, cada uma com o denominador no
nome. O que não entra é a contagem nua, "reclamações sobem 40%", que não responde a nenhuma das duas
perguntas.

## Uma taxa que subiu porque o denominador caiu

A armadilha também corre ao contrário. Num mês de 2025, a equipe da Renata pausou as campanhas pagas,
e a conversão online deu um salto:

| | A | B | C |
|---|---|---|---|
| 1 | | Visitas | Pedidos |
| 2 | Antes | 300000 | 3750 |
| 3 | Depois | 210000 | 3375 |

```localised
=ARRED(C2/B2*100;2)          1,25
=ARRED(C3/B3*100;2)          1,61
=ARRED((C3/C2-1)*100;1)      -10
```

A conversão foi de 1,25% para 1,61%, o melhor mês que a loja já tinha registrado, e os pedidos caíram
10%. As campanhas pagas vinham trazendo visitantes que raramente compravam; quando pararam, as visitas
caíram 30%, os visitantes que sobraram eram os interessados, e a taxa subiu. **Uma taxa pode melhorar
porque o denominador perdeu os piores casos**, o que é boa notícia sobre a taxa e não sobre o negócio.
A árvore da aula 10 é a conferência: um ramo só é boa notícia se os outros ficaram parados.

## O hábito

Sempre que um relatório mostrar uma mudança, peça o denominador e olhe para ele também. Três perguntas
cobrem a maioria dos casos: **em quantos?** (uma contagem precisa da sua base); **a base mudou?** (uma
taxa pode se mexer porque a parte de baixo se mexeu); **a base é o conjunto certo de chances?**
(pedidos ou clientes, visitas ou visitantes). Os números raramente estão errados. O que falta é a
linha embaixo deles.
