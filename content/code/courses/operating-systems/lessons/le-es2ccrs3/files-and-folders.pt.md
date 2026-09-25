---
title: O que cada letra permite, num arquivo e numa pasta
version: 1
---

As mesmas três letras querem dizer coisas diferentes num arquivo e numa pasta, e a diferença explica a
maior parte dos enigmas de permissão.

| | num arquivo | numa pasta |
|---|---|---|
| `r` | ler o conteúdo | listar os nomes dentro |
| `w` | mudar o conteúdo | criar, renomear e **apagar** nomes dentro |
| `x` | executar como programa | **entrar** nela, e alcançar qualquer coisa dentro |

## Tirando a leitura

```
ana@server:/srv/office$ sudo -u bruno cat payroll.txt
salaries
ana@server:/srv/office$ chmod o-r payroll.txt
ana@server:/srv/office$ ls -l payroll.txt
-rw-r----- 1 ana ana 9 Sep  1 09:00 payroll.txt
ana@server:/srv/office$ sudo -u bruno cat payroll.txt
cat: payroll.txt: Permission denied
```

O `o-r` tirou a leitura dos **o**utros (*others*). O `cat` seguinte como bruno foi recusado, que é o
problema do estagiário resolvido para este arquivo.

## Uma pasta sem x

```
ana@server:/srv/office$ chmod o-x reports
ana@server:/srv/office$ ls -ld reports
drwxr-xr-- 2 ana ana 4096 Sep  1 09:00 reports
ana@server:/srv/office$ sudo -u bruno ls reports
q3.txt
ana@server:/srv/office$ sudo -u bruno cat reports/q3.txt
cat: reports/q3.txt: Permission denied
ana@server:/srv/office$ chmod o+x reports
```

Com `r` e sem `x` para os outros, o bruno *conseguiu listar os nomes* em `reports` e **não conseguiu
abrir o arquivo de dentro**, embora o próprio `q3.txt` seja legível por todos. Para alcançar qualquer
coisa numa pasta você precisa de `x` nela, e em toda pasta acima. É também por isso que as pastas
pessoais do Ubuntu deixam os outros de fora: sem `x` em `/home/ana`, nada lá dentro é alcançável, digam
o que disserem as permissões de cada coisa.

## Apagar é assunto da pasta

```
ana@server:/srv/office$ mkdir drop && chmod 777 drop
ana@server:/srv/office$ printf "draft\n" > drop/plan.txt && chmod 444 drop/plan.txt
ana@server:/srv/office$ ls -l drop
total 4
-r--r--r-- 1 ana ana 6 Sep 25 10:53 plan.txt
ana@server:/srv/office$ sudo -u bruno sh -c "echo change >> drop/plan.txt"
sh: 1: cannot create drop/plan.txt: Permission denied
ana@server:/srv/office$ sudo -u bruno rm -f drop/plan.txt
ana@server:/srv/office$ ls -l drop
total 0
ana@server:/srv/office$ ls -ld /tmp
drwxrwxrwt 9 root root 180 Sep 25 10:49 /tmp
```

O `plan.txt` era **só de leitura para todos**, e o bruno não conseguiu mudá-lo. Ele **o apagou assim
mesmo**, porque apagar um nome é uma mudança na pasta, e a pasta `drop` podia ser gravada por todos.

**Para proteger um arquivo de ser apagado, proteja a pasta em que ele está.** Pastas compartilhadas que
precisam ser graváveis por todos usam o **sticky bit**, o `t` no fim das permissões do `/tmp`: numa
pasta assim, cada pessoa só consegue apagar os próprios arquivos.
