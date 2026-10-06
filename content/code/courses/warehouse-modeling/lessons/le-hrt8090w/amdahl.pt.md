---
title: A lei de Amdahl, o limite do trabalho em paralelo
version: 1
---

Gene Amdahl formulou em 1967 o limite em que a seção anterior esbarrou. Se uma fração *p* de um trabalho
pode ser espalhada entre processadores e o resto não, então com *n* processadores o maior ganho possível
é:

```
speed-up(n) = 1 / ((1 - p) + p / n)
```

A parte que não se divide, `1 - p`, leva o mesmo tempo seja qual for *n*. Conforme *n* cresce, a parte
paralela encolhe até quase nada e só sobra a parte serial, então o ganho nunca passa de `1 / (1 - p)`.

Calculado para um trabalho 90% paralelo:

| processadores | ganho |
|---|---|
| 1 | 1,0 |
| 2 | 1,8 |
| 4 | 3,1 |
| 16 | 6,4 |
| quantos quiser | no máximo 10 |

**Dez é o teto, e dezesseis processadores já alcançam dois terços dele.** Cada processador além disso
compra menos que o anterior. Para um trabalho 99% paralelo o teto é 100; para um 50% paralelo, é 2.

Duas lições para warehouses decorrem disso:

- **A escala vertical tem retornos decrescentes dentro de uma consulta**, e por isso as quatro threads da
  seção 03 deram menos que quatro vezes a velocidade.
- **A escala horizontal tem a mesma lei e mais uma parte serial**: mover dados entre máquinas e combinar
  as respostas delas. Uma consulta distribuída cujas máquinas passam metade do tempo trocando linhas tem
  *p* bem abaixo de 1, com quantas máquinas tiver. As seções 07 a 09 são sobre manter essa troca pequena.

A lei de Amdahl é sobre um trabalho. Um warehouse também roda muitas consultas ao mesmo tempo, e doze
analistas rodando doze consultas em doze máquinas podem ter cada um uma máquina inteira. Esse tipo de
escala, mais usuários em vez de consultas individuais mais rápidas, é o que a escala horizontal faz
melhor, e a seção 11 volta a ele.
