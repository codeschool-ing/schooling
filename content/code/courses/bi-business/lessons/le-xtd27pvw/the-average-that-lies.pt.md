---
title: A média que não descreve ninguém
version: 1
---

Na segunda-feira, 16 de março de 2026, o relatório semanal da Renata mostrou o tíquete médio das novas
páginas de móveis de jardim da loja online em **R$ 2.607**, contra R$ 350 da loja online inteira em
2025. As páginas tinham entrado no ar na semana anterior, e a primeira leitura na reunião foi que
tinham funcionado de forma espetacular. Ninguém tinha errado uma conta. **O número estava certo, e não
descrevia nenhum dos clientes da semana.**

Esta aula é sobre números como esse: calculados corretamente a partir de dados corretos, e ainda
assim apontando a reunião para a conclusão errada. A aula 1 chamou isso de "não é a verdade por
padrão"; aqui estão as cinco formas que isso mais toma, começando pela média.

## Doze pedidos

As páginas receberam doze pedidos na primeira semana, em reais. Digite numa planilha nova a partir de
A1:

| | A | B |
|---|---|---|
| 1 | Pedido | Valor |
| 2 | 1 | 189 |
| 3 | 2 | 245 |
| 4 | 3 | 312 |
| 5 | 4 | 278 |
| 6 | 5 | 420 |
| 7 | 6 | 156 |
| 8 | 7 | 365 |
| 9 | 8 | 298 |
| 10 | 9 | 540 |
| 11 | 10 | 233 |
| 12 | 11 | 18400 |
| 13 | 12 | 9850 |

Os pedidos 11 e 12 vieram de um escritório de arquitetura mobiliando um hotel em Belo Horizonte:
sessenta cadeiras de jardim num, as espreguiçadeiras da piscina no outro. Agora a média, que é o que
"tíquete médio" quer dizer no relatório da Renata, e a mediana:

```localised
=ARRED(MÉDIA(B2:B13);0)      2607
=MED(B2:B13)                 305
```

A **média** soma os valores e divide pela quantidade: R$ 31.286 em doze pedidos. A **mediana** ordena
os valores e pega o do meio; com doze, fica no meio do caminho entre o sexto e o sétimo. **Dois pedidos
em doze carregam 90,3% do dinheiro**, então eles arrastam a média para um valor onde não há pedido
nenhum, enquanto a mediana fica entre os clientes:

```localised
=ARRED((B12+B13)/SOMA(B2:B13)*100;1)      90,3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Doze pedidos como pontos numa linha de 0 a 20.000 reais. Dez ficam amontoados na ponta esquerda, todos abaixo de 600 reais. Dois ficam longe, à direita, em 9.850 e 18.400. A mediana, 305 reais, está marcada dentro do amontoado; a média, 2.607 reais, está marcada no espaço vazio entre o amontoado e os dois pedidos grandes, onde não há pedido nenhum.\" data-fig=\"l12-orders\"><path d=\"M40.0 96.0 L680.0 96.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M40.0 96.0 L40.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"40.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M200.0 96.0 L200.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"200.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5.000</text><path d=\"M360.0 96.0 L360.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"360.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">10.000</text><path d=\"M520.0 96.0 L520.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"520.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">15.000</text><path d=\"M680.0 96.0 L680.0 102.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"680.0\" y=\"118.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">20.000</text><text x=\"680.0\" y=\"138.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reais por pedido</text><path d=\"M42.0 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M43.8 79.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M46.0 72.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M44.9 65.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M49.4 58.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M41.0 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M47.7 79.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M45.5 72.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M53.3 65.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M43.5 58.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M624.8 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M351.2 86.0 a4 4 0 1 0 8 0 a4 4 0 1 0 -8 0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M123.4 30.0 L123.4 96.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"131.4\" y=\"34.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">média R$ 2.607</text><text x=\"131.4\" y=\"50.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nenhum pedido perto dela</text><path d=\"M49.8 152.0 L49.8 126.0\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"45.8\" y=\"172.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">mediana R$ 305</text><text x=\"45.8\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">metade dos pedidos abaixo, metade acima</text><text x=\"492.0\" y=\"74.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os dois pedidos do hotel</text></svg>", "caption": "Os doze pedidos da semana. Dez deles, todos os clientes comuns, cabem no primeiro pedaço do eixo. A média fica onde ninguém comprou nada."}
```

## Nenhum dos dois está errado

A conclusão tentadora é "a mediana está certa e a média mente". Não é tão simples. **A média responde
a uma pergunta sobre dinheiro: a receita total dividida pelos pedidos.** Se o Otávio quer saber quanto
mil pedidos a mais como os desta semana trariam, a média é o número a usar, e a mediana subestimaria
muito. **A mediana responde a uma pergunta sobre pessoas: quanto um cliente típico gasta.** Se a
Renata quer saber se as novas páginas mudaram o jeito de comprar dos clientes comuns, é para a mediana
que ela deve olhar, e ela diz R$ 305: abaixo do tíquete habitual da loja, e não sete vezes acima dele.

A falha não está em nenhuma das fórmulas. Está num relatório que escreve "tíquete médio" e deixa o
leitor supor que ele descreve um cliente típico. Três hábitos evitam isso:

- **Ponha a mediana ao lado da média** sempre que alguns valores muito grandes forem possíveis.
  Quando as duas ficam longe, essa distância é o achado.
- **Olhe os maiores valores antes de informar a média.** Duas linhas em doze ficaram óbvias no momento
  em que alguém ordenou a coluna.
- **Informe à parte um tipo diferente de cliente.** O hotel era uma empresa comprando para um projeto,
  não uma casa. Tire os pedidos 11 e 12 e os pedidos das famílias ficam assim:

```localised
=ARRED(MÉDIA(B2:B11);0)      304
```

R$ 304 para as famílias, e os pedidos de empresa informados numa linha própria. São dois números onde
o relatório tinha um, e os dois são verdadeiros.

Por que alguns tipos de dado puxam a média para longe do meio, e como descrever a dispersão em torno
dela, são assunto das aulas 3, 4 e 9 de `statistics`. O que este curso pede é mais estreito e vem
antes: antes de uma média chegar a uma reunião, alguém olha as linhas que estão atrás dela.
