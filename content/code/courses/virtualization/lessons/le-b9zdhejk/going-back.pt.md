---
title: Quebrando, e voltando
version: 1
---

Agora a mudança que dá errado. O arquivo é apagado, e some um programa de que o sistema precisa:

```
ana@vm1:~$ rm notes.txt; sudo mv /usr/bin/ls /usr/bin/ls.gone; ls
bash: line 1: ls: command not found
```

Um minuto depois, um comando no host:

```
ana@host:~$ virsh snapshot-revert vm1 clean
Domain snapshot clean reverted

ana@vm1:~$ cat notes.txt; ls -d /etc; date +%T
checked, all fine
/etc
20:27:08
ana@host:~$ date +%T
20:28:14
```

O `notes.txt` voltou, o `ls` voltou, e o convidado nem percebeu que algo aconteceu, porque para o
convidado nada aconteceu: ele foi posto de volta na memória e no disco do momento em que o snapshot foi
tirado.

**Incluindo o relógio.** O convidado diz 20:27:08, o host diz 20:28:14: o convidado está 66 segundos atrás,
porque retomou no momento do snapshot e não faz ideia de que o tempo passou. Um convidado com serviço de
hora pela rede se corrige em minutos. Até lá, e num snapshot da semana passada, a hora errada causa
defeitos bem reais:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha do tempo. O snapshot é tirado às 20:26:55. O convidado então é quebrado, e passa um minuto. Na reversão, o convidado volta ao momento do snapshot, memória e relógio incluídos, então alguns segundos depois o relógio dele diz 20:27:08 enquanto o do host diz 20:28:14: 66 segundos atrás.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 70 L700 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\"></path><circle cx=\"40\" cy=\"70\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"34\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">snapshot tirado</text><text x=\"34\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20:26:55</text><circle cx=\"240\" cy=\"70\" r=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"234\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o convidado é quebrado</text><circle cx=\"480\" cy=\"70\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"474\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">revertido</text><path d=\"M 474 62 C 330 10, 170 10, 48 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ck-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"480\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o relógio do convidado</text><text x=\"640\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">20:27:08</text><text x=\"480\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o relógio do host</text><text x=\"640\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20:28:14</text><text x=\"480\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">66 segundos atrás</text></svg>", "caption": "Reverter um snapshot com a máquina ligada leva o convidado de volta no tempo, relógio e tudo. Os arquivos voltam como eram, e volta também uma hora que já não é verdade."}
```

- **Logins que conferem a hora**, como o Kerberos num domínio Windows, recusam um relógio com mais de
  alguns minutos de diferença.
- **Certificados** parecem ainda não válidos, ou vencidos, aula 6 do curso de redes.
- **Uma máquina Windows num domínio pode perder a confiança com o domínio** se for revertida para antes
  de uma troca da senha da máquina, que o domínio faz todo mês. A mensagem diz que a relação de confiança
  falhou, e o conserto é juntá-la ao domínio de novo.

Então um snapshot serve para voltar **um pouco**: minutos ou dias, enquanto você testa algo. Voltar meses
é restaurar uma máquina antiga num presente que já mudou.
