---
title: As cláusulas que decidem
version: 1
---

Uma licença de modelo tem poucas páginas, e a maior parte é o mesmo texto padrão de qualquer
licença: garantias negadas, responsabilidade limitada, qual foro. Três tipos de cláusula são
próprios de modelos, e são esses que se lê antes de qualquer outra coisa.

## Um teto para o quanto você pode crescer

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/LICENSE
  33: 2. Additional Commercial Terms. If, on the Llama 3.1 version release date, the monthly
      active users of the products or services made available by or for Licensee, or
      Licensee’s affiliates, is greater than 700 million monthly active users in the preceding
      calendar month, you must request a license from Meta, which Meta may grant to you in its
      sole discretion, and you are not authorized to exercise any of the rights under this
      Agreement unless or until Meta otherwise expressly grants you such rights.
```

Setecentos milhões de usuários por mês é um número que a Lantern Books não vai alcançar. Repare
como a cláusula funciona, porém: a contagem é feita **na data de lançamento da versão**, e acima
dela a licença não concede nada até a Meta concordar. É uma cláusula mirada num punhado de
empresas, e escrita de um jeito que não dá para crescer até ela por acidente.

A licença mais antiga da Qwen tem a mesma forma, com um número menor, e uma segunda cláusula que
importa mais para a maioria dos leitores:

```
# QwenLM/Qwen@2df8e8ac Tongyi Qianwen LICENSE AGREEMENT
  29: If you are commercially using the Materials, and your product or service has more than
      100 million monthly active users, You shall request a license from Us. You cannot
      exercise your rights under this Agreement without our express authorization.
  33: b. You can not use the Materials or any output therefrom to improve any other large
      language model (excluding Tongyi Qianwen or derivative works thereof).
```

**Cem milhões de usuários** ainda está longe para uma livraria. **A cláusula b** não está: ela
proíbe usar a *saída* do modelo para melhorar qualquer outro grande modelo de linguagem. Gerar
exemplos de treino com um modelo para fazer fine-tuning de outro (o quarto degrau da aula 1 seção
11) é um plano comum, e com esta licença ele só é permitido em direção à própria Qwen. O cartão da
Llama 3.1, citado na aula 1, diz o contrário: a licença dela permite exatamente esse uso.

## O que você deve quando distribui

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/LICENSE
  25: i. If you distribute or make available the Llama Materials (or any derivative works
      thereof), or a product or service (including another AI model) that contains any of
      them, you shall (A) provide a copy of this Agreement with any such Llama Materials; and
      (B) prominently display “Built with Llama” on a related website, user interface,
      blogpost, about page, or product documentation. If you use the Llama Materials or any
      outputs or results of the Llama Materials to create, train, fine tune, or otherwise
      improve an AI model, which is distributed or made available, you shall also include
      “Llama” at the beginning of any such AI model name.
```

Duas obrigações, e as duas recaem sobre quem **distribui** o modelo ou um produto que o contém: uma
cópia do contrato, e as palavras *Built with Llama* em algum lugar visível. Uma terceira vale para
quem usa as saídas da Llama para treinar um modelo que depois publica: o nome dele precisa começar
com *Llama*.

Chamar um modelo pela API de alguém não é distribuí-lo. Lançar um aplicativo que embute os pesos, ou
oferecer um modelo hospedado a clientes, é.

## Uma lista de usos que não são permitidos

A maioria das licenças de pesos abertos traz, ou aponta para, uma **política de uso aceitável**: uma
lista de finalidades a que o modelo não pode servir. A da Llama é um documento separado; as da
DeepSeek são um anexo da licença (a seção 04 cita o parágrafo que as apresenta). Elas proíbem coisas
como ajudar a causar dano a pessoas ou violar a lei, e viajam com o modelo: os derivados precisam
carregá-las também.

## Como ler uma, na prática

1. Ache a **concessão**: o que você pode fazer, e os adjetivos dela.
2. Ache qualquer **limite**: usuários, receita, tamanho da empresa. Anote quando ele é medido.
3. Ache o que ela diz sobre **saídas**: elas podem treinar outros modelos?
4. Ache as **obrigações na distribuição**: avisos, nomes, atribuição.
5. Ache a **política de uso**, e leia contra o que o seu produto faz.

Cinco perguntas, um quarto de hora, e uma nota escrita no projeto com as respostas e de qual versão
da licença elas vieram. **Uma licença tem versão, como o modelo**: a Llama 4 tem a sua, e a seção 06
mostra por que não dá para supor que uma resposta antiga vale para um lançamento novo.
