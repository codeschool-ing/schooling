---
title: Eficiência de fluxo, e o que o quadro não enxerga
version: 1
---

A seção anterior achou a espera **entre** colunas. A espera **dentro** de uma coluna é mais difícil de ver, e costuma ser maior. Um item que passa 3,6 dias em *Development* não ficou sendo desenvolvido por 3,6 dias. Parte disso foi trabalho; parte foi o seu dev numa reunião, revisando a mudança de um colega, respondendo uma dúvida de suporte ou esperando um ambiente de teste.

**Eficiência de fluxo** é o nome da parte que foi trabalho:

```localised
eficiência de fluxo = tempo trabalhado de fato ÷ tempo total decorrido
```

Um item trabalhado por um dia num tempo de ciclo de cinco dias tem eficiência de fluxo de 20%. O número importa porque diz de onde a melhoria pode vir. Se um item é trabalhado em 20% do tempo, fazer as pessoas trabalharem mais rápido pode tirar um pouco desses 20%; **remover a espera pode tirar tempo dos outros 80%**.

## Por que o quadro não consegue calcular

Um quadro registra quando um item **entrou** numa coluna. Não registra quando alguém estava de fato trabalhando nele, porque ninguém move um cartão de volta para *Waiting* toda vez que vai almoçar. Então a eficiência de fluxo é o único número desta aula que os arquivos do time de Billing não conseguem dar. O `billing.py` sabe quantos dias de trabalho cada item precisou, e de propósito não escreve isso, porque nenhum quadro real teria essa informação.

O que os arquivos **conseguem** dar é um limite. Todo dia na coluna de revisão foi espera, menos o último, porque revisar leva horas e o item foi integrado no dia em que foi revisado. Em julho, só isso deu 7,1 dias de espera pura num lead time de 42,5 dias, antes de contar uma única hora ociosa dentro do desenvolvimento. Limites assim muitas vezes bastam para encerrar uma discussão.

## Tornando a espera visível

O remédio padrão é dar à espera colunas próprias, para o quadro registrá-la enquanto acontece:

- **Divida cada coluna ativa em *doing* e *done*.** *Development: done* é um item terminado pelo seu dev e esperando revisão. O tempo ali é espera, por definição, e agora o quadro o conta.
- **Faça da revisão uma coluna de fila.** *Ready for review* e *In review* separam o item que ninguém pegou daquele que está sendo lido.
- **Marque os itens bloqueados, e mantenha-os no quadro.** Um item bloqueado movido para uma lista separada deixa de contar como trabalho em andamento e deixa de envelhecer onde alguém olha. O `BIL-189` foi bloqueado exatamente assim, e a aula 3 é sobre o que isso esconde.

Cada divisão custa um pouco de disciplina e compra uma medição. Não divida tudo de uma vez: comece pela coluna cuja fila a seção anterior achou maior, que para o time de Billing em julho era a revisão.

## Um aviso sobre o número

Quando os times chegam a medir a eficiência de fluxo, o resultado costuma ser baixo o bastante para causar alarme, e o alarme costuma produzir a resposta errada: pressão para as pessoas ficarem "mais ocupadas". **A eficiência de fluxo é uma propriedade do sistema, não das pessoas.** Um dev com 100% de utilização é exatamente a pessoa diante de quem o trabalho se acumula; a aula 12 mostra a aritmética. A correção para uma eficiência de fluxo baixa é menos itens abertos e passagens mais rápidas, que é a aula 4.
