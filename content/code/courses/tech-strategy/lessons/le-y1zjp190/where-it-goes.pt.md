---
title: Para onde vai o dinheiro
version: 1
---

Pergunte a um engenheiro quanto custa a engenharia e a resposta costuma ser a fatura da nuvem. É a
única fatura com o nome do departamento, chega todo mês e traz um número grande o bastante para
preocupar. **Também é uma parte pequena do dinheiro.** O maior custo de uma organização de
engenharia nunca chega como fatura, e por isso quem está mais perto dele raramente o enxerga como
custo.

Esta seção põe o ano da Coreto numa planilha só, para que o resto da aula argumente a partir do
orçamento inteiro, e não da linha que por acaso está à vista.

## Quatro linhas

Otávio Lins, o CFO da Coreto, mantém o orçamento de engenharia em quatro linhas. Todo valor abaixo
é de um ano.

| linha | o que entra nela | valor | parcela |
|---|---|---|---|
| Pessoas | 52 engenheiros ao custo carregado da aula 1 | R$ 13.728.000 | 79,0% |
| Nuvem | a fatura do provedor, R$ 212.000 por mês | R$ 2.544.000 | 14,6% |
| Licenças e SaaS | assinaturas pagas por usuário ou por uso, R$ 61.000 por mês | R$ 732.000 | 4,2% |
| Ferramental | o que se compra de uma vez: máquinas de build, os aparelhos de teste de que o Mobile precisa, as compras avulsas do ano | R$ 380.000 | 2,2% |
| **total** | | **R$ 17.384.000** | |

A linha de pessoas é uma conta que você já tem. Uma hora de engenharia custa R$ 150 carregada, um
ano de engenheiro tem 1.760 horas de trabalho, então um engenheiro custa **R$ 264.000 por ano**, e
52 deles custam R$ 13.728.000.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l11-budget\" aria-label=\"Uma barra horizontal para o orçamento de engenharia da Coreto, de R$ 17.384.000 por ano. Pessoas ocupam 79,0% dela, desenhadas como 52 blocos, um por engenheiro a R$ 264.000 cada. Nuvem ocupa 14,6%, licenças e SaaS 4,2% e ferramental 2,2%, as duas últimas fatias finas na ponta direita.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Orçamento de engenharia da Coreto em um ano: R$ 17.384.000</text><rect x=\"20.0\" y=\"74.0\" width=\"537.2\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><path d=\"M30.3 75 L30.3 123 M40.7 75 L40.7 123 M51.0 75 L51.0 123 M61.3 75 L61.3 123 M71.7 75 L71.7 123 M82.0 75 L82.0 123 M92.3 75 L92.3 123 M102.6 75 L102.6 123 M113.0 75 L113.0 123 M123.3 75 L123.3 123 M133.6 75 L133.6 123 M144.0 75 L144.0 123 M154.3 75 L154.3 123 M164.6 75 L164.6 123 M175.0 75 L175.0 123 M185.3 75 L185.3 123 M195.6 75 L195.6 123 M206.0 75 L206.0 123 M216.3 75 L216.3 123 M226.6 75 L226.6 123 M236.9 75 L236.9 123 M247.3 75 L247.3 123 M257.6 75 L257.6 123 M267.9 75 L267.9 123 M278.3 75 L278.3 123 M288.6 75 L288.6 123 M298.9 75 L298.9 123 M309.3 75 L309.3 123 M319.6 75 L319.6 123 M329.9 75 L329.9 123 M340.3 75 L340.3 123 M350.6 75 L350.6 123 M360.9 75 L360.9 123 M371.2 75 L371.2 123 M381.6 75 L381.6 123 M391.9 75 L391.9 123 M402.2 75 L402.2 123 M412.6 75 L412.6 123 M422.9 75 L422.9 123 M433.2 75 L433.2 123 M443.6 75 L443.6 123 M453.9 75 L453.9 123 M464.2 75 L464.2 123 M474.6 75 L474.6 123 M484.9 75 L484.9 123 M495.2 75 L495.2 123 M505.5 75 L505.5 123 M515.9 75 L515.9 123 M526.2 75 L526.2 123 M536.5 75 L536.5 123 M546.9 75 L546.9 123\" fill=\"none\" stroke=\"var(--ink)\" stroke-width=\"1\"></path><rect x=\"557.2\" y=\"74.0\" width=\"99.3\" height=\"50.0\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"656.5\" y=\"74.0\" width=\"28.6\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"685.0\" y=\"74.0\" width=\"15.0\" height=\"50.0\" rx=\"2\" fill=\"var(--paper-dim)\"></rect><text x=\"20.0\" y=\"46.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Pessoas · 79,0%</text><text x=\"20.0\" y=\"63.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">52 engenheiros × R$ 264.000 = R$ 13.728.000</text><text x=\"559.2\" y=\"46.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Nuvem · 14,6%</text><text x=\"559.2\" y=\"63.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 2.544.000</text><path d=\"M670.8 124 L670.8 146 L600 146\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M692.5 124 L692.5 170 L600 170\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"594.0\" y=\"150.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Licenças e SaaS · 4,2% · R$ 732.000</text><text x=\"594.0\" y=\"174.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ferramental · 2,2% · R$ 380.000</text><text x=\"20.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cada bloco é um engenheiro</text></svg>", "caption": "As quatro linhas do orçamento nas proporções verdadeiras. A fatura que os engenheiros mais veem, a da nuvem, é a segunda linha; a primeira nunca chega como fatura."}
```

## A planilha

Acrescente uma aba à sua planilha, preparada como na aula 1, e digite as quatro linhas:

| | A | B | C |
|---|---|---|---|
| 1 | Linha | Valor | Parcela |
| 2 | Pessoas | 13728000 | |
| 3 | Nuvem | 2544000 | |
| 4 | Licenças e SaaS | 732000 | |
| 5 | Ferramental | 380000 | |

O total, numa célula vazia:

```localised
=SOMA(B2:B5)      17384000
```

E a parcela de cada linha nele, em C2:

```localised
=ARRED(B2/SOMA($B$2:$B$5)*100;1)      79
```

Os cifrões fixam o intervalo, e assim a fórmula pode ser copiada para baixo: C3, C4 e C5 passam a
mostrar 14,6, 4,2 e 2,2. **Sem eles o intervalo desliza uma linha a cada cópia**, e C5 dividiria o
ferramental por uma soma de três células, duas delas vazias. C2 mostra 79 e não 79,0 porque a
célula descarta o zero final; formate a coluna com uma casa decimal e ela fica igual à tabela.

## O que as parcelas dizem

**Quatro quintos do orçamento são tempo de gente.** Qualquer conversa sobre dinheiro de engenharia
é, no fundo, uma conversa sobre como 52 pessoas gastam suas horas. Dois engenheiros durante um
trimestre são meio ano de engenheiro, R$ 132.000 de tempo. Uma economia na nuvem que levou esse tempo
para sair precisa economizar mais do que isso antes de se pagar, e ninguém confere isso se
as horas não forem precificadas do mesmo jeito que a fatura.

**As linhas não são independentes.** Uma licença muitas vezes substitui tempo de gente: a aula 9
mostrou que a operação era 76% do custo total da observabilidade hospedada por conta própria, e
quase tudo isso era hora de engenheiro. Cancele a assinatura e o dinheiro passa da linha de
licenças para a de pessoas, onde ninguém o registra como custo da decisão. A nuvem faz o mesmo no
sentido contrário: uma arquitetura mais barata que precisa de alguém de olho nela é mais barata numa
linha só.

**E as linhas se movem em velocidades diferentes.** A fatura da nuvem muda todo mês, com o tráfego;
a aula 12 é sobre como lê-la. As licenças acompanham o número de pessoas, porque a maioria é cobrada
por usuário. Pessoas mudam em degraus de R$ 264.000, e devagar: uma vaga leva meses para ser
preenchida, e um engenheiro que sai leva junto o que sabe. O ferramental vem aos solavancos, uma
compra grande num ano e quase nada no seguinte.

| linha | o que a move | com que rapidez pode mudar |
|---|---|---|
| Pessoas | contratações, saídas, realocação | meses, em degraus de R$ 264.000 |
| Nuvem | tráfego, arquitetura, desperdício | semanas |
| Licenças e SaaS | número de pessoas, renovação de contratos | na renovação, em geral anual |
| Ferramental | compras avulsas | quando alguém compra alguma coisa |

Essa última coluna decide o que um líder consegue de fato mudar num trimestre, e é a primeira coisa
a conferir quando alguém pede dinheiro de volta. A próxima seção é esse pedido.
