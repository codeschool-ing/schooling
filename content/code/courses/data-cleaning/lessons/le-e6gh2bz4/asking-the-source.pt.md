---
title: Perguntar à origem, e escrever a resposta
version: 1
---

**O dado consegue descartar alguns mecanismos; só a origem consegue confirmar um.** Essa assimetria
é a lição prática desta aula inteira. Comparar linhas com e sem valor pode mostrar que os vazios não
são completamente aleatórios — Roderick Little publicou um teste formal para exatamente isso em 1988
— e pode mostrar com que colunas visíveis eles se alinham. Não pode mostrar que nada invisível está
por trás deles, porque a coisa invisível, por definição, não está no arquivo.

Então toda coluna com vazios recebe as mesmas cinco perguntas, nesta ordem:

1. **Um valor poderia existir aqui?** Se não, o vazio é uma resposta: não se aplica.
2. **O que o sistema que o escreveu quer dizer com um vazio?** Zero, desconhecido, recusado, não
   perguntado, tempo esgotado. Quem fez o formulário sabe; o arquivo não.
3. **Os vazios se alinham com uma coluna que você vê?** Separe-os, como o `pattern.py` fez. Tudo ou
   nada num grupo é uma explicação.
4. **Há sinal de que o próprio valor está envolvido?** Um máximo que para num número redondo, uma
   cauda cortada reta, um grupo que deveria ser mais lento respondendo menos.
5. **Quem confirmou, e quando?** Um mecanismo que ninguém confirmou é uma hipótese, e deve ser
   escrito como uma.

## O registro de ausências

As respostas vão para uma tabela que viaja com o dado, porque a aula 4 decide o que fazer com cada
coluna a partir dela, e quem ler o dado limpo no ano que vem precisa saber por que uma coluna foi
preenchida de um jeito e não de outro:

| coluna | o vazio quer dizer | mecanismo | evidência | confirmado por |
|---|---|---|---|---|
| `delivery_minutes`, retiradas | não houve entrega | não se aplica | 100% vazio onde `fulfilment` é `pickup` | o dado |
| `delivery_minutes`, Rapidex | a parceira não informa tempos | MAR em `courier` | 100% vazio na Rapidex | operações |
| `delivery_minutes`, frota própria | levou 120 minutos ou mais | MNAR | máximo 119; taxa 4× à noite | operações: o cronômetro para em 2 h |
| `discount`, site | sem cupom: zero | não falta | vazio só no site, `0` só no aplicativo | o dado |
| `nps` | o cliente não respondeu | MNAR, em parte visível | a resposta cai com o tempo de entrega | não confirmável; conhecido na área |
| `email`, lojas | o cliente recusou ou não foi perguntado | MAR em `signup_channel` | 45% vazio nas lojas, 0% no resto | gerência das lojas |
| `birth_year` de 1900 | marcador do formulário | não é valor | 344 dos 348 vêm das lojas | gerência das lojas |
| `cliente`, vendas das lojas | venda sem número de fidelidade | não é defeito | tíquete médio de R$ 65,58 contra R$ 65,68 | o dado |

**A coluna `confirmado por` é a que faz a tabela valer a pena.** "O dado" quer dizer que o padrão é
exato e não precisa da palavra de ninguém. Um nome quer dizer que alguém que conhece o sistema
afirmou, e pode ser perguntado de novo quando o sistema mudar. E "não confirmável" é um registro
honesto: diz ao leitor que o número construído sobre esta coluna carrega um viés de tamanho
desconhecido, o que é mais do que a maioria dos relatórios diz sobre si mesma.

## O que esta aula não fez

Ela não preencheu, descartou nem imputou um único valor. De propósito. Cada opção da aula 4 —
descartar linhas, preencher com uma constante, imputar a partir de linhas parecidas, sinalizar — é
certa para um mecanismo e errada para outro, e escolher uma antes de ler os vazios é como a frota
acaba informada como mais rápida do que é.
