---
title: Seguindo
version: 1
---

O mesmo runbook, seguido no `pc1`, onde as duas faturas da Elisa estão presas. Passo 1:

```
ana@pc1:~$ lpstat -p office
printer office disabled since Sat Sep 26 01:15:43 2026 -
        paper jam, tray 2
```

`disabled`, com o motivo `paper jam, tray 2`: este runbook se aplica. Passo 2:

```
ana@pc1:~$ lpstat -o office
office-1                unknown           1024   Sat Sep 26 01:15:44 2026
office-2                unknown           1024   Sat Sep 26 01:15:44 2026
```

Dois trabalhos esperando. Os donos aparecem como `unknown` porque quem imprimiu o quê é privado sem
`sudo`, aula 2; a contagem é o que este passo precisa. O passo 3 é uma conversa, não um comando: alguém
perto da impressora tira o papel preso e avisa. Passo 4:

```
ana@pc1:~$ sudo cupsenable office && sleep 3 && lpstat -p office
printer office is idle.  enabled since Sat Sep 26 01:15:50 2026
```

`idle` e `enabled`. Passo 5:

```
ana@pc1:~$ lpstat -o office | wc -l; sudo lpstat -W completed -o office | head -3
0
office-1                elisa             1024   Sat Sep 26 01:15:50 2026
office-2                elisa             1024   Sat Sep 26 01:15:50 2026
```

**0** trabalhos esperando, e as duas faturas, da Elisa, concluídas. O runbook disse o que cada passo
deveria mostrar, então em cada passo havia um jeito de saber que tinha funcionado, e um lugar para parar
se não tivesse.
