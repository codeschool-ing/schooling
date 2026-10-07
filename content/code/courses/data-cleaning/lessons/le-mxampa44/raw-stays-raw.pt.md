---
title: Os arquivos brutos continuam brutos
version: 1
---

Toda aula deste curso leu de `raw/` e nenhuma escreveu lá. Não foi por educação. **Os arquivos
brutos são a única prova do que chegou**, e uma limpeza que os edita destrói justamente aquilo
contra o que precisaria ser conferida. A aula 1 montou o laboratório para que essa regra seja
garantida e não lembrada:

```
ana@lab:~/clean$ ls -ld raw; ls -l raw | head -4
dr-xr-xr-x 2 ana ana 4096 Oct  7 01:52 raw
total 6908
-r--r--r-- 1 ana ana  244696 Oct  7 01:52 customers.csv
-r--r--r-- 1 ana ana     286 Oct  7 01:52 fx_rates_2025.csv
-r--r--r-- 1 ana ana    3659 Oct  7 01:52 invoices.csv
ana@lab:~/clean$ touch raw/notes.txt
touch: cannot touch 'raw/notes.txt': Permission denied
ana@lab:~/clean$ sed -i 's/Pepino/Pepino japonês/' raw/products.csv
sed: couldn't open temporary file raw/sedCSmpNw: Permission denied
```

O diretório e todos os arquivos nele são só de leitura, então um `touch` perdido ou um `sed` que
edita no lugar falha em vez de mudar os dados em silêncio. Essa proteção tem um limite que vale
dizer: a ana é dona dos arquivos, então poderia torná-los graváveis de novo. **Só leitura protege
contra acidentes, não contra intenção**, e o passo seguinte é o que pega o resto.

Um **checksum** é uma impressão digital dos bytes de um arquivo. Mude um caractere em qualquer
lugar e a impressão SHA-256 muda por completo. Registrar as impressões dos arquivos brutos uma vez,
quando chegam, torna detectável qualquer mudança posterior:

```
ana@lab:~/clean$ sha256sum raw/*.csv > raw.sha256 && head -3 raw.sha256
8a594c4c04516e4398bebea1c3d13357730d214f5ce8b7e14927d717217860c1  raw/customers.csv
828ced3123e1715e6b6df68071cd4461ba91e019c4f0f5194760b43c759f8302  raw/fx_rates_2025.csv
351f51e69a37b56975b307f8c8e8de040751857e947bc2f1aad1a5a7591c8351  raw/invoices.csv
ana@lab:~/clean$ sha256sum --check --quiet raw.sha256 && echo all raw files match
all raw files match
```

O `raw.sha256` é pequeno, legível e vai para o controle de versão junto com o código. Antes de
qualquer nova execução, o `sha256sum --check` diz se as entradas ainda são aquelas a partir das
quais os resultados foram feitos. Se um arquivo foi trocado, reexportado ou editado, a verificação
diz qual, e os resultados feitos sobre o antigo passam a ser sabidamente desatualizados em vez de
errados em silêncio.

A mesma ideia vale para tudo o mais que a análise usa de fora: os arquivos de referência da aula
14, em `ref/`, também pertencem ao manifesto, com `sha256sum raw/*.csv ref/*.csv`.
