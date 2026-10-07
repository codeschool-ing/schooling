---
title: Quão cheio está o disco, e com o quê?
version: 2
---

Duas perguntas diferentes, e cada uma tem o seu comando. A segunda precisa de uma pasta para medir. A
aula 12 deixou uma pasta `work` na sua pasta pessoal; isto a troca por quatro arquivos pequenos e um de
3 MB, só zeros, no lugar de um documento escaneado, com as mesmas datas daqui:

```sh
rm -rf ~/work && mkdir -p ~/work/invoices ~/work/reports
printf 'id,name,city\n1,Acme Ltd,Sao Paulo\n2,Bravo & Filhos,Campinas\n' > ~/work/clients.csv
printf 'Invoice 104 for Acme Ltd\n' > ~/work/invoices/104.txt
printf 'Q3 summary, Bravo & Filhos\n' > ~/work/reports/q3.txt
head -c 3000000 /dev/zero > ~/work/reports/scan.pdf
find ~/work -exec touch -h -d '2026-09-01 09:00' {} +
```

```
ana@server:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   14G   25G  36% /
ana@server:~$ du -sh work
2.9M    work
ana@server:~$ du -sh work/*
4.0K    work/clients.csv
8.0K    work/invoices
2.9M    work/reports
PS /home/ana> Get-PSDrive -PSProvider FileSystem | Select-Object Name, Root

Name Root
---- ----
/    /
Temp /tmp/

PS /home/ana> (Get-ChildItem work -Recurse -File | Measure-Object -Property Length -Sum).Sum
3000112
```

- O `df -h` responde **quão cheio está o disco**, por sistema de arquivos: tamanho, usado,
  disponível e a porcentagem. O `-h` são os tamanhos *humanos* da aula 8.
- O `du -sh` responde **o que está ocupando o espaço**, por pasta: `work` tem 2.9 MB, e o segundo
  comando mostra que quase tudo é `reports`. O `-s` dá um total por argumento em vez de cada subpasta.
- O `Get-PSDrive` do PowerShell lista as unidades; no Linux há uma, `/`, mais a `Temp`. No Windows
  ele lista `C:`, `D:` e as outras com o espaço usado e livre. **Somar o `Length`** de todo arquivo é o
  `du` do PowerShell: 3000112 bytes, os mesmos 2.9 MB.

A ordem importa na prática: *o `df` primeiro* para ver qual disco está cheio, *depois o `du`* nesse
disco, descendo a cada vez para a pasta maior.

```sh
Get-Volume                                   # every volume, size and free space
Get-PSDrive C                                # used and free on C:
(Get-ChildItem C:\Users\ana\Documents -Recurse -File | Measure-Object Length -Sum).Sum
```

No Mac, o `df -h` e o `du -sh` são os mesmos comandos, e o *Sobre Este Mac > Armazenamento* é o desenho
dos mesmos números.
