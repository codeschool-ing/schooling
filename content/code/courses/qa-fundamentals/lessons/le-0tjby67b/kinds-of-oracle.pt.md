---
title: Tipos de oráculo
version: 1
---

**Os oráculos vêm em alguns tipos, e cada um é forte num lugar e cego em outro.** Quem testa e conhece os tipos em
geral acha um, mesmo onde ninguém escreveu um resultado esperado.

| tipo | contra o que compara | Cine Aurora | cego para |
|---|---|---|---|
| **especificado** | um resultado esperado escrito: uma regra, um exemplo, um critério | as cinco frases, o esboço combinado | o que a especificação deixou de fora, ou errou |
| **de referência** | outra implementação da mesma coisa | a tabela de preços impressa na bilheteria; a versão do programa do mês passado | defeitos que a referência compartilha |
| **implícito** | coisas que estão erradas em qualquer programa | o traceback com `sixty` na aula 6 | tudo o que roda sem reclamar |
| **de consistência** | o produto contra ele mesmo e o mundo dele | uma sessão mais cedo que custa mais que uma mais tarde | um defeito que é consistente em todo lugar |
| **humano** | uma pessoa que conhece o domínio | a Célia, que sabe quanto uma família paga às 9:30 de domingo | o que essa pessoa nunca viu |

## Oráculos implícitos são de graça

Alguns resultados estão errados seja o que for que a especificação diga: uma queda, um traceback, uma página de erro,
um preço negativo, um total que não soma as linhas, uma tela que nunca termina de carregar. Esses não precisam de
resultado esperado, e é por isso que toda sessão exploratória fica de olho neles. A queda com `sixty` da aula 6 foi
achada por um oráculo implícito: ninguém tinha escrito o que deveria acontecer quando a idade é uma palavra, mas
ninguém precisava.

## Heurísticas de consistência

Quando nenhuma especificação responde a pergunta, quem testa ainda pode perguntar se o produto é consistente com
coisas com que deveria concordar. Michael Bolton, partindo do trabalho de James Bach, reuniu isso numa lista de
heurísticas conhecida como **FEW HICCUPPS**. Uma seleção, com a pergunta que cada uma levanta no Cine Aurora:

| o produto deveria ser consistente com | a pergunta |
|---|---|
| **sua história** | um ingresso custava R$ 28,00 nesta matinê semana passada? |
| **produtos comparáveis** | quanto o cinema do outro lado da rua cobra de um estudante numa quarta? |
| **o que se afirma sobre ele** | o cartaz na porta, *quartas pela metade*, bate com o que o programa cobra? |
| **expectativas de quem usa** | uma família esperaria que uma sessão de manhã custasse mais que uma de tarde? |
| **ele mesmo** | o mesmo ingresso custa o mesmo no site e na bilheteria? |
| **seu propósito** | a regra de preço de fato deixa o cinema mais barato para estudantes, como a Joana queria? |
| **leis e normas** | um cliente idoso recebe a meia-entrada que a lei garante? |

Nenhuma delas produz um preço esperado. Cada uma produz um *motivo para suspeitar* de um preço, que é o que um oráculo
precisa fazer. A pergunta que uma heurística levanta vira uma pergunta a uma pessoa, muitas vezes a Joana, e a
resposta vira um exemplo escrito, um oráculo especificado, para a próxima vez.

## Oráculos humanos

O oráculo mais flexível é uma pessoa que conhece o domínio. A Célia soube em segundos que o preço de domingo estava
errado, porque vende ingressos todo dia. Oráculos humanos são lentos, inconsistentes e indisponíveis às três da manhã,
então não escalam. São também o único oráculo para perguntas que nenhum documento responde ainda, e é por isso que o
System Demo da aula 14 e a revisão da aula 12 põem o produto na frente de pessoas.
