---
title: Licença do código não é licença dos pesos
version: 1
---

O repositório de um modelo costuma guardar duas coisas diferentes: o **código** que carrega e roda
o modelo, e os **pesos**, ou instruções para obtê-los. Eles podem estar sob licenças diferentes, e o
selo no topo da página nomeia só uma.

O README da DeepSeek-V3 diz isso com todas as letras:

```
# deepseek-ai/DeepSeek-V3@9b4e9788 README.md
 345: This code repository is licensed under [the MIT License](LICENSE-CODE). The use of
      DeepSeek-V3 Base/Chat models is subject to [the Model License](LICENSE-MODEL).
      DeepSeek-V3 series (including Base and Chat) supports commercial use.
```

O código é MIT, que não impõe condições. Os modelos estão sob uma **Model License** separada, e essa
impõe. O preâmbulo dela diz de que tipo:

```
# deepseek-ai/DeepSeek-V3@9b4e9788 LICENSE-MODEL
  13: In short, this license strives for both the open and responsible downstream use of the
      accompanying model. When it comes to the open character, we took inspiration from open
      source permissive licenses regarding the grant of IP rights. Referring to the downstream
      responsible use, we added use-based restrictions not permitting the use of the model in
      very specific scenarios, in order for the licensor to be able to enforce the license in
      case potential misuses of the Model may occur. At the same time, we strive to promote
      open and responsible research on generative models for content generation.
```

Então uma equipe que lê "MIT" no repositório e para ali leu a licença errada. As restrições de uso
estão num anexo da Model License, e o parágrafo acima diz que elas acompanham todo derivado.

## Um modelo feito a partir de outro

A mesma coisa acontece um nível abaixo. A DeepSeek também publicou modelos menores treinados para
imitar o R1, e o README tem cuidado com a origem de cada um:

```
# deepseek-ai/DeepSeek-R1@0cf78561 README.md
 259: - DeepSeek-R1-Distill-Qwen-1.5B, DeepSeek-R1-Distill-Qwen-7B, DeepSeek-R1-Distill-
      Qwen-14B and DeepSeek-R1-Distill-Qwen-32B are derived from [Qwen-2.5
      series](https://github.com/QwenLM/Qwen2.5), which are originally licensed under [Apache
      2.0 License](https://huggingface.co/Qwen/Qwen2.5-1.5B/blob/main/LICENSE), and now
      finetuned with 800k samples curated with DeepSeek-R1.
 260: - DeepSeek-R1-Distill-Llama-8B is derived from Llama3.1-8B-Base and is originally
      licensed under [Llama3.1 license](https://huggingface.co/meta-
      llama/Llama-3.1-8B/blob/main/LICENSE).
 261: - DeepSeek-R1-Distill-Llama-70B is derived from Llama3.3-70B-Instruct and is originally
      licensed under [Llama3.3 license](https://huggingface.co/meta-
      llama/Llama-3.3-70B-Instruct/blob/main/LICENSE).
```

O R1 em si é MIT (seção 02). **Estes não são**, ou não só: cada um começou como o modelo de outra
pessoa, e mantém a licença desse modelo. O destilado de 8B é uma Llama 3.1 por baixo e carrega os
termos da Llama da seção 03, incluindo o *Built with Llama* se você distribuí-lo. Um fine-tuning
herda do mesmo jeito, e isso inclui um que a ana venha a fazer a partir de qualquer base da aula 1
seção 11.

## E o repositório que você consegue ler muitas vezes é só o código

O `mistral-inference` é o código para rodar os modelos da Mistral. O arquivo de licença dele é o que
todo mundo reconhece:

```
# mistralai/mistral-inference@9eaeb91c LICENSE
   1: Apache License
   2: Version 2.0, January 2004
```

Isso diz o que você pode fazer com **o código de inferência**. A Mistral publica os modelos abertos
dela sob licenças declaradas modelo a modelo, na página de cada um, e os modelos comerciais dela não
são abertos. O arquivo acima não responde a nenhuma dessas perguntas.

**A regra que sai daí: ache a licença dos pesos que você vai de fato rodar**, por nome e versão, na
página de onde esses pesos são publicados. O selo do repositório, a fama de abertura da empresa e
uma licença lida para a versão anterior são, cada um, um palpite.
