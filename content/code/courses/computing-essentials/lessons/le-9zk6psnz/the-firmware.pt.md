---
title: O firmware, onde dois ajustes importam e trinta não
version: 1
---

A tela que você alcança apertando `Del` ou `F2` na ligação é o **firmware** — `UEFI` em qualquer
coisa moderna, `BIOS` em qualquer coisa mais velha e no vocabulário da maioria das pessoas de
qualquer jeito. É um programa pequeno na placa-mãe que roda antes de qualquer sistema operacional
existir.

Ele tem uma centena de ajustes. Dois valem mudar numa montagem nova, um vale conferir, e o resto
é para quem está resolvendo um problema específico.

## O que é desempenho de graça

**`XMP`, ou `EXPO` em placas AMD.** A memória sai de fábrica rodando numa velocidade conservadora
que toda placa garante dar conta — normalmente `2133` ou `2400 MHz` — independentemente do que
foi vendido. Os `3600 MHz` da caixa são um *perfil* guardado dentro do módulo, e a placa não o usa
até você mandar.

Um ajuste, um reinício, e a memória roda na velocidade que você pagou. **Deixar isso desligado é
o jeito mais comum de uma montagem nova ser mais lenta do que deveria**, e nada em lugar nenhum
reporta — a máquina funciona perfeitamente, um pouco mais devagar, para sempre.

Espere o liga-desliga-liga de dois segundos enquanto a placa retreina.

## O que não é opcional

**A ordem de partida**, que decide de onde a máquina tenta iniciar. Para a instalação você precisa
do pendrive primeiro; depois, do disco interno. A maioria das placas também tem um menu de
partida avulso no `F11` ou `F12`, que é melhor que mudar o ajuste duas vezes.

## O que conferir em vez de mudar

**A data e a hora.** Uma placa com a pilha-moeda vazia as esquece, e o sintoma não é um relógio
errado — é **páginas se recusando a carregar com erro de certificado**, porque certificados têm
datas e a máquina acha que está em 2015. É uma hora confusa, e a cura é uma `CR2032` que custa
quase nada.

## Curvas de ventoinha, em resumo

O firmware decide a que velocidade cada ventoinha gira em cada temperatura. Os padrões são
agressivos, porque um fabricante prefere ser barulhento a ser culpado por calor.

Uma curva mais suave — ventoinhas paradas abaixo de uns `50 °C`, subindo a partir dali — deixa uma
máquina muito mais silenciosa e custa alguns graus que ninguém percebe. Esse é o único lugar em
que mexer compensa, e é reversível.

## No que não mexer

- **Tensões.** O lugar em que um número errado causa dano permanente, e o único desta lista.
- **Secure Boot**, a menos que algo precise dele desligado. Deixe ligado; o Windows espera por ele
  e o Linux já lida bem.
- **Overclock.** Um assunto à parte com um modo de falha à parte. Os ajustes de fábrica são
  aquilo em que tudo foi testado.
- **Qualquer coisa que você não saiba nomear.** Um firmware cheio de mudanças de que ninguém se
  lembra é a razão de *limpe os ajustes* estar na lista da tela preta.

## Atualizá-lo

Uma atualização de firmware conserta compatibilidade — um processador mais novo que a placa, um
kit de memória que ela não reconhece — e é a única tarefa de manutenção que pode **matar a placa**
se a energia cair no meio.

Então: atualize se tiver um motivo, não atualize se não tiver, e nunca durante uma tempestade.
Muitas placas conseguem gravar a partir de um pendrive sem processador instalado, que é o recurso
que salva uma montagem em que a placa é mais velha que o chip.
