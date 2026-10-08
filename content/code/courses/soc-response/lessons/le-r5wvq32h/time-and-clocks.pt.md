---
title: Hora, fusos e relógios
version: 1
---

Uma investigação é uma linha do tempo, e uma linha do tempo montada com registros que discordam sobre a
hora é ficção. Três coisas dão errado, e cada uma tem uma prevenção barata.

**O fuso.** A máquina em que este curso foi gravado roda no horário de São Paulo, três horas atrás do UTC:

```
root@soc:~# date
Wed Oct  7 04:34:57 -03 2026
root@soc:~# date -u
Wed Oct  7 07:34:57 UTC 2026
root@soc:~# date -d '2026-09-17T02:33:07-03:00' -u
Thu Sep 17 05:33:07 UTC 2026
root@soc:~# date -d 'Sep 17 02:33:07'
Thu Sep 17 02:33:07 -03 2026
```

O terceiro comando pega um carimbo escrito com o deslocamento, `-03:00`, e o converte para UTC sem
ambiguidade: **05:33:07**. O quarto pega o mesmo momento escrito do jeito antigo do syslog, como o
`fw.log` o escreve na aula 1, sem ano e sem fuso. O `date` preencheu as duas lacunas com a máquina em que
rodou: o ano **2026** e o fuso `-03`. Aqui o palpite acerta. Lido numa máquina em UTC, erraria por três
horas; lido em janeiro sobre uma noite de dezembro, erraria por um ano. **Um registro sem fuso é lido no
fuso de quem lê**, e ninguém percebe.

**O relógio.** Duas máquinas cujos relógios diferem em quarenta segundos põem o login de um invasor numa
delas depois da cópia de arquivo que ele causou na outra. Toda máquina de um parque sincroniza com a mesma
fonte de hora por NTP: no Ubuntu, `systemd-timesyncd` ou `chrony`, conferidos com `timedatectl` (não
rodado aqui, pelo mesmo motivo do `journalctl`). Um SIEM que registra tanto a hora em que o evento diz ter
acontecido quanto a hora em que o recebeu consegue mostrar o desvio; a diferença entre esses dois campos
merece um painel só para ela.

**A precisão.** A aula 1 já esbarrou nisso: o `ts` carimba ao segundo, o `tcpdump` ao microssegundo, o
rsyslog ao microssegundo com o deslocamento. Juntar um registro de um segundo com um de microssegundo é
juntar com uma janela, não com um ponto.

A regra que sai disso é simples de dizer. **Guarde e compare em UTC; mostre no horário local; nunca aceite
um registro sem deslocamento se puder configurá-lo para trazer um.** O Windows já guarda em UTC. O rsyslog
do Ubuntu 24.04 já escreve o deslocamento. Equipamentos de rede são onde o formato antigo sobrevive por
mais tempo, e uma linha dizendo `Sep 17 02:33:07` é uma linha que alguém precisa anotar à mão com o fuso
do aparelho que a escreveu, exatamente o tipo de passo que se pula às três da manhã.
