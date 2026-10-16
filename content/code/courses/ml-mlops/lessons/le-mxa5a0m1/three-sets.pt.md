---
title: Três conjuntos, e para que serve cada um
version: 1
---

O `overfit.py` usou três cortes para três trabalhos, e **o que importa são os trabalhos, não os
nomes.**

| conjunto | no overfit.py | para que serve | quantas vezes é olhado |
| --- | --- | --- | --- |
| **treino** | 31 de agosto de 2025 | as linhas que o `fit` lê | toda vez que um modelo é ajustado |
| **validação** | 30 de setembro de 2025 | escolher entre modelos: qual profundidade, quais atributos, qual algoritmo | quantas vezes você quiser |
| **teste** | 30 de novembro de 2025 | uma estimativa honesta do modelo escolhido | **uma vez**, no fim |

**A validação existe porque escolher é um tipo de aprendizado.** Seis profundidades foram testadas
e ficou a de melhor nota na validação. Essa escolha usou as linhas de validação, então a nota delas
para o vencedor, 0,762, é um pouco lisonjeira: com tentativas suficientes, uma delas vai bem em parte
por sorte. As linhas de teste não participaram de escolha nenhuma, então 0,769 é o número a relatar.

**Um conjunto de teste olhado duas vezes é um conjunto de validação.** Se a nota de teste tivesse
decepcionado e alguém tivesse testado a profundidade 6 e conferido de novo, as linhas de teste
passariam a fazer parte da escolha, e não sobraria número honesto nenhum. Numa plataforma isso é uma
regra de processo tanto quanto técnica: as linhas de teste ficam onde os jobs de treino não as leem,
e a nota nelas é calculada pela etapa de publicação, não por quem está ajustando.

## Qual o tamanho de cada um

Não há regra que valha decorar. Duas coisas decidem na prática. O **conjunto de teste precisa ser
grande o bastante para que a nota não seja sorte**: 3.130 membros, 530 deles afastados, bastam para
distinguir 0,76 de 0,79; cinquenta membros não bastariam. E para dados que se movem com o tempo, como
estes, os conjuntos **não são escolhidos pelo tamanho, e sim pela data**, que é a seção 07.

**Validação cruzada** (*cross-validation*) é o nome de repetir a divisão várias vezes em fatias
diferentes e tirar a média, comum quando há poucas linhas. Ela responde a mesma pergunta com menos
ruído, e tem a mesma fraqueza que a seção 06 mostra para qualquer divisão que ignora quem e quando.
