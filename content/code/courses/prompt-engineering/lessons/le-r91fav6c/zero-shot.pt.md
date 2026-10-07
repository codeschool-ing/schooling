---
title: Uma instrução, a entrada e nenhum exemplo
version: 2
---

**Um prompt zero-shot pede uma tarefa sem mostrar um único exemplo resolvido dela.** Ele dá a
instrução e a entrada, e conta com o que o modelo aprendeu no treinamento para saber o que querem
dizer "classificar", "resumir" ou "traduzir". O "shot" é um exemplo resolvido; zero deles é o jeito
padrão como as pessoas usam uma janela de chat.

A crença comum é que o zero-shot funciona ou não funciona conforme a esperteza do modelo. Na
prática, **a maioria das falhas de zero-shot vem de o prompt deixar algo sem dizer**, e de o modelo
preencher a lacuna com o que fosse provável. As correções estão na redação, e são quatro.

## Uma versão fraca

O Café Aurora recebe mensagens pelo site e quer cada uma rotulada, para que as reclamações cheguem
primeiro ao gerente. Eis uma primeira tentativa, como um modelo de prompt: `{message}` é onde cada
mensagem entra. Salve-a como `~/pe/prompts/weak.txt`:

```
ana@lab:~/pe$ cat prompts/weak.txt
Is this review positive or negative?

{message}
```

Cada parte dela deixa uma decisão para o modelo:

- a tarefa oferece dois rótulos, e o café precisa de quatro: positiva, negativa, mista, e mensagens
  que nem são avaliações;
- a entrada vem emendada na instrução, sem nada dizendo onde uma termina e a outra começa;
- a saída não é descrita, então o modelo pode responder com uma palavra, uma frase ou uma resposta;
- os casos-limite não são mencionados, e esta entrada é um deles: é uma pergunta, não uma avaliação.

Diante de uma mensagem que é uma pergunta, um modelo tem todos os motivos para respondê-la, porque
responder perguntas é aquilo para que ele foi treinado (lição 1), ou para inventar um rótulo que
ninguém listou. Nada no prompt diz o contrário, e a próxima seção de leitura mostra o que ele fez.

## Uma versão forte

A mesma tarefa, com cada lacuna fechada. Salve-a como `~/pe/prompts/strong.txt`:

```
ana@lab:~/pe$ cat prompts/strong.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Edge cases:
  - Sarcasm counts as what the writer means, not what the words say.
  - Messages in any language get the same English labels.
  - Do not answer questions; label them not_a_review.

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
```

Ela é mais longa, e cada acréscimo carrega uma decisão:

1. Uma tarefa clara. Diz o que é rotulado e para quem, e lista os quatro rótulos que o café usa,
   cada um com uma definição de uma linha. `mixed` é onde dois leitores têm mais chance de
   discordar, então a definição dele é a mais cuidadosa.
2. A entrada delimitada. A mensagem fica entre tags `<message>`, a convenção da lição 18.
   Instruções dentro da mensagem de um cliente ficam então visivelmente parte da mensagem.
3. O formato da saída declarado. Um rótulo, em minúsculas, mais nada. Um programa comparando a
   resposta com `negative` estaria, de outro jeito, comparando com `Negative.` ou `This is
   negative`.
4. Os casos-limite nomeados. Ironia, outros idiomas, perguntas. São as entradas em que um leitor
   razoável poderia ir para qualquer lado, então o prompt faz a escolha no lugar do modelo.

**Nada disso ensina ao modelo algo novo.** Ele já sabe o que é ironia. O que o prompt acrescenta é
a sua decisão sobre ela, que o modelo não tem como adivinhar.

## De onde vêm os casos-limite

Você não acha casos-limite pensando muito antes. Você os acha em **entradas reais**: as mensagens
que o café de fato recebe, lidas em bloco, classificadas à mão e discutidas onde duas pessoas
discordam. Cada discordância entre duas pessoas é uma frase de que o prompt precisa. A lista da
versão forte é o que uma leitura dessas produz, e a próxima seção de leitura a transforma num
teste.
