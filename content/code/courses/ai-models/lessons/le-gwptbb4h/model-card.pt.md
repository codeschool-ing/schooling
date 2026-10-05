---
title: Lendo um cartão de modelo
version: 1
---

Um **cartão de modelo** (*model card*) é o documento que os autores de um modelo publicam junto
com ele: com o que foi treinado, para que serve, como pontuou e onde se sabe que falha. É o mais
próximo de uma ficha técnica que um modelo tem, e a maioria das pessoas pula o cartão e vai direto
para a tabela de benchmarks. A tabela é a parte menos útil para decidir sobre a sua tarefa, porque
mede a tarefa de outra pessoa.

O cartão da Llama 3.1 passa de mil linhas. Dois parágrafos dele respondem a perguntas que a ana
precisa fazer sobre qualquer modelo antes de a Lantern Books depender dele:

```
ana@desk:~/desk$ sources quote llama3.1-card "^\*\*supported languages|^\*\*Intended Use Cases"
# meta-llama/llama-models@0e0b8c51 models/llama3_1/MODEL_CARD.md
  78: **Supported languages:** English, German, French, Italian, Portuguese, Hindi, Spanish,
      and Thai.
  93: **Intended Use Cases** Llama 3.1 is intended for commercial and research use in multiple
      languages. Instruction tuned text only models are intended for assistant-like chat,
      whereas pretrained models can be adapted for a variety of natural language generation
      tasks. The Llama 3.1 model collection also supports the ability to leverage the outputs
      of its models to improve other models including synthetic data generation and
      distillation. The Llama 3.1 Community License allows for these use cases.
```

## O que procurar, nesta ordem

**Idiomas.** *Suportado* quer dizer que os autores testaram e respondem pelos resultados. O
português está na lista da Llama 3.1, o que importa para uma loja cujos clientes escrevem em
português. O mesmo cartão diz, algumas centenas de linhas adiante, que o modelo foi treinado em
mais idiomas do que esses oito, e "desencoraja fortemente" usá-lo para conversar nos outros sem
trabalho adicional. Um idioma que funciona num teste rápido e não está na lista é um idioma que
ninguém mediu.

**Uso pretendido.** O parágrafo acima separa os dois tipos da seção 03: o ajustado para instruções
serve para "chat no estilo assistente", o pré-treinado serve para ser adaptado. Ele também diz que a
licença permite usar as saídas do modelo para melhorar outros modelos, coisa que algumas licenças
proíbem de forma explícita. A aula 2 mostra uma que proíbe.

**Dados de treino e a data deles.** Do que ele aprendeu, e quando isso parou. A seção 06 trata da
data.

**Avaliações.** Leia pelo **formato**, não pela nota: quais tarefas foram medidas, em quais idiomas,
contra quais outros modelos e com quantos exemplos. Um cartão que só traz benchmarks em inglês não
disse nada sobre e-mails em português.

**Limitações e segurança.** A parte escrita por quem mais conhece o modelo, sobre como ele erra. A da
Llama 3.1 ocupa várias seções. Um cartão sem seção de limitações não é um modelo sem limitações.

## Quando não há cartão

Os provedores fechados publicam algo parecido com outros nomes: um *system card*, uma página de
visão geral do modelo, notas de versão. Dizem menos sobre os dados de treino e nada sobre os pesos,
porque você nunca vai tê-los. O que eles publicam, e você precisa ler, é a lista de
**identificadores de modelo e as datas de aposentadoria**, que a aula 2 lê na tabela.

Um cartão responde ao que os autores mediram. **Se o modelo faz a sua tarefa é uma pergunta que só
os seus próprios casos respondem**, e a aula 5 ensina a fazê-la.
