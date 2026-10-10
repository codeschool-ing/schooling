---
title: Do objetivo ao indicador
version: 1
---

O jeito comum de montar uma página de indicadores é listar o que os sistemas produzem e escolher os
que parecem importantes. Isso parte dos dados, que a aula 1 apontou como um dos dois jeitos de
quebrar o ciclo de BI, e termina numa página de números fáceis de obter. **O método que funciona
corre ao contrário: o objetivo, depois as perguntas que o objetivo levanta, depois o indicador que
responde a cada pergunta.** Na engenharia de software ele é conhecido como goal-question-metric
(objetivo, pergunta, métrica), de um método para medir projetos de software; o nome não importa, a
ordem sim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma árvore lida da esquerda para a direita. Um objetivo, cumprir a data que damos ao cliente, leva a três perguntas: estamos atrasando, e onde; avariamos o que entregamos; o produto está lá para enviar. Cada pergunta leva ao indicador que a responde: entregue no prazo por rota, entregas com avaria e rupturas entre os 200 produtos principais.\" data-fig=\"l11-gqm\"><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">objetivo</text><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">perguntas</text><text x=\"605.0\" y=\"30.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">indicadores</text><rect x=\"20.0\" y=\"125.0\" width=\"180.0\" height=\"80.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"158.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">cumprir a data que</text><text x=\"110.0\" y=\"178.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">damos ao cliente</text><rect x=\"255.0\" y=\"50.0\" width=\"210.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"85.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">estamos atrasando, e onde?</text><rect x=\"510.0\" y=\"50.0\" width=\"190.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"77.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">entregue no prazo</text><text x=\"605.0\" y=\"96.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por rota, semanal</text><path d=\"M202.0 165.0 L253.0 80.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M253.0 80.0 L252.2 89.0 L245.5 84.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M467.0 80.0 L508.0 80.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 80.0 L499.9 83.9 L499.9 76.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"255.0\" y=\"145.0\" width=\"210.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">avariamos o que entregamos?</text><rect x=\"510.0\" y=\"145.0\" width=\"190.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"172.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">entregas com avaria</text><text x=\"605.0\" y=\"191.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">porcentagem, semanal</text><path d=\"M202.0 165.0 L253.0 175.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M253.0 175.0 L244.3 177.3 L245.8 169.6 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M467.0 175.0 L508.0 175.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 175.0 L499.9 178.9 L499.9 171.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"255.0\" y=\"240.0\" width=\"210.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"275.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o produto está lá para enviar?</text><rect x=\"510.0\" y=\"240.0\" width=\"190.0\" height=\"60.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"267.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">rupturas, top 200</text><text x=\"605.0\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dias em falta, semanal</text><path d=\"M202.0 165.0 L253.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M253.0 270.0 L245.9 264.4 L253.0 261.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M467.0 270.0 L508.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 270.0 L499.9 273.9 L499.9 266.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"360.0\" y=\"322.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um indicador sem pergunta acima dele não tem motivo para estar na página</text></svg>", "caption": "Objetivo, perguntas, indicadores, para o objetivo de entregas do Caio. Lida da esquerda, ela escolhe os indicadores; lida da direita, é o motivo escrito de cada um estar ali."}
```

O objetivo do Caio, da aula 10, é cumprir a data que a Varanda dá ao cliente. Ele levanta três
perguntas que o Caio vai fazer toda semana: estamos atrasando, e onde? Avariamos o que entregamos? O
produto está no depósito para ser enviado? Cada pergunta escolhe o seu indicador, e cada indicador
tem acima dele uma frase dizendo por que está ali. **Um indicador sem pergunta acima dele não tem
motivo para estar na página**, por mais fácil que seja calculá-lo.

## Dando nota aos candidatos

Na prática, a lista de candidatos é maior que a de perguntas, porque cada diretor chega com alguns.
A Lívia juntou dez para a página do Caio e deu a cada um uma nota de 1 a 5 em quatro critérios:

- *relevante*: quão diretamente ele responde a uma das perguntas do objetivo;
- *acionável*: se a equipe do Caio consegue mudá-lo em semanas;
- *dados*: se os registros existem e são confiáveis;
- *barato*: quão pouco trabalho dá produzi-lo toda semana (5 é o mais barato).

Relevância e ação importam mais que conveniência, então pesam 3, e os outros dois pesam 2. Digite a
tabela numa planilha nova a partir de A1; a linha 2 tem os pesos:

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Indicador | Relevante | Acionável | Dados | Barato |
| 2 | Peso | 3 | 3 | 2 | 2 |
| 3 | Entregue no prazo | 5 | 5 | 4 | 4 |
| 4 | Entregas com avaria | 4 | 5 | 4 | 4 |
| 5 | Rupturas, top 200 | 5 | 4 | 3 | 3 |
| 6 | Dias de estoque | 4 | 3 | 5 | 5 |
| 7 | Erros de separação | 4 | 5 | 3 | 3 |
| 8 | Custo de entrega por pedido | 4 | 4 | 4 | 3 |
| 9 | Paletes recebidos por dia | 2 | 2 | 5 | 5 |
| 10 | Produtos no catálogo | 2 | 1 | 5 | 5 |
| 11 | Uso das empilhadeiras | 2 | 3 | 2 | 2 |
| 12 | Energia por m² nas lojas | 2 | 3 | 2 | 3 |

Em F1 digite `Nota`, e em F3 a soma ponderada da linha:

```localised
=SOMARPRODUTO(B$2:E$2;B3:E3)      46
```

`SOMARPRODUTO` multiplica os dois intervalos célula a célula e soma os produtos: aqui 3×5 + 3×5 +
2×4 + 2×4, que dá 46. Copie F3 até F12. O `$` faz toda linha multiplicar pelos pesos da linha 2. A nota máxima
possível é 50.

Sua coluna deve mostrar 46, 43, 39, 41, 39, 38, 32, 29, 23 e 25. **Os cinco primeiros são entregue
no prazo (46), entregas com avaria (43), dias de estoque (41), e rupturas e erros de separação (39
cada).** O custo de entrega por pedido fica de fora por um ponto, com 38.

## Para que serve a nota

**A planilha não escolhe; ela torna o argumento visível.** Cada número das colunas B a E é o
julgamento de alguém, e um ponto de diferença entre o quinto e o sexto está bem dentro do quanto os
julgamentos de duas pessoas variam. O que a tabela dá ao Caio é um lugar para discordar de uma célula
em vez da página inteira: "erros de separação é 3 em dados, não 4" é uma conversa que termina; "acho
que ele devia estar lá" é uma que não termina.

Duas conferências valem antes de confiar no corte. A primeira é se os pesos decidem tudo. Mude o peso
de dados em D2 de 2 para 1 e as notas mudam, mas os mesmos cinco ficam no topo, três deles agora
empatados em 36; um corte que resiste a uma mudança de pesos é mais firme que um que não resiste. A
segunda é olhar o fim da lista: **paletes recebidos e produtos no catálogo tiram 5 em dados e em
custo, e essas duas colunas são tudo o que eles têm.** Uma planilha de notas sem o peso da relevância
teria promovido exatamente os números fáceis de obter.

O Caio pôs o custo de entrega por pedido na lista de candidatos a rever em três meses, com o motivo
escrito ao lado, que é o assunto da última seção desta aula.
