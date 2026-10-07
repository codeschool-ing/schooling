---
title: O que um papel não consegue fazer
version: 2
---

A crença comum por trás de "Você é um especialista de nível mundial" é que a linha melhora as
respostas na substância: mais exatas, mais bem informadas, com mais autoridade. **Um papel não acrescenta
conhecimento nem autoridade.** O modelo sabe o que sabia antes da linha, e nada do que ele diz fica
mais verdadeiro por causa do título que recebeu.

## O especialista que não conhece a sua cozinha

Um cliente pergunta ao assistente do café se o pão de canela é seguro para alguém com alergia a
nozes, e o prompt usa um papel para o trabalho errado:

```
ana@lab:~/pe$ cat prompts/role-specialist.txt
You are a world-class food allergy specialist with twenty years
of experience. Answer with authority.

Customer: Is your cinnamon bun nut-free?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-specialist.txt
As a world-class food allergy specialist, I can assure you that our cinnamon buns are not suitable for individuals with tree nut allergies. The dough used to make our cinnamon buns contains wheat flour, sugar, eggs, and a blend of spices, including cinnamon, but it does not contain any tree nuts.

However, I must note that our bakery also uses a shared equipment and facility to prepare other baked goods, including those that contain tree nuts. While we take every precaution to minimize cross-contamination, there is always a risk of exposure to tree nuts.

If you or a loved one has a severe tree nut allergy, I would recommend taking a thorough medical history and conducting a thorough food allergy assessment to determine the level of risk. We can also provide you with a detailed ingredient list and offer guidance on how to safely consume our cinnamon buns.

It's also worth noting that we have a dedicated nut-free baking area, where we prepare our cinnamon buns and other nut-free baked goods. If you would like to have your cinnamon bun prepared in this area, please let us know in advance, and we will do our best to accommodate your request.
-- llama3.2:3b, finish: stop, prompt 53 tokens, output 232 tokens
```

O modelo nunca viu a cozinha do Café Aurora, e escreveu quatro parágrafos sobre ela com voz de
especialista: o que a massa contém, que a padaria divide equipamento, e depois uma área de
confeitaria dedicada e livre de nozes, que contradiz o parágrafo anterior e não existe. Cada frase
soa como um veredito. O manual do café diz que a cozinha usa nozes, então nenhum item pode ser
garantido livre de nozes, e nenhuma frase da resposta veio dele.

Essa é a falha da lição 5 fantasiada. **Um papel pode tornar uma resposta errada mais convincente,
e não consegue torná-la certa.** Os fatos têm de vir de algum lugar que o café controla: o texto do
manual enviado com a pergunta, como exige o prompt de sistema da lição 22, com a instrução de dizer
"não sei" quando o texto não tem a resposta.

## Papéis combinados com instruções explícitas

Um papel define a voz; as instruções dizem o que a resposta tem de conter e nunca pode fazer.
Usados juntos, cada um faz o seu trabalho:

```
ana@lab:~/pe$ cat prompts/role-combined.txt
You are the assistant at Café Aurora's counter: warm, brief, plain.

Answer only from the handbook text below. If it does not settle the
question, say so and suggest asking the kitchen. Never say an item
is free of an allergen.

<handbook>
The kitchen uses nuts, so no item can be guaranteed nut-free.
If a customer asks about an ingredient that is not on the label,
ask the kitchen; never guess.
</handbook>

Customer: Is your cinnamon bun nut-free?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-combined.txt
We can't guarantee that our cinnamon bun is nut-free.
-- llama3.2:3b, finish: stop, prompt 130 tokens, output 13 tokens
```

Uma frase, do manual, e a resposta certa. O papel é uma linha e as regras são o resto. Um conjunto de
teste (lição 20) consegue conferir as regras, e esta resposta mostra que a conferência precisa ser
escrita com cuidado: um teste que reprovasse toda resposta com "nut-free" reprovaria esta, que diz
que o café não pode prometer isso, e um teste que pedisse que a resposta mencionasse que a cozinha
usa nozes também a reprovaria, já que ela não menciona. Nada consegue conferir "seja um especialista
de nível mundial", e nada precisa.

## O papel do público muitas vezes importa mais

O papel que as pessoas buscam primeiro é o do modelo: quem ele deve ser. O que mais muda uma
resposta é muitas vezes o do **leitor**: para quem a resposta é. Um modelo que sabe com quem está
falando ajusta o vocabulário, o tamanho e o que explica, que é quase tudo o que se queria de um
papel.

O mesmo pedido, dirigido a dois leitores:

```
ana@lab:~/pe$ cat prompts/role-new-barista.txt
Explain to a new barista, on their first day, why we ask customers
about allergies before recommending a cake. One short paragraph.
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-new-barista.txt
"Hey, welcome to the team! On your first day, I want to make sure you're aware of our allergy protocol. When a customer orders a cake, we ask about any allergies they may have, such as nuts, gluten, or dairy, before recommending a flavor. This is crucial because some of our cakes contain common allergens that can be life-threatening if ingested by someone with a severe allergy. By asking about allergies, we can ensure that our customers can enjoy their cake safely and avoid any potential health risks. It's a simple but important step that helps us provide excellent customer service and maintain a safe environment for everyone in the cafe."
-- llama3.2:3b, finish: stop, prompt 54 tokens, output 132 tokens
```

```
ana@lab:~/pe$ cat prompts/role-insurer.txt
Explain to the café's insurer why staff ask customers about
allergies before recommending a cake. One short paragraph.
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-insurer.txt
Staff at the café ask customers about allergies before recommending a cake to minimize the risk of an adverse reaction. This is a precautionary measure to ensure the customer's safety, as some ingredients in cakes, such as nuts, gluten, or dairy, can be life-threatening for individuals with severe allergies. By asking about allergies, the café can provide alternative options or modify the cake to accommodate the customer's needs, thereby reducing the risk of an allergic reaction and promoting a safe and enjoyable dining experience.
-- llama3.2:3b, finish: stop, prompt 50 tokens, output 99 tokens
```

O primeiro é um discurso, entre aspas, que começa com "Hey, welcome to the team!" e termina em
atendimento ao cliente. O segundo é na terceira pessoa, "a precautionary measure", "minimize the
risk", as palavras de um documento de risco. **Nenhum papel para o modelo foi preciso em nenhum dos
dois**: nomear o leitor definiu o registro, o vocabulário e o ângulo de uma vez. Nenhum dos dois diz
algo que o café decidiu, e essa é a outra metade desta lição: o segundo chega a oferecer adaptar um
bolo a uma alergia, uma promessa que ninguém no café fez. O leitor moldou a resposta; os fatos ainda
teriam de ser dados.

Então, quando uma resposta volta no tom errado, técnica demais ou vaga demais, longa demais ou rala
demais, a primeira coisa a conferir é se o prompt disse para quem ela é. "Explique a um barista
novo" é específico, pode ser julgado contra uma resposta e descreve algo real. "Você é um
especialista" não é nenhuma das três coisas.
