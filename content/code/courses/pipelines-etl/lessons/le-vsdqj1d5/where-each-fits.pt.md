---
title: Onde cada um se encaixa
version: 1
---

Declarativo nem sempre é melhor. Ele precisa que todo passo tenha uma saída que possa ser comparada, e
alguns passos não têm nenhuma:

- **Enviar alguma coisa.** Um e-mail para os gerentes, uma mensagem num canal de chat, uma chamada
  que cobra um cartão. Não há arquivo que diga *o e-mail existe*, e rodar o passo duas vezes o envia
  duas vezes. Passos assim são imperativos por natureza, e ficam no fim, protegidos para rodar uma
  vez.
- **Decidir enquanto roda.** Um laço sobre o que a API devolveu esta noite, um desvio conforme uma
  contagem. Uma declaração fixa o grafo antes de qualquer coisa rodar; um script decide no caminho.
  Foi o caso do Prefect na lição 13.
- **Esperar e tentar de novo.** *Tente de novo em quinze segundos, depois em trinta* é uma sequência
  no tempo. Os retries, sensores e prazos da lição 10 são maquinaria imperativa em volta de cada passo.

E imperativo nem sempre é mais simples. Quando um pipeline tem mais que um punhado de passos, a ordem
escrita à mão e o trabalho refeito a cada execução são para onde vão o tempo e os erros.

Então a maioria dos pipelines de verdade é as duas coisas, em camadas, e o curso já construiu um. **O
Airflow declara o grafo e roda tarefas imperativas**, com retries e tempo marcado. Uma dessas tarefas
é o `dbt build`, que é **uma declaração de tabelas**. Dentro do warehouse, todo modelo é um `select`,
a coisa mais declarativa deste curso. A pergunta em cada camada é a mesma: este passo é mais bem
descrito pelo *que ele produz* ou pelo *que ele faz*? Onde ele produz algo que pode ser conferido,
declare. Onde ele só faz algo, escreva os passos, e torne-os seguros para repetir.
