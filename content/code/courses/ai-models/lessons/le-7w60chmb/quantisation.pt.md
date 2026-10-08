---
title: Menos bits por peso
version: 1
---

A coluna de 4 bits da seção 03 não é um modelo diferente. São os mesmos pesos **guardados com menos
precisão**: cada número de 16 bits trocado por um de 4 bits, mais um pouco de informação extra por
grupo de pesos dizendo como reescalá-los. Isso é **quantização**, e é o motivo de modelos abertos
rodarem em hardware comum.

O que ela compra está na tabela: o 8B vai de 16 GB para 4 GB, o 70B de 141 GB para 35 GB. O que ela
custa é **precisão**. Um número de 4 bits só pode assumir dezesseis valores. Os formatos de
quantização são espertos na escolha desses dezesseis, e em manter os pesos mais sensíveis com mais
precisão, mas alguma informação se perde.

## Quanto custa, e por que você mede

O padrão relatado em muitos modelos, por quem constrói os formatos, é mais ou menos este:

- **8 bits** fica quase indistinguível de 16 na maioria das tarefas;
- **4 bits** perde um pouco: um ou dois pontos em benchmarks, mais em algumas tarefas que em outras;
- **abaixo de 4 bits** as perdas crescem rápido, e modelos pequenos sofrem mais que os grandes.

"Um pouco em benchmarks" é a frase contra a qual a aula 1 seção 09 avisou: a tarefa de outra pessoa.
A perda é desigual, e as tarefas que sofrem primeiro são as precisas: aritmética, seguir um formato
de saída rígido, um idioma que era uma fatia pequena do texto de treino. **A tarefa de extração da
ana pede JSON exato**, que é exatamente o tipo de coisa a conferir em vez de supor.

Então um modelo quantizado é **um candidato diferente** na aula 5. `llama-3.1-8b em 16 bits` e
`llama-3.1-8b em 4 bits` são duas linhas na avaliação, cada uma com a sua nota, e a segunda só é mais
barata se a nota dela ainda for boa o bastante.

## Onde você a encontra sem escolher

As entradas `fp8` da aula 2 eram quantização feita por um host, em 8 bits. Os modelos do Ollama
(aula 14) vêm quantizados por padrão, e a tag no nome diz como. Sempre que um preço ou um tamanho de
download parecer pequeno demais para a contagem de parâmetros, a explicação quase sempre está aqui,
e a pergunta a fazer é **quantos bits**.
