---
title: O que um papel muda numa resposta
version: 2
---

Um prompt de papel diz ao modelo quem ele deve ser: "Você é um barista-chefe", "Você é um professor
paciente", "Você é um advogado revisando um contrato de aluguel". É uma linha, costuma vir primeiro
e, numa aplicação, fica na mensagem de sistema da lição 22, já que vale para a conversa inteira.

**Um papel é um jeito de escolher com que tipo de texto a resposta vai se parecer.** Um modelo
produz texto provável (lição 1), e o texto de onde ele aprendeu foi escrito por muitos tipos de
pessoa para muitos tipos de leitor. Um barista explicando café a um cliente escreve diferente de
um torrador ensinando aprendizes, e uma linha de papel torna provável continuar num desses estilos.

## Quatro coisas que um papel define

- O registro: o quanto é formal, o quanto é caloroso, quantas palavras. Um barista no balcão é
  breve e simpático; um instrutor é minucioso.
- O vocabulário: que termos são usados, e quais são explicados. "Extração" é coisa comum para um
  torrador e precisa de explicação para um cliente.
- O ângulo: sobre o que é a resposta. Perguntado por que um café está amargo, um barista pensa no
  que fazer agora e um instrutor em por que isso acontece.
- O público que a resposta supõe: o que ela dá como sabido, e o que ela para para explicar.

**A quarta é a que as pessoas esquecem que estão definindo**, e a próxima seção de leitura volta a
ela.

## A mesma pergunta, dois papéis

A pergunta é a mesma nos dois: um flat white amargo. Com o papel de um barista falando com um
cliente:

```
ana@lab:~/pe$ cat prompts/role-barista.txt
You are a barista at Café Aurora, talking to a customer at the counter.
Reply in three sentences or fewer.

Customer: My flat white tastes really bitter today. Why?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-barista.txt
I'd be happy to help you troubleshoot. Can you tell me when you last had a flat white from us that you enjoyed, and have you noticed any changes in your coffee beans or brewing method recently?
-- llama3.2:3b, finish: stop, prompt 61 tokens, output 43 tokens
```

Com o papel de um instrutor de café ensinando a equipe nova:

```
ana@lab:~/pe$ cat prompts/role-instructor.txt
You are a coffee instructor at Café Aurora, teaching new staff.
Reply in three sentences or fewer.

Trainee: A customer said their flat white tasted really bitter. Why?
ana@lab:~/pe$ ask - --temperature 0 < prompts/role-instructor.txt
That's a great question, trainee! A flat white's bitterness can be caused by over-extraction of the coffee, which can happen if the brewing time is too long or the coffee-to-water ratio is off. Let's review the brewing technique and make sure we're aiming for a balanced extraction to bring out the smooth, velvety texture and flavors we want in a flat white.
-- llama3.2:3b, finish: stop, prompt 60 tokens, output 80 tokens
```

As duas são razoáveis, e não são intercambiáveis. O barista não explicou nada: fez duas perguntas ao
cliente, sobre o último flat white de que ele gostou e sobre os grãos e o preparo dele, como se o
cliente tivesse feito o café. O instrutor nomeou uma causa, "over-extraction", deu dois jeitos de
ela acontecer e passou ao que o aprendiz deve conferir, com um "great question" na entrada.
**Nenhum papel acrescentou um fato que faltasse ao outro**: o que deixa o café amargo veio do que o
modelo aprendeu no treino, e o instrutor o pôs à frente enquanto o barista não. O que mudou foi qual
parte desse conhecimento foi usada, com que palavras, para quem.

A resposta do barista também mostra o que um papel não resolve. Ela soa como uma pessoa no balcão, e
responde a uma reclamação com perguntas que o cliente não sabe responder. Um papel escolhe uma voz;
não escolhe uma boa resposta.

## Um papel é barato, e essa é a força dele

Uma linha muda o registro de toda resposta que vem depois. É uma boa troca onde o registro importa:
um assistente de site que deve soar como o café, um tutor que deve explicar em vez de se exibir, um
revisor que deve ser direto. O prompt de sistema do café na lição 22 tem um papel pequeno na
primeira linha exatamente por isso.

Ele não substitui dizer o que você quer. "Você é um assistente conciso" é um jeito mais fraco de
escrever "responda em no máximo três frases", e a versão explícita pode ser testada contra uma
resposta. **Use um papel para a voz, e uma instrução para tudo o que você vai conferir.**
