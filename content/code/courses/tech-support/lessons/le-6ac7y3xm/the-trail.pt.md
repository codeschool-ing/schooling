---
title: O computador anota
version: 1
---

Cada comando desta aula que passou pelo `sudo` deixou uma linha no journal do sistema, o registro da aula 10.
O `grep` separa os quatro citados acima:

```
ana@pc1:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep -E "COMMAND=/usr/bin/(ls|lpstat|cmp)"
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/ls /home/elisa
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/lpstat -W completed -o
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/ls -l /var/spool/cups
     ana : PWD=/home/ana ; USER=root ; COMMAND=/usr/bin/cmp /var/spool/cups/d00001-001 /home/elisa/letter-to-doctor.txt
```

O journal diz a conta, a pasta onde ela estava e o comando exato, e fez isso para todos eles, inclusive a
listagem da pasta da Elisa. Quem ler esse journal depois, numa auditoria, numa reclamação ou numa
investigação, vê o que a técnica olhou, no nome da própria técnica.

O registro vale para os dois lados. **Para um técnico que ficou dentro do chamado, é uma defesa**: mostra que
ele fez o que o trabalho pedia e nada mais. Para um que foi procurar, é a evidência. Nos dois casos, a
atitude certa é trabalhar como se cada comando fosse ser lido depois pela pessoa dona do computador, porque
pode ser.
