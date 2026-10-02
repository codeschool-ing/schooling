---
title: O que um papel não consegue fazer
version: 1
---

A crença comum por trás de "Você é um especialista de nível mundial" é que a linha melhora as
respostas na substância: mais exatas, mais sabidas, com mais autoridade. **Um papel não acrescenta
conhecimento nem autoridade.** O modelo sabe o que sabia antes da linha, e nada do que ele diz fica
mais verdadeiro por causa do título que recebeu.

## O especialista que não conhece a sua cozinha

Um cliente pergunta ao assistente do café se o pão de canela é seguro para alguém com alergia a
nozes. O curso escreveu este prompt como ilustração de um papel usado para o trabalho errado:

```localised
Você é um especialista em alergias alimentares de nível mundial, com
vinte anos de experiência. Responda com autoridade.

Cliente: O pão de canela de vocês é livre de nozes?
```

O modelo nunca viu a cozinha do Café Aurora. O que um papel assim muda é o **tom** do que ele
escrever a seguir: confiante, específico, tranquilizador. Se a continuação provável for "O nosso
pão de canela não contém nozes", o papel faz essa frase soar como o veredito de um especialista. O
manual do café diz outra coisa: a cozinha usa nozes, então nenhum item pode ser garantido livre de
nozes.

Essa é a falha da lição 5 fantasiada. **Um papel pode tornar uma resposta errada mais convincente,
e não consegue torná-la certa.** Os fatos têm de vir de algum lugar que o café controla: o texto do
manual enviado com a pergunta, como exige o prompt de sistema da lição 22, com a instrução de dizer
"não sei" quando o texto não tem a resposta.

## Papéis combinados com instruções explícitas

Um papel define a voz; as instruções dizem o que a resposta tem de conter e nunca pode fazer.
Usados juntos, cada um faz o seu trabalho. O curso escreveu esta versão como ilustração:

```localised
Você é o assistente do balcão do Café Aurora: caloroso, breve, simples.

Responda só a partir do texto do manual abaixo. Se ele não resolver a
pergunta, diga isso e sugira perguntar à cozinha. Nunca diga que um
item é livre de um alérgeno.

<handbook>
The kitchen uses nuts, so no item can be guaranteed nut-free.
If a customer asks about an ingredient that is not on the label,
ask the kitchen; never guess.
</handbook>

Cliente: O pão de canela de vocês é livre de nozes?
```

O papel é uma linha e as regras são o resto. Um conjunto de teste (lição 20) consegue conferir as
regras: a resposta menciona que a cozinha usa nozes, e nunca diz "livre de nozes". Nada consegue
conferir "seja um especialista de nível mundial", e nada precisa.

## O papel do público muitas vezes importa mais

O papel que as pessoas buscam primeiro é o do modelo: quem ele deve ser. O que mais muda uma
resposta é muitas vezes o do **leitor**: para quem a resposta é. Um modelo que sabe com quem está
falando ajusta o vocabulário, o tamanho e o que explica, que é quase tudo o que se queria de um
papel.

O curso escreveu este par como ilustração. O mesmo pedido, dirigido a dois leitores:

```localised
Explique a um barista novo, no primeiro dia dele, por que perguntamos
aos clientes sobre alergias antes de recomendar um bolo.
```

```localised
Explique à seguradora do café por que a equipe pergunta aos clientes
sobre alergias antes de recomendar um bolo.
```

O primeiro pede frases curtas, um motivo de que um novato vai se lembrar e o que dizer no balcão. O
segundo pede a política, o risco que ela administra e o registro de que ela é cumprida. **Nenhum
papel para o modelo foi preciso em nenhum dos dois**: nomear o leitor definiu o registro, o
vocabulário e o ângulo de uma vez.

Então, quando uma resposta volta no tom errado, técnica demais ou vaga demais, longa demais ou rala
demais, a primeira coisa a conferir é se o prompt disse para quem ela é. "Explique a um barista
novo" é específico, pode ser julgado contra uma resposta e descreve algo real. "Você é um
especialista" não é nenhuma das três coisas.
