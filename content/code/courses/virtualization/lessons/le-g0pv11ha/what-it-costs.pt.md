---
title: Para que serve, e quanto custa
version: 1
---

Para que um técnico de suporte usa máquinas virtuais, na ordem em que você deve encontrá-las:

- **Um lugar para testar.** Uma atualização, uma versão nova de um programa, uma configuração de que
  você não tem certeza: primeiro num convidado, depois no computador do cliente.
- **Outro sistema operacional.** Um convidado Windows num laptop Linux, ou o contrário, para seguir os
  passos de um cliente no sistema que ele tem de fato.
- **Um laboratório.** Um cliente, um servidor e algo para atacar ou consertar, num computador só, numa
  rede só deles. As aulas 14 e 15 montam um, e os cursos depois deste o usam.
- **Software antigo.** Um programa que só roda num sistema antigo continua rodando num convidado desse
  sistema depois que o último computador de verdade que o rodava já se foi.
- **Voltar atrás.** Um snapshot, aula 9, salva o estado de um convidado e volta a ele em segundos, e é
  isso que torna barato quebrar coisas de propósito.

Nada disso é de graça. **Tudo o que um convidado tem, o host deixa de ter.** O convidado de 1 GiB daqui
custou ao host cerca de 1,5 GiB enquanto rodava. Os dois processadores dele são
tempo tirado dos 4 do host, e cinco convidados ocupados em quatro processadores esperam a vez. O
disco dele cresce conforme ele escreve, e dez sobreposições numa base podem encher o disco de um host
devagar, onde ninguém está olhando. E um convidado é mais lento que o host em tudo o que passa pelo
hypervisor: um pouco mais lento com a ajuda do processador, bem mais lento sem ela, como no computador
em que este curso foi gravado. As aulas 2 e 8 medem quanto.

A regra prática que sai disso: **dê a um convidado o que o trabalho dele precisa, não o que o host
consegue ceder**, e desligue os que você não está usando.
