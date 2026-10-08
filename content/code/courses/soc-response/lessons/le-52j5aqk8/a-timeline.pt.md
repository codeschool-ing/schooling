---
title: Uma linha do tempo a partir do sistema de arquivos
version: 1
---

Todo inode carrega horários, e juntos eles são uma **linha do tempo** do disco: o que foi criado, mudado, lido e
apagado, e em que ordem. O TSK a constrói em dois passos. O `fls -m` escreve todo nome com seus horários num
formato simples chamado **body file**; o `mactime` ordena o body file numa linha do tempo. `-d` separa os campos
com vírgulas, `-y` escreve datas ISO, e `-z UTC` põe todos os horários num fuso só, como a aula 12 insiste:

```
root@soc:~/case# fls -r -m / work.dd > body.txt
root@soc:~/case# mactime -b body.txt -d -y -z UTC 2>/dev/null | grep -E '^Date|exports'
Date,Size,Type,Mode,UID,GID,Meta,File Name
2026-10-08T00:05:18Z,4096,macb,d/drwxr-xr-x,0,0,23,"/exports"
2026-10-08T00:05:18Z,313,macb,r/rrw-r--r--,0,0,24,"/exports/contacts-2026-08.csv (deleted)"
```

A coluna `Type` traz as letras **m**, **a**, **c** e **b**: o conteúdo do arquivo foi **m**odificado, ele foi
**a**cessado, o inode dele foi alterado (**c**hanged), e ele nasceu (**b**orn), foi criado. Aqui as quatro
aconteceram no mesmo segundo, porque o disco inteiro foi feito de uma vez e o arquivo apagado logo depois; a
última linha diz `(deleted)`.

Num servidor de verdade a linha do tempo é longa, e é dela que vêm os achados: um arquivo lido às 02:39 de quinta,
dois minutos antes da transferência na linha do tempo da aula 12, é candidato ao que saiu. Dois cuidados vêm
junto. **Horários de acesso muitas vezes não são atualizados** no Linux moderno, para economizar escritas, então
um `a` pode ser mais antigo que a última leitura de verdade. E **horários podem ser mudados** por qualquer pessoa
com acesso suficiente ao servidor; uma linha do tempo é forte quando concorda com fontes que o invasor não
controlava, como o firewall e os registros de fluxo.
