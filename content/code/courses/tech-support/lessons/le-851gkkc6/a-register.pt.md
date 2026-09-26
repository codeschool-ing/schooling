---
title: Três computadores, um registro
version: 1
---

O mesmo script em três computadores, cada linha acrescentada a um arquivo:

```
ana@host:~$ echo "name,maker,model,serial,cpu,memory,root fs,mac,os" > assets.csv; for m in pc1 pc2 srv1; do ssh $m bash /tmp/inventory.sh >> assets.csv; done; cat assets.csv
name,maker,model,serial,cpu,memory,root fs,mac,os
"pc1","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","961 MiB","6.8G","52:54:00:8c:26:a7","24.04"
"pc2","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","961 MiB","6.8G","52:54:00:8c:e8:f2","24.04"
"srv1","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","1463 MiB","6.8G","52:54:00:db:e3:cb","24.04"
```

Três linhas, e **elas diferem onde as máquinas diferem**: o `srv1` tem 1463 MiB, os outros
961, e cada um tem o próprio MAC. O resto é idêntico, o que também é informação: três computadores
do mesmo tipo podem ser trocados, consertados e estocados juntos.

Duas coisas deram errado enquanto esta aula era escrita, e as duas são comuns:

- **Uma vírgula dentro de um valor.** O nome do modelo tem uma, e a primeira versão do script não punha os
  campos entre aspas, então uma planilha dividia `(Q35 + ICH9, 2009)` em duas colunas e deslocava todas as
  colunas seguintes em uma.
- **Um valor padrão que nunca entrava.** A primeira versão escrevia `none` quando o número de série vinha
  vazio. Ele nunca vem vazio: uma máquina sem número de série diz `Not Specified`, e muitos PCs dizem *To Be
  Filled By O.E.M.*, e os dois são texto que parece número de série para um script que só confere se veio
  nada.

O registro precisa então da metade das pessoas ao lado de cada linha:

| da máquina | das pessoas e da papelada |
|---|---|
| nome, fabricante, modelo, número de série | plaqueta de patrimônio, o número da própria organização |
| processador, memória, disco, MAC | quem usa, e onde está |
| sistema operacional e versão | comprado quando, de quem, garantia até quando |
| | situação: em uso, em estoque, em reparo, aposentado |
