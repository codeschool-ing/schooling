---
title: O que o sistema lembra
version: 1
---

O sistema guarda o próprio relato do que aconteceu, e ele não depende da memória de ninguém:

```
ana@pc1:~$ sudo lpstat -W completed -o
pdf-4                   bruno             1024   Sat Sep 26 00:29:21 2026
office-3                ana               1024   Sat Sep 26 00:29:16 2026
pdf-1                   bruno             1024   Sat Sep 26 00:29:14 2026
pdf-2                   bruno             1024   Sat Sep 26 00:29:14 2026
ana@pc1:~$ sudo cat /home/bruno/.cups/lpoptions; sudo stat -c "%y" /home/bruno/.cups/lpoptions
Default pdf
2026-09-26 00:29:13.903412990 -0300
```

- Todo trabalho que o Bruno mandou foi para `pdf`, e o único trabalho em `office` é a página de teste da
  técnica.
- O arquivo `~/.cups/lpoptions` dele tem uma linha, `Default pdf`, gravada às **00:29**, o momento em que
  os trabalhos começaram a ir para o lugar errado.

Essa hora vale mais que a configuração. Ela bate com o que o Bruno disse quando perguntado o que estava
fazendo: salvando um PDF e fechando uma janela. **Uma hora dos logs e uma hora do usuário que concordam**
transformam uma teoria num achado.

O `sudo` foi necessário para ver os donos. Sem ele, o `lpstat` mostra os trabalhos de outras pessoas como
`unknown`, porque quem imprimiu o quê é privado. A aula 13 volta ao que um técnico consegue ver e ao que
ele faz com isso.
