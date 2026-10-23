---
title: Linha de base, alvo e a lacuna entre eles
version: 1
---

**As fases B, C e D descrevem, cada uma, duas arquiteturas, a linha de base como ela é agora e o
alvo como deveria ser, e o trabalho é definido pela lacuna entre as duas.** A técnica do TOGAF para
achar essa lacuna de forma sistemática é a **matriz de análise de lacunas**, e ela é uma das partes
do framework que valem a pena mesmo numa empresa que não use mais nada dele.

## A matriz

Ponha os blocos de construção da linha de base nas linhas e os do alvo nas colunas. Cada célula em
que uma linha e uma coluna são a mesma coisa é **mantida**. Uma linha da linha de base sem par no
alvo é **eliminada**; uma coluna do alvo sem par na linha de base é **nova**. O domínio de aplicação
do programa da Carcará:

| linha de base ↓ · alvo → | ticketing | app web do passageiro, com modo balcão | app de embarque, lendo QR em papel | *eliminado* |
| --- | --- | --- | --- | --- |
| **ticketing** | mantido | | | |
| **app web do passageiro** | | mudou: modo balcão | | |
| **app de embarque** | | | mudou: lê QR em papel | |
| **back office das rodoviárias** | | | | **eliminado: de propósito?** |
| **módulo de impressão de recibo das rodoviárias** | | | | **eliminado: de propósito?** |
| ***novo*** | | | | |

## A pergunta da última coluna

O valor real da matriz é a pergunta que ela impõe a cada item eliminado: **ele foi eliminado de
propósito, ou o alvo o esqueceu?** A orientação do TOGAF é verificar um por um, porque uma
eliminação acidental é uma capacidade que o negócio perde sem ninguém ter decidido isso.

No back office das rodoviárias, a verificação achou duas capacidades assim:

- **reembolsos em dinheiro no balcão**, que os stakeholders da aula 7 já tinham mostrado serem
  invisíveis em outros lugares. O alvo não tinha lugar para eles; foram acrescentados ao modo balcão.
- **o relatório de caixa do fim do dia** que cada atendente imprime para o gerente da rodoviária.
  Ninguém tinha falado dele, porque ele rodava sozinho na hora de fechar. Também virou requisito do
  modo balcão.

Já o módulo de impressão de recibo foi eliminado de propósito: a impressão passa para o modo balcão,
que imprime o recibo com QR.

## Arquiteturas de transição

Quando a lacuna é grande demais para fechar de uma vez, o plano define **arquiteturas de transição**:
estados intermediários, cada um estável e utilizável por si só. As três da Carcará foram as
rodoviárias piloto, as linhas do litoral e o resto. Cada arquitetura de transição é uma descrição
completa por direito próprio: no fim do primeiro trimestre, duas rodoviárias rodam o alvo e vinte e
quatro rodam a linha de base, e **as duas precisam funcionar**, inclusive para um passageiro que
compra numa rodoviária piloto e embarca em outra.

Essa última frase é o que as arquiteturas de transição existem para pegar: **os estados do meio
também são arquiteturas**, muitas vezes as mais complicadas, e são as que ninguém desenha a menos que
um método obrigue.
