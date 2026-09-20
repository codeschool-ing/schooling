---
title: O primeiro dia, que é quando uma máquina ganha os hábitos dela
version: 1
---

A montagem acaba quando o sistema operacional está instalado e a máquina está fazendo o serviço
para o qual foi comprada. Isso são mais duas horas, e a maior parte é espera.

## Fazer o instalador

Você precisa de um pendrive de `8 GB` ou mais e de uma ferramenta que grave o instalador nele. O
Windows tem a *Media Creation Tool*; para qualquer outra coisa, `Rufus` ou `balenaEtcher` ou o
comando `dd`. **Copiar os arquivos para o pendrive não funciona** — ele precisa ser tornado
inicializável, que é o que essas ferramentas fazem.

O pendrive é apagado no processo. Essa frase está aqui porque é o único passo desta aula que
destrói alguma coisa.

## Particionamento, num parágrafo

O instalador vai oferecer usar o disco inteiro, e numa montagem nova com um disco, **deixe.** Os
instaladores modernos criam as três ou quatro partições de que um sistema precisa — uma partição
de partida, o sistema e uma área de recuperação — e fazer isso à mão é um jeito de errar.

A única decisão que vale tomar: **se há dois discos, instale o sistema no rápido** e guarde o
grande para arquivos. Um NVMe de `500 GB` para o sistema e um disco de `2 TB` para o resto é o
arranjo que envelhece melhor.

## Drivers, e o que mudou

O ritual antigo era um disco de drivers e uma tarde. Hoje uma instalação atual de Windows ou de
Linux chega com quase tudo funcionando, e há exatamente dois para buscar à mão:

- **o driver de vídeo**, no fabricante da placa e não no serviço de atualização, porque é o que é
  genuinamente mais novo e genuinamente importa;
- **o driver de chipset**, na página da própria placa-mãe, que afeta sobretudo gerenciamento de
  energia e vale dez minutos.

Todo o resto — rede, som, armazenamento — funciona de saída, e uma máquina que veio com um disco
de drivers é uma máquina cujos drivers têm três anos.

## A lista do primeiro dia

| | por que agora |
|---|---|
| **rode todas as atualizações** | serão várias rodadas, e elas pedem reinícios |
| **ligue a criptografia do disco** | é de graça neste ponto e é um projeto depois |
| **crie uma segunda conta, sem administrador**, para o dia a dia | quase todo dano precisa de direitos de administrador |
| **arme o backup antes de haver o que perder** | veja abaixo |
| **anote a ficha técnica da máquina** | você vai precisar e não vai lembrar |
| **anote a data** | garantias começam agora, e uma montagem não tem nota fiscal do conjunto |

## A que não é opcional

**Arme o backup hoje.** Não quando houver algo na máquina que valha guardar — hoje, com a máquina
vazia e o serviço levando dez minutos.

A razão não é diligência. É que **um backup arranjado depois é um backup arranjado depois da
primeira coisa que você teria querido de volta**, e toda pessoa que já perdeu algo armou o dela na
semana seguinte. Um disco externo e a ferramenta do próprio sistema bastam; qualquer coisa
automática ganha de qualquer coisa melhor que seja feita à mão.

É essa a montagem inteira. A máquina à sua frente são as quatro partes da aula um, as três da aula
dois, os periféricos da aula três, espetados nas portas da aula quatro, e metade dela está
conversando pelos rádios da aula cinco.
