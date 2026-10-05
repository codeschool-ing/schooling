---
title: Quem decide quando muda
version: 1
---

O modelo que a ana escolhe na aula 5 vai ser medido contra os quarenta casos dela num dia, com um
nome. A pergunta desta seção é **o que acontece com essa medição no ano que vem**, e a resposta é
diferente para cada tipo.

## Um modelo fechado é aposentado no calendário do provedor

Os provedores publicam datas depois das quais um identificador de modelo para de responder. A tabela
traz essas datas onde as conhece, como `deprecation_date`, e o `sheet retiring` lista toda entrada
que tem uma:

```
ana@desk:~/desk$ sheet retiring --provider anthropic
# LiteLLM model sheet at 21881c57, 4472 entries
3 entries carry a deprecation date
2026-06-09  claude-mythos-preview                              anthropic
2026-11-30  claude-sonnet-4-5                                  anthropic
2026-11-30  claude-sonnet-4-5-20250929                         anthropic
```

Duas datas, e hoje, quando este curso é gravado, uma delas já passou. O **Claude Sonnet 4.5**
responde até o fim de novembro de 2026; um produto que ainda o chame depois disso recebe um erro no
lugar da resposta. Os dois nomes de API da DeepSeek também tinham data:

```
ana@desk:~/desk$ sheet retiring --provider deepseek
# LiteLLM model sheet at 21881c57, 4472 entries
4 entries carry a deprecation date
2026-07-24  deepseek-chat                                      deepseek
2026-07-24  deepseek-reasoner                                  deepseek
2026-07-24  deepseek/deepseek-chat                             deepseek
2026-07-24  deepseek/deepseek-reasoner                         deepseek
```

E a lista da OpenAI é comprida o bastante para pedir um `head`:

```
ana@desk:~/desk$ sheet retiring --provider openai | head -6
# LiteLLM model sheet at 21881c57, 4472 entries
44 entries carry a deprecation date
2026-07-23  computer-use-preview                               openai
2026-07-23  gpt-5-chat                                         openai
2026-07-23  gpt-5-chat-latest                                  openai
2026-07-23  gpt-5.1-chat-latest                                openai
```

Quarenta e quatro entradas para um provedor. Algumas são versões datadas substituídas por outras
mais novas; algumas, como `gpt-5-chat-latest`, são **apelidos**: nomes que apontam para o que o
provedor servir sob eles no momento, que é um segundo jeito de um modelo mudar debaixo de você sem
aposentadoria nenhuma.

O padrão é o mesmo em todo lugar:

- **Um identificador datado** (`claude-sonnet-4-5-20250929`) nomeia um modelo fixo. Ele não muda,
  e um dia para.
- **Um apelido** (`claude-sonnet-4-5`, `...-latest`) nomeia um membro da família. Ele continua
  respondendo, e o que responde pode mudar numa data que ninguém avisou a você.

Então fixe um identificador datado em produção quando existir, registre qual no projeto, e ponha a
data de aposentadoria num calendário com a avaliação da aula 5 anexada a ela. A aula 21 volta a isso
como tarefa de operação.

## Um modelo aberto muda quando você o muda

Um arquivo de pesos no seu disco nunca é aposentado. Ele responde do mesmo jeito daqui a dez anos,
que é exatamente o que a avaliação que você rodou nele supôs. O que pode sair do ar é **um host**: as
entradas da seção 05 vêm e vão, e um host que serve um modelo antigo pode parar. Os pesos continuam
seus; você os leva para outro lugar.

Esse é o argumento prático mais forte a favor dos pesos abertos nesta aula. **Controle é sobretudo
controle do tempo**: decidir quando o modelo muda, e rodar os seus casos de novo antes, não depois.
