---
title: Os cabos, que é onde uma montagem de fato falha
version: 1
---

Toda peça é assentada por pressão e se segura sozinha. **Os cabos são o único passo sem
retorno**, e um conector que entrou nove décimos parece exatamente um que entrou.

## Os seis que precisam estar ligados

| | aonde vai | o que acontece se faltar |
|---|---|---|
| **ATX de 24 pinos** | o conector comprido na borda da placa | absolutamente nada acontece |
| **EPS de 8 pinos** | no canto de cima, perto do processador | as ventoinhas giram, sem imagem. O esquecimento mais comum |
| **força PCIe** | a placa de vídeo, se ela tiver soquete | ventoinhas giram, sem imagem, às vezes um LED na placa |
| **SATA, força e dados** | qualquer disco que não seja M.2 | o disco não existe |
| **painel frontal** | o bloco de pinos na borda de baixo | o botão de ligar não faz nada |
| **conectores de ventoinha** | `CPU_FAN` para o cooler, o resto em qualquer um | algumas placas se recusam a ligar sem ventoinha de CPU |

A segunda linha merece sua nota. O conector **EPS de 8 pinos** é a alimentação do próprio
processador, é separado do de 24 pinos, e fica no canto mais desconfortável do gabinete. Esquecê-lo
te dá uma máquina que acende, gira todas as ventoinhas, e não desenha nada na tela — o que parece
exatamente uma placa-mãe morta.

Ele também é o conector mais confundido com o **PCIe de 8 pinos** de uma placa de vídeo. Eles têm
formatos diferentes e não trocam de lugar, mas os cabos se parecem num feixe e as duas pontas de
uma fonte modular são rotuladas em letra miúda. **Leia o rótulo do soquete da própria fonte**,
não o do plugue.

## O painel frontal, que é a parte chata

Um blocozinho de pinos recebe cinco ou seis conectores minúsculos de dois fios:

- `PWR_SW` — o botão de ligar. **É o único que precisa estar certo para a máquina partir.**
- `RESET_SW` — o botão de reiniciar.
- `PWR_LED` — a luz de ligado. A polaridade importa: ao contrário ela simplesmente não acende.
- `HDD_LED` — a luz de atividade do disco. A mesma coisa.
- `SPEAKER` — o bipezinho, se o gabinete tiver um. **Instale.** É a diferença entre uma tela preta
  e uma tela preta com três bipes te dizendo o que está errado.

Interruptores não têm polaridade — `PWR_SW` funciona nos dois sentidos. LEDs têm. E se os pinos da
placa estiverem ilegíveis, o manual tem o diagrama, que é a razão de tê-lo aberto.

## Fontes modulares, e a regra que importa

Uma fonte modular tem cabos destacáveis, e **os cabos de uma fonte não funcionam em outra**, nem
do mesmo fabricante, nem quando o plugue encaixa. As atribuições de pinos diferem e ligá-los pode
destruir tudo que estiver conectado.

Há uma regra e ela é absoluta: **use os cabos que vieram na caixa daquela fonte.** É o único
lugar numa montagem em que algo que encaixa fisicamente pode causar dano de verdade.

## A arrumação, e quando

Faça **depois** de a máquina ter sido testada e estar rodando. Organização de cabos é inteiramente
por causa do ar e da próxima pessoa que abrir o gabinete, e passar tudo por trás da bandeja antes
de saber que a montagem funciona significa desfazer tudo para alcançar um conector.

Uma coisa vale fazer antes do teste, porém: garanta que cabo nenhum alcance uma pá de ventoinha.
Essa é a única falha que um teste de bancada encontra de forma barulhenta e cara.
