---
title: Encontrando o privilégio que ninguém usa
version: 1
---

Um conjunto de regras se acumula. Depois de um ano, algumas regras concedem acesso que ninguém usa
mais, e algumas concedem mais do que alguém usa. O privilégio mínimo precisa de um jeito de encontrar
as duas, e o firewall já coleta a evidência: os **contadores**.

O método é simples. Dê um contador a cada `accept`, como a aula 1 fez, e leia-os ao longo de um
período longo o bastante para incluir todo uso legítimo: um mês cobre a maioria das empresas, um
trimestre cobre os relatórios que rodam no fechamento do trimestre. Depois separe as regras em três
grupos:

| contador ao fim do período | o que ele sugere | o que fazer |
|---|---|---|
| zero | o acesso não é usado, ou está sombreado (aula 18) | encontre o dono; remova-o, ou agende sua expiração |
| baixo e de poucas origens | a regra é mais larga que o seu uso | estreite-a para essas origens e portas |
| alto | o acesso está em uso | mantenha-o, e confira se ele ainda corresponde ao seu comentário |

Os registros de fluxo (*flow records*, aula 23) afinam a segunda linha: eles dizem não só quantos
pacotes uma regra permitiu, mas **quais pares de máquinas** a usaram, que é exatamente o que uma
regra mais estreita precisa nomear.

**Toda remoção é testada antes de se tornar permanente.** A sequência mais segura é a que a aula 5
montou para qualquer mudança: remova a regra com um caminho de volta agendado, rode o teste da matriz
da aula 18 e fique atento à reclamação. Um acesso de cuja perda ninguém reclama dentro do período não era
necessário.

A revisão em si é uma tarefa recorrente, não um projeto. Regras são baratas de adicionar com pressa e
caras de remover sem evidência, então a evidência precisa ser coletada continuamente, e os contadores
já estão fazendo isso.
