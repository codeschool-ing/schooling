---
title: O que uma placa de vídeo faz de fato
version: 1
---

Um processador é feito para fazer uma coisa complicada depois da outra, muito rápido. Um
**processador gráfico** é feito para o contrário: a mesma coisa simples em um milhão de dados ao
mesmo tempo.

É essa a diferença inteira, e toda consequência sai dela.

Uma tela de 1920×1080 tem uns dois milhões de pixels. Sessenta vezes por segundo, alguma coisa
precisa decidir uma cor para cada um. As decisões são quase idênticas e não dependem umas das
outras — que é exatamente o trabalho em que uma CPU é ruim e uma GPU é boa.

| | processador | processador gráfico |
|---|---|---|
| núcleos | 6 a 16, complicados | milhares, simples |
| bom em | uma coisa difícil de cada vez | uma coisa fácil, em todo lugar |
| ruim em | um milhão de tarefas iguais | qualquer coisa com decisão dentro |

## E é por isso que deixou de ser sobre gráficos

O nome hoje está metade errado. "A mesma operação simples sobre um arranjo enorme" descreve
desenhar um quadro, e também descreve treinar uma rede neural, multiplicar matrizes grandes e
minerar criptomoeda. Uma placa de vídeo é uma máquina de fazer aritmética a granel, e imagens
foram só a primeira coisa que alguém quis a granel.

## VRAM, e por que ela é citada em separado

Uma placa de vídeo carrega a memória dela — a **VRAM** — porque precisa das texturas e do quadro
que está montando bem ao lado daqueles milhares de núcleos. Ir buscar na memória principal da
máquina poria o passo de dois minutos da aula passada no meio de cada quadro.

Quando uma placa é descrita como `8 GB`, essa é a memória dela e não tem nada a ver com os
`16 GB` do resto da ficha. Ficar sem ela não deixa a placa lentamente mais lenta: ela cai para a
memória principal, e a taxa de quadros despenca.
