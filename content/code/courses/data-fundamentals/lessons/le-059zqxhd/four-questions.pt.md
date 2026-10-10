---
title: Quatro perguntas antes da primeira cópia
version: 1
---

**A imagem comum é que armazenamento é barato, então você coleta tudo agora e decide para que serve
depois.** Armazenamento é barato. Todo o resto em volta dele não é: cada linha coletada precisa ser
movida, conferida, guardada, lida, paga e, quando descreve uma pessoa, protegida. Coletar é a
promessa de fazer tudo isso todo dia, enquanto o dado for guardado.

O pedido de Caio mostra o formato. Na terça, ele pede a Davi as leituras dos sensores das docas: toda
doca, todo minuto, guardadas para sempre, porque o modelo de demanda dele vai querer. Parece uma
decisão só. Davi responde com quatro perguntas, e a maior parte desta aula é uma ou duas seções sobre
cada uma.

| pergunta | o que ela pergunta | para os sensores das docas | seção |
|---|---|---|---|
| **quanto?** | linhas por dia, bytes por linha, e como os dois crescem | 150 docas, uma leitura por minuto cada | 03 |
| **com que frequência?** | quão velho o dado pode estar quando alguém o lê | Caio retreina uma vez por semana | 04, 05 |
| **com que qualidade?** | o que é conferido na chegada, e contra o quê | uma leitura de uma doca que não existe | 06, 07 |
| **a que preço?** | guardar, ler, mover, chamar | a conta que um painel consegue gerar | 08 |

Por baixo das quatro há uma quinta, que não é uma pergunta técnica: **podemos ter esse dado?** Uma
leitura de sensor descreve uma doca. Uma viagem descreve uma pessoa: onde ela estava, e quando. A
seção 09 trata dessa diferença.

## Não são quatro perguntas separadas

As respostas se multiplicam. A frequência decide quantas execuções existem, e cada execução é uma
chance de falhar: uma cópia feita a cada minuto tem 1.440 delas por dia, enquanto uma cópia noturna tem
uma. O volume decide quanto cada execução move e confere. Volume vezes o tempo que se guarda vezes a
frequência com que se lê é a maior parte da conta. **Mudar uma resposta mexe nas outras três**, e é
por isso que elas são feitas juntas e antes da primeira cópia, e não uma de cada vez, conforme cada uma
vira um problema.

Nenhuma delas tem resposta certa em geral. Cada uma tem a resposta certa para uma pergunta que alguém
está fazendo, e é por isso que a primeira coisa que Davi pergunta a Caio é para que serve o modelo.
