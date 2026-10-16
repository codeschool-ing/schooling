---
title: Três jeitos de o mundo se mexer
version: 1
---

As aulas 3 e 4 disseram que um modelo é testado em meses posteriores porque o mundo muda. Esta aula já o
viu mudar de três jeitos distintos, e eles têm nome, porque cada um é percebido de um jeito e respondido
de outro.

| | o que muda | aqui | visto por | quando |
|---|---|---|---|---|
| **deriva de dados** | as entradas: quem são os assinantes | o plano mensal; preços mais altos | `inputs.py` | no dia |
| **deriva de conceito** | o que as entradas querem dizer: a chance de o mesmo assinante sair | o concorrente em duas cidades | `where.py` | um mês depois, se o erro for dividido |
| **mudança de rótulo** | quão comum é o resultado no geral | o fim do efeito posterior do aumento de preço | `labels.py` | um mês depois |

Duas das três não podem ser vistas até as respostas chegarem, e esse é o centro desconfortável desta
aula. **Um modelo em produção é sempre julgado pelo mês passado**, e a mudança que mais estraga, aquela em
que o mundo reage de outro jeito aos mesmos fatos, é invisível no dia. O que o dia pode oferecer é um
substituto para a resposta: a **chance média**, comparada com a taxa real recente. Se o modelo diz 6,5%
num mês depois de três meses de 5%, isso não prova nada, mas é o sinal mais cedo que existe.

Mais dois pontos que os nomes escondem.

**Deriva nem sempre é problema.** `price_month` derivou muito e a ordenação sobreviveu: o modelo tinha
aprendido o efeito do preço, e preços mais altos mexeram as chances na direção que ele tinha aprendido. A
deriva de dados importa quando leva o modelo **a um lugar onde ele não esteve**, o plano mensal, e muito
menos quando ele anda por uma estrada que já conhece.

**A resposta nem sempre é reajustar.** O aumento de preço foi passageiro: um modelo reajustado em
dezembro teria aprendido o pânico de setembro e o levado para um janeiro calmo, que é mais ou menos o que
aconteceu com o `churn-2025-12`. Um concorrente não é passageiro. Distinguir os dois é uma pergunta sobre
o negócio, e as pessoas que podem respondê-la em geral não estão olhando o modelo.
