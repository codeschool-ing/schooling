---
title: Quartis
version: 1
---

Os **quartis** são os três valores que cortam os dados ordenados em quatro partes iguais.

- **Q1**, o primeiro quartil: um quarto dos dados nele ou abaixo. O percentil 25.
- **Q2**, o segundo quartil: a mediana. O percentil 50.
- **Q3**, o terceiro quartil: três quartos nele ou abaixo. O percentil 75.

## Os doze tempos de entrega

Ordenados, eles são

```localised
27,5   29,0   31,5   33,0   34,5   36,0   38,5   39,0   41,0   44,0   52,5   61,0
```

Com a regra da planilha, Q1 fica na posição 0,25 × 11 + 1 = 3,75, a três quartos do caminho de 31,5 a 33,0,
então **Q1 = 32,625**. Q3 fica na posição 9,25, a um quarto do caminho de 41,0 a 44,0, então **Q3 = 41,75**.
A mediana, como a aula 3 achou, é 37,25.

```localised
=QUARTIL.INC(A2:A13; 1)      32,625
=QUARTIL.INC(A2:A13; 3)      41,75
```

## Três regras, três respostas

Eis algo que surpreende: **existe mais de um jeito correto de calcular um quartil**, e eles dão respostas
diferentes em dados pequenos.

| método | Q1 | Q3 |
|---|---|---|
| `QUARTIL.INC`, o padrão da planilha | 32,625 | 41,75 |
| `QUARTIL.EXC`, outra opção da planilha | 31,875 | 43,25 |
| mediana de cada metade, o método usual à mão | 32,25 | 42,5 |

O método à mão divide os doze valores nos seis de baixo e nos seis de cima e tira a mediana de cada
grupo: (31,5 + 33,0) ÷ 2 = 32,25 e (41,0 + 44,0) ÷ 2 = 42,5. As duas funções da planilha interpolam com
regras de posição um pouco diferentes. Os softwares estatísticos oferecem cerca de nove variantes ao
todo.

Nenhuma está errada. Elas discordam porque um quarto de doze valores não cai exatamente sobre um valor, e
cada regra faz uma escolha diferente sobre onde, entre dois valores, o corte deve ficar. **Em dados
grandes as diferenças encolhem até sumir**; em doze valores elas são de cerca de um minuto.

A regra prática: **escolha um método e use-o do começo ao fim de um trabalho**, e ao comparar seus
quartis com os de outra pessoa, confira que método ela usou antes de concluir que os dados diferem. Este
curso usa `QUARTIL.INC` daqui em diante.
