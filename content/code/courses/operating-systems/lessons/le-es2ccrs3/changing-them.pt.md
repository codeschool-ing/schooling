---
title: Mudando permissões e donos
version: 1
---

O **`chmod`** muda permissões, e as aceita de dois jeitos.

**Por letra**, que muda só o que você nomeia: `u`, `g`, `o` para dono (*user*), grupo e outros, `+` ou
`-`, e as letras. É o que conserta um script que não roda:

```
ana@server:/srv/office$ cat backup.sh
#!/bin/sh
echo backup done
ana@server:/srv/office$ ls -l backup.sh
-rw-rw-r-- 1 ana ana 27 Sep 25 10:53 backup.sh
ana@server:/srv/office$ ./backup.sh
bash: ./backup.sh: Permission denied
ana@server:/srv/office$ chmod u+x backup.sh
ana@server:/srv/office$ ./backup.sh
backup done
ana@server:/srv/office$ chmod 640 payroll.txt
ana@server:/srv/office$ ls -l payroll.txt backup.sh
-rwxrw-r-- 1 ana ana 27 Sep 25 10:53 backup.sh
-rw-r----- 1 ana ana  9 Sep  1 09:00 payroll.txt
ana@server:/srv/office$ stat -c "%a %A %n" payroll.txt backup.sh
640 -rw-r----- payroll.txt
764 -rwxrw-r-- backup.sh
```

O `./backup.sh` foi recusado porque ninguém tinha `x` nele. O `chmod u+x` o acrescentou para o dono, e o
mesmo arquivo rodou.

**Por número**, que define as nove de uma vez. Cada letra vale um número, e o dígito de cada grupo é a
soma delas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Como funcionam os números do chmod. Ler vale 4, gravar 2 e executar ou entrar 1, somados para dono, grupo e outros. 640 é rw-, r--, ---: seis é quatro mais dois, depois quatro, depois zero; o arquivo da folha, que o dono edita e o grupo lê. 755 é rwx, r-x, r-x: sete, cinco, cinco; um programa ou uma pasta pública. 2770 é rwx, rws, ---: o 2 na frente é o setgid, mostrado como um s no lugar do grupo; uma pasta compartilhada cujos arquivos novos entram no grupo dela.\"><defs><marker id=\"oc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\" xml:space=\"preserve\">r = 4   w = 2   x = 1</text><text x=\"200\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada letra é um número; some por grupo</text><rect x=\"20\" y=\"40\" width=\"64\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">640</text><rect x=\"100\" y=\"40\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rw-</text><text x=\"140\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 = 4+2</text><rect x=\"190\" y=\"40\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r--</text><text x=\"230\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"280\" y=\"40\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">---</text><text x=\"320\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"380\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">folha: o dono edita, o grupo lê</text><rect x=\"20\" y=\"92\" width=\"64\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">755</text><rect x=\"100\" y=\"92\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rwx</text><text x=\"140\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7 = 4+2+1</text><rect x=\"190\" y=\"92\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r-x</text><text x=\"230\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 = 4+1</text><rect x=\"280\" y=\"92\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">r-x</text><text x=\"320\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><text x=\"380\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um programa ou uma pasta pública</text><rect x=\"20\" y=\"144\" width=\"64\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2770</text><rect x=\"100\" y=\"144\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rwx</text><text x=\"140\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><rect x=\"190\" y=\"144\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rws</text><text x=\"230\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7 + setgid</text><rect x=\"280\" y=\"144\" width=\"80\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">---</text><text x=\"320\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"380\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma pasta compartilhada: arquivo novo entra no grupo dela</text></svg>", "caption": "Três dígitos, um por grupo, cada um a soma de 4, 2 e 1. Um quarto dígito na frente liga os bits especiais, e o 2 é o que uma pasta compartilhada precisa."}
```

O `chmod 640 payroll.txt` deu ao dono leitura e gravação, ao grupo leitura, e aos outros nada, num passo
só. O `stat` imprime o número de um arquivo que já existe, que é o jeito mais rápido de aprender a lê-los.

Os números que vale saber de cor: `644` para um arquivo comum, `600` para um particular, `755`
para um programa ou uma pasta em que qualquer um pode entrar, `700` para uma pasta particular.

## Donos

```
ana@server:/srv/office$ chown bruno payroll.txt
chown: changing ownership of 'payroll.txt': Operation not permitted
ana@server:/srv/office$ sudo chown bruno:bruno payroll.txt
ana@server:/srv/office$ ls -l payroll.txt
-rw-r----- 1 bruno bruno 9 Sep  1 09:00 payroll.txt
```

**O `chown` muda o dono, e só o root pode fazer isso.** Senão qualquer um poderia dar um arquivo a outra
pessoa, e com ele a responsabilidade pelo que há dentro, ou encher a cota de disco de outro usuário. O
`chown bruno:bruno` define dono e grupo juntos.
