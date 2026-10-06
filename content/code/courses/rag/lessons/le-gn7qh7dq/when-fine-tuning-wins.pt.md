---
title: Quando o fine-tuning vence
version: 1
---

As quatro últimas seções deixam o fine-tuning com cara de ferramenta errada, e para ensinar os fatos de
uma empresa a um modelo ele quase sempre é. Ele é a ferramenta certa para outro trabalho, e uma equipe
que o descarta de vez acaba tentando fazer esse trabalho com prompts, mal.

## Quando o problema é o como, não o quê

O fine-tuning muda um comportamento que aparece em toda resposta. Isso o torna a ferramenta certa quando
o modelo tem o conhecimento, ou o recebe da recuperação, e erra a **forma**.

- **Um formato de saída rígido.** Um sistema de atendimento que entrega respostas a uma ferramenta de
  chamados precisa do mesmo formato JSON toda vez, com os mesmos nomes de campo. Um prompt pode pedir
  isso; algumas centenas de exemplos fazem disso um hábito do modelo.
- **Um estilo da casa.** O manual de atendimento deste corpus diz: a resposta primeiro, o nome do
  cliente uma vez, no máximo um pedido de desculpas, o próximo passo com data. Um modelo pode receber
  isso em todo prompt e se desviar sob a pressão de um contexto longo; um modelo treinado em algumas
  centenas de respostas escritas assim se desvia muito menos.
- **A linguagem de um domínio.** Um modelo que insiste em chamar um *ponto de retirada* de *armário de
  coleta*, ou que lê mal as abreviações da própria loja, aprende o vocabulário com exemplos mais depressa
  que com um glossário em todo prompt.
- **Recusar bem.** Dizer "os documentos não cobrem isso" em vez de chutar é comportamento, e pode ser
  ensinado. Um modelo ajustado com exemplos em que a resposta certa é uma recusa recusa com mais
  facilidade, com o contexto recuperado ainda decidindo o que ele sabe.

## Quando o prompt sai caro demais

Cada instrução num prompt de sistema é paga em toda requisição, e instruções longas também custam tempo
antes do primeiro token. Um comportamento que precisa de uma página de instruções e vinte exemplos para
se sustentar custa essa página em toda pergunta, para sempre. O fine-tuning move a página para os pesos.
Em volume alto isso pode pagar o treinamento várias vezes, que é a mesma conta do ponto de equilíbrio da
seção de custo, aplicada a instruções em vez de conhecimento.

A versão extrema é a **destilação**: as respostas de um modelo grande e caro viram exemplos de
treinamento para um pequeno e barato, que então faz aquele trabalho quase tão bem por uma fração do
preço e da latência. É como muitos sistemas em produção rodam uma tarefa estreita em escala, e é um
fine-tuning como outro qualquer.

## Quando não dá tempo de recuperar

A recuperação acrescenta uma busca a cada requisição: um embedding da pergunta, uma consulta ao índice e
um prompt mais longo para o modelo ler. Neste laboratório a busca é um embedding e um produto de
matrizes, e para a maioria dos usos o tempo dela não importa. Para um assistente de voz ou um
autocompletar, em que a resposta inteira tem um orçamento de algumas centenas de milissegundos, um modelo
que já conhece o pequeno e estável conjunto de fatos de que precisa pode ser o único projeto que cabe.

## O que nenhuma dessas vitórias muda

Em todos os casos acima, **os fatos continuam vindo de um lugar que você pode atualizar e citar**, ou
são poucos e estáveis o bastante para aceitar o custo de treinar de novo quando mudam. Um modelo ajustado
que tem de responder sobre as políticas da Marginalia continua sendo um modelo que precisa das políticas
no prompt; o que o fine-tuning comprou é que ele responde na forma certa, na voz certa, e recusa quando
deve. Essa é a combinação que a próxima seção recomenda.
