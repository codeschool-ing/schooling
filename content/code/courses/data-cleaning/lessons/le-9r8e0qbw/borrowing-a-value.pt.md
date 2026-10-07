---
title: Imputar a partir de linhas parecidas
version: 1
---

**O melhor palpite para um valor que falta é o valor de linhas parecidas com a dele.** Essa é toda a
ideia da imputação além do centro: agrupar pelo que se sabe e tomar a mediana do grupo, ou o valor
da linha parecida mais próxima, ou a previsão de um modelo das outras colunas.

Funciona exatamente tão bem quanto as colunas de agrupamento preveem o valor que falta. **Para
vazios MAR, é a cura**: se os vazios dependem de uma coluna visível, preencher dentro dos grupos
dessa coluna compara iguais com iguais. A seção anterior também mostrou o limite: preencher anos de
nascimento por canal de cadastro não mudou nada, porque o canal não prevê a idade.

Três famílias, da mais simples à mais elaborada:

| método | preenche um vazio com | serve quando |
|---|---|---|
| mediana do grupo | a mediana das linhas que compartilham algumas colunas | uma ou duas colunas explicam a maior parte do valor |
| vizinhos mais próximos | os valores das *k* linhas mais parecidas | várias colunas juntas o explicam |
| baseado em modelo | uma previsão a partir das outras colunas, uma vez ou várias | a relação é forte e conhecida |

A última tem um refinamento que vale conhecer pelo nome: a **imputação múltipla** preenche cada vazio
várias vezes com valores plausíveis, roda a análise em cada cópia completada e combina os
resultados, para que a incerteza do palpite apareça nas margens de erro finais em vez de sumir. É a
resposta da estatística à dispersão encolhida da seção anterior. O `statistics` cobre a inferência
que ela alimenta; este curso para em saber quando vale o trabalho.

## Onde a imputação para

Nenhum desses métodos corrige um MNAR. Um modelo de tempos de entrega construído com os registrados
nunca viu uma entrega acima de 119 minutos, então prevê valores abaixo de 120 justamente para as
linhas que se sabe estarem acima. **A imputação toma emprestado das linhas que você tem, e MNAR quer
dizer que as linhas que você tem são as erradas para emprestar.** Os tempos de entrega pedem outro
movimento, e é o mais humilde desta aula.
