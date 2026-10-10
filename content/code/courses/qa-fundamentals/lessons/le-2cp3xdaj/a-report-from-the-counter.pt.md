---
title: Um relato do balcão
version: 1
---

**Numa segunda-feira, a Célia trouxe para a Lia uma reclamação que tinha ouvido no domingo.** Uma família
de quatro pessoas, dois adultos e duas crianças, tinha comprado ingressos pelo site para a nova sessão das
9:30, a primeira sessão matinal da história do cinema, criada para um filme infantil. No balcão eles teriam
pago R$ 84,00. O site cobrou R$ 108,00. Eles queriam a diferença de volta, e a Célia queria saber se ia
acontecer de novo no domingo seguinte.

Esse é um relato de defeito típico vindo de fora do time: **verdadeiro, importante, e quase inútil para
achar a causa.** Diz que algo deu errado. Não diz o quê.

## Primeiro, a evidência que já existe

Antes de rodar qualquer coisa, a Lia anotou o que se sabia, separando o observado do deduzido:

- **observado:** quatro ingressos, domingo, sessão das 9:30, dois adultos, duas crianças de 8 e 10 anos,
  R$ 108,00 cobrados;
- **observado:** o preço do balcão seria R$ 84,00. Dois adultos no preço da matinê, R$ 28,00, duas
  crianças pela metade disso;
- **deduzido, ainda não conferido:** o site e o balcão usam as mesmas regras.

A conta vale a pena, porque também é evidência. R$ 108,00 é exatamente duas vezes R$ 36,00 mais duas vezes
R$ 18,00: **o preço da noite, com o desconto das crianças aplicado.** Essa única subtração já descarta
coisas. As crianças foram reconhecidas como crianças. O que falhou foi a sessão.

## Depois, as hipóteses

Com a evidência no papel, a Lia listou toda explicação em que conseguiu pensar que batesse com ela, antes
de testar qualquer uma:

1. a loja trata o **domingo** de um jeito diferente dos outros dias;
2. a loja trata qualquer sessão **antes de certa hora** como sessão da noite, porque ninguém esperava uma
   de manhã;
3. o **horário** chegou à regra de preço escrito de um jeito que ela não entende;
4. a família escolheu a sessão das 19:00 por engano e o site estava certo.

Listá-las primeiro importa. Quem testa a primeira ideia que vem à cabeça e a acha plausível para ali, e
isso é o viés de confirmação de novo, pelo outro lado. Quatro hipóteses, cada uma capaz de estar errada,
podem ser postas umas contra as outras por experimentos.

A quarta é a mais barata de conferir e nem precisa do programa: o registro do pedido dizia 9:30. A família
tinha razão. Sobraram três.

## O que faz uma hipótese merecer ser testada primeiro

Nem todas as três custam o mesmo para decidir, e não são igualmente prováveis. Uma ordem útil é: **aquela
cujo experimento é mais barato e cujo resultado descarta mais.** Uma execução do preço de um adulto numa
sessão de domingo à tarde decide a primeira, e algumas execuções em horários diferentes da manhã separam a
segunda da terceira. A próxima seção as roda.

Repare no que a Lia ainda não fez. Não abriu o `tickets.py`, não chutou uma linha de código e não disse
nada ao Rafael além de que há um relato que ela está investigando. **Ela está construindo evidência que vai
resistir a ser mostrada a quem escreveu o código**, que é o único tipo de evidência que faz um defeito ser
corrigido em vez de discutido.
