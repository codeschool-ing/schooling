---
title: O que um papel muda numa resposta
version: 1
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

A pergunta é a mesma nos dois: a reclamação de um cliente de que o flat white está amargo. O curso
escreveu os dois prompts e as duas respostas como ilustração; nenhum modelo foi chamado.

Com o papel de um barista falando com um cliente:

```localised
Você é barista no Café Aurora, falando com um cliente no balcão.

Cliente: Meu flat white está muito amargo hoje. Por quê?
```

```localised
Desculpe por isso! Pode ser que o shot tenha corrido um pouco demais.
Vou fazer um novo para você, e se quiser mais suave posso usar leite
de aveia, sem custo extra.
```

Com o papel de um instrutor de café ensinando a equipe nova:

```localised
Você é instrutor de café no Café Aurora, ensinando a equipe nova.

Aprendiz: Um cliente disse que o flat white estava muito amargo. Por quê?
```

```localised
Amargor costuma indicar superextração: a água ficou tempo demais em
contato com o café, ou a moagem estava fina demais. Confira primeiro
o tempo do shot. Se estiver longo, engrosse um pouco a moagem e tire
um shot de teste antes de servir.
```

As duas são razoáveis, e não são intercambiáveis. A primeira pede desculpas, oferece uma solução e
cita um fato do manual do café. A segunda usa a palavra "superextração", dá uma causa e um
procedimento, e não pede desculpas a ninguém. **Nenhum dos papéis acrescentou um fato que o outro
não tinha**: a causa do amargor é a mesma nas duas, e veio do que o modelo aprendeu no treinamento.
O que mudou foi qual parte desse conhecimento foi posta à frente, com que palavras, para quem.

## Um papel é barato, e essa é a força dele

Uma linha muda o registro de toda resposta que vem depois. É uma boa troca onde o registro importa:
um assistente de site que deve soar como o café, um tutor que deve explicar em vez de se exibir, um
revisor que deve ser direto. O prompt de sistema do café na lição 22 tem um papel pequeno na
primeira linha exatamente por isso.

Ele não substitui dizer o que você quer. "Você é um assistente conciso" é um jeito mais fraco de
escrever "responda em no máximo três frases", e a versão explícita pode ser testada contra uma
resposta. **Use um papel para a voz, e uma instrução para tudo o que você vai conferir.**
