---
title: O que ele não sabe
version: 1
---

Um modelo pré-treinado sabe o que estava no texto de treino, e nada do que aconteceu depois que
esse texto foi coletado. Essa data é o **corte de conhecimento** (*knowledge cutoff*), e o cartão
da Llama 3.1 a declara com todas as letras:

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/MODEL_CARD.md
 188: **Data Freshness:** The pretraining data has a cutoff of December 2023.
```

Dois erros vêm daí, e apontam em direções opostas.

**O primeiro é esperar que ele saiba o que é recente.** Pergunte a um modelo com esse corte sobre
um livro publicado em 2025 e ele tem três opções: dizer que não sabe, descrever um livro mais
antigo com título parecido, ou inventar um. O ajuste empurra os modelos para a primeira, e nenhum
deles consegue isso sempre, porque o modelo não tem uma lista do que não sabe. Uma descrição
confiante de um livro que não existe se lê exatamente como a descrição confiante de um que existe.

**O segundo é esquecer que quase tudo o que importa nunca foi público.** O corte é o problema menor
da Lantern Books. Os números de pedido, o estoque, a transportadora e as regras de reembolso nunca
estiveram nos dados de treino de ninguém, antes ou depois de data nenhuma. Nenhum modelo, por mais
recente, sabe que o `LB-20417` ainda está no depósito. Um modelo mais novo estreita a primeira
lacuna e deixa a segunda exatamente do mesmo tamanho.

## O que fecha cada lacuna

| o que falta ao modelo | exemplo | o que fornece |
|---|---|---|
| fatos públicos depois do corte | um título lançado no mês passado | recuperação de uma fonte confiável, ou um modelo mais novo |
| os seus próprios fatos, em qualquer data | onde está o pedido `LB-20417` | recuperação dos seus sistemas, toda vez |
| um fato que muda de hora em hora | o estoque de um título | uma ferramenta que o modelo pode chamar, nunca a memória |

As três respostas têm a mesma forma: **colocar o fato no prompt, no momento da requisição.** O
modelo então lê o fato como texto, do mesmo jeito que lê o e-mail. Recuperar o trecho certo é o
assunto de `embeddings-vectors` e `rag`, os dois cursos que vêm depois deste na trilha `ai`;
chamar uma ferramenta está em `agents-mcp`.

## O que isso significa para escolher

Um corte mais recente vale alguma coisa quando a sua tarefa é sobre o mundo: bibliotecas atuais,
acontecimentos recentes, produtos novos. Para as tarefas da ana ele quase não vale nada. Classificar
um e-mail em cinco rótulos não precisa de fato mais novo que o idioma em que ele foi escrito;
extrair `LB-20417` não precisa de fato nenhum.

Então **ponha o corte na lista de critérios só quando a tarefa depende de fatos públicos e
recentes**, e mesmo assim prefira fornecer os fatos a escolher um modelo pela data. A data é a única
propriedade que todo modelo perde um pouco mais a cada dia em que continua em uso.
