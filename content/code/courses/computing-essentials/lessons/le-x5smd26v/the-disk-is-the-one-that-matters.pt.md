---
title: O disco, que é a única peça que leva o seu trabalho junto
version: 1
---

Todo outro componente desta aula pode ser trocado e você não perde nada além de dinheiro. O disco é
diferente, e essa diferença decide como se comportar no instante em que ele vira suspeito.

## Dois tipos, dois jeitos de falhar

**Um disco rígido é uma máquina**: um prato girando, uma cabeça num braço se movendo sobre ele. Ele
falha mecanicamente, fica mais lento primeiro, e **em geral faz barulho** — um clique ritmado, um
tique, um ranger. Esse barulho é a cabeça falhando em achar o lugar dela e tentando de novo.

**Um disco de estado sólido não tem peça móvel.** Ele é silencioso, não fica lento aos poucos do
mesmo jeito, e tende a falhar de forma mais repentina — muitas vezes ficando somente-leitura, ou
sumindo entre um início e o outro. É mais confiável em geral e menos educado no fim.

## Os sintomas, na ordem em que costumam chegar

- **Arquivos que demoram demais para abrir**, um arquivo em particular, vezes seguidas. O disco
  está tentando de novo numa região que não consegue ler.
- **A máquina inteira congelando por segundos**, com todo o resto normal — uma pausa, e volta. É a
  máquina esperando uma leitura.
- **Um arquivo que não copia**, com um erro no meio do caminho, sendo que o mesmo arquivo copiava
  bem mês passado.
- **Uma mensagem sobre o sistema de arquivos sendo reparado** na inicialização, mais de uma vez.
- **O disco não sendo encontrado**, em alguns inícios e em outros não.

## SMART, que é a opinião do próprio disco

Discos guardam contadores de saúde próprios — setores realocados, setores pendentes, erros de
leitura, horas ligado — e os reportam sob o nome **SMART**. Todo sistema consegue lê-los, e
ferramentas gratuitas os mostram com clareza.

Duas coisas sobre esse número:

- **Um aviso do SMART é um ótimo motivo para agir.** Setores realocados que só aumentam querem
  dizer que o disco está ficando sem lugares reservas para pôr os seus dados.
- **SMART passando não é atestado de saúde.** Uma parcela significativa dos discos falha com o
  SMART não relatando nada de errado, porque ele só conhece as falhas que ele conta.

Então é prova numa direção só: um aviso quer dizer acredite, silêncio não quer dizer nada.

## O que fazer, na ordem certa

**Copie os seus arquivos primeiro. Antes de testar, antes de diagnosticar, antes de tudo.**

Este é o único lugar deste curso em que a ordem não é preferência. Um disco que começou a falhar
tem um número de leituras restantes e ninguém sabe qual é esse número. Todo teste que você roda
gasta algumas. Um disco que sobrevive a uma cópia completa pode não sobreviver a uma tarde sendo
investigado.

Então: copie, para algo que não seja aquele disco. Depois diagnostique, com calma, numa máquina
cuja falha agora custa só dinheiro.

E depois, a conclusão honesta: **um disco que começou a falhar é trocado, não consertado.** Setores
ruins podem ser marcados e contornados, e isso compra tempo em vez de saúde.
