---
title: Exatidão e validade: certo, e bem formado
version: 1
---

**A exatidão pergunta se um valor corresponde ao mundo. A validade pergunta só se ele é o tipo de
valor que a coluna admite.** As duas se confundem fácil porque a segunda é muito mais fácil de
checar, e uma checagem fácil tende a ser tomada pela que importa.

Um ano de nascimento `1987` é válido: quatro dígitos, dentro de uma faixa plausível. É exato só se
o cliente nasceu em 1987, e nada no arquivo diz isso. Um ano `87` é **inválido** — a coluna
deveria guardar anos e isto não é um — mas pode muito bem ser exato, já que quem digitou quase
certamente quis dizer 1987.

Ana pergunta à coluna o que ela guarda com mais frequência:

```
ana@lab:~/clean$ psql -c "SELECT birth_year, count(*) FROM raw.customers GROUP BY birth_year ORDER BY count(*) DESC LIMIT 4"
 birth_year | count 
------------+-------
 1900       |   348
            |   338
 1975       |    41
 2005       |    38
(4 rows)
```

O ano de nascimento mais comum entre os clientes da Quitanda Verde é 1900. É válido, bem formado,
dentro de qualquer faixa que uma regra fixaria para um ano — e falso para todos os 348. Ninguém
vivo nasceu em 1900. É **um marcador**: um formulário que não salvava sem um ano, e uma equipe que
digitou o primeiro que funcionou.

Separar por onde o cliente se cadastrou mostra onde nasce cada defeito:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, count(*) FILTER (WHERE birth_year = '1900') AS year_1900, count(*) FILTER (WHERE length(birth_year) = 2) AS two_digits FROM raw.customers GROUP BY signup_channel ORDER BY signup_channel"
 signup_channel | year_1900 | two_digits 
----------------+-----------+------------
 app            |         0 |        103
 import-2023    |         4 |          3
 site           |         0 |          0
 store          |       344 |          0
(4 rows)
```

Todo ano de dois dígitos veio do aplicativo, e quase todo 1900 veio das lojas. **Um defeito quase
sempre tem uma origem**, e achar a origem transforma uma regra de limpeza numa pergunta que alguém
sabe responder: o formulário das lojas exige um ano que não deveria exigir, e o aplicativo guarda o
que a pessoa digitou sem completar os quatro dígitos.

O que um marcador faz com um resumo é fácil de medir. A idade média dos clientes cujo ano tem quatro
dígitos, com e sem ele:

```
ana@lab:~/clean$ psql -c "SELECT round(avg(2025 - birth_year::int), 1) AS with_1900, round(avg(2025 - birth_year::int) FILTER (WHERE birth_year <> '1900'), 1) AS without_1900 FROM raw.customers WHERE length(birth_year) = 4"
 with_1900 | without_1900 
-----------+--------------
      59.3 |         45.2
(1 row)
```

Catorze anos mais velhos em média, por um valor digitado para passar de um formulário. **Nada
falhou**: a conversão funcionou, a média é um número, e um relatório construído sobre ela teria dito
ao marketing que os seus clientes estão beirando os sessenta.

## Por que a diferença importa

| | inválido | válido e inexato |
|---|---|---|
| exemplo | `87` | `1900` |
| uma regra encontra? | sim: o formato está errado | só se a regra conhecer o marcador |
| o que a correção exige | uma decisão sobre o que se quis dizer | informação de fora do arquivo |
| o que acontece se ignorado | uma conversão falha, ou lê como ano 87 | uma média que parece certa e não está |

Valores inválidos se anunciam, ao menos para quem converte a coluna; a aula 10 é sobre converter
com segurança. **Valores válidos e inexatos não dizem nada**, e as únicas defesas são conhecer o
domínio — ninguém aqui nasceu em 1900 — e comparar com uma segunda fonte. Para um ano de nascimento,
a segunda fonte é o próprio cliente, e é por isso que a exatidão é a dimensão mais cara de medir e a
mais deixada de lado.

Uma consequência prática: uma regra de exatidão é sempre uma afirmação sobre o mundo escrita na
língua do dado. "Um ano de nascimento não é 1900" é uma regra sobre o formulário desta empresa, não
uma lei da natureza, e o quadro de regras no fim desta aula a escreve exatamente assim.
