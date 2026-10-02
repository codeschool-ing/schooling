---
title: Escolher um modelo, e conferir o que você lê
version: 1
---

O jeito tentador de escolher é achar uma tabela comparativa, pegar o modelo do topo e seguir em
frente. A tabela já estava desatualizada antes de você encontrá-la, e ordenou os modelos pelas
tarefas de outra pessoa. **O modelo a usar é o mais barato que faz a sua tarefa bem o bastante,
medido na sua tarefa.** Tudo abaixo é como encontrá-lo.

## Os critérios

| critério | a pergunta a fazer |
|---|---|
| qualidade na sua tarefa | quantos dos seus próprios casos de teste ele acerta? |
| custo | quanto custa um dos seus pedidos típicos, entrada e saída juntas? |
| latência | quanto tempo leva uma resposta, e quanto o seu usuário pode esperar? |
| tamanho do contexto | a sua maior entrada real cabe, com espaço para a resposta (lição 4)? |
| política de dados | para onde vão os seus prompts, e o que acontece com eles (a seção anterior)? |
| disponibilidade | ele é oferecido na sua região, e no volume de que você precisa? |
| vida útil | quando este modelo exato vai ser aposentado, e quanto vai custar substituí-lo? |

A primeira linha é a que as pessoas pulam. **De vinte a cinquenta exemplos reais do seu trabalho,
com a resposta que você aceitaria para cada um, dizem mais que qualquer nota pública.** São
as suas entradas, na sua língua, com os seus casos difíceis, e ninguém treinou um modelo com eles
(lição 10). Rode cada candidato no mesmo conjunto, conte e guarde o conjunto: quando um modelo for
aposentado, o mesmo conjunto diz se o substituto é tão bom quanto ele.

## Preço por token não é preço por tarefa

Os provedores cobram por milhão de tokens, e é tentador comparar esses números direto. Eles não se
comparam, porque **os modelos de cada provedor cortam o texto em tokens do seu próprio jeito**, então
o mesmo pedido vira um número diferente de tokens em cada um. A bancada tem dois tokenizadores,
ambos da OpenAI, uma codificação mais antiga e uma mais nova, e eles discordam numa frase em
português:

```
ana@lab:~/pe$ tok show "O café abre às oito aos domingos." -e cl100k_base
"O" " café" " abre" " às" " o" "ito" " aos" " dom" "ing" "os" "."
46 53050 67441 53629 297 6491 43914 4824 287 437 13
11 tokens, 33 characters (cl100k_base)
ana@lab:~/pe$ tok show "O café abre às oito aos domingos." -e o200k_base
"O" " café" " abre" " às" " oito" " aos" " domingos" "."
46 30469 59024 16683 99497 13924 194577 13
8 tokens, 33 characters (o200k_base)
```

A codificação mais antiga corta `oito` e `domingos` em pedaços e precisa de 11 tokens; a mais nova
tem as duas como palavras inteiras e precisa de 8. No manual do café, em inglês, as duas ficam bem
mais perto:

```
ana@lab:~/pe$ tok count handbook/*.md -e cl100k_base
tokens  words  chars  file
    73     55    310  handbook/allergens.md
    61     44    249  handbook/deliveries.md
    66     46    261  handbook/hours.md
    59     50    260  handbook/loyalty.md
    75     62    318  handbook/refunds.md
    49     35    209  handbook/wifi.md
ana@lab:~/pe$ tok count handbook/*.md -e o200k_base
tokens  words  chars  file
    70     55    310  handbook/allergens.md
    60     44    249  handbook/deliveries.md
    65     46    261  handbook/hours.md
    58     50    260  handbook/loyalty.md
    74     62    318  handbook/refunds.md
    48     35    209  handbook/wifi.md
```

Isso são duas codificações de um só provedor. Os tokenizadores dos outros provedores diferem de
novo, e nenhum deles está na bancada, então este curso não mostra contagem para eles. A regra que
decorre disso não precisa de uma: **compare quanto custa um pedido típico inteiro em cada
provedor**, o que os contadores de tokens deles ou um pedido de teste dizem, e não o preço por
milhão.

## Como conferir o que você lê

Cada fato da primeira seção desta lição tem uma data, e tudo o que você lê sobre modelos também.
Três fontes, em ordem de confiança:

- o cartão do modelo (*model card*), a página ou o arquivo do próprio provedor para um modelo exato,
  dizendo para que ele foi feito, o tamanho do contexto, os limites e a licença. Leia o cartão do
  modelo e da versão exatos que você vai chamar, não o da família;
- a documentação e as páginas de preço do provedor, que dizem o que está disponível, onde e a que
  preço. Procure a data da última atualização da página, e desconfie de uma página sem data;
- todo o resto, incluindo tabelas comparativas, artigos e este curso, como uma indicação do que
  conferir nas duas primeiras.

**Uma tabela comparativa num curso fica desatualizada em poucos meses**, e é por isso que este não
tem nenhuma. O que não fica desatualizado é o método: o seu próprio conjunto de teste, o custo de um
pedido inteiro e os documentos datados do provedor.

::: track ai
O curso `ai-models`, mais à frente nesta trilha, pega esse assunto: os provedores um a um, quando
vale rodar você mesmo modelos de pesos abertos e como avaliar candidatos com os seus próprios casos.
:::

::: track *
Este curso não vai além disso na escolha de modelos. O método acima basta para escolher um para os
prompts que o resto do curso ensina.
:::
