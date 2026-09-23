---
title: Nomes, e quatro regras que não são as que você espera
version: 2
---

Um nome de arquivo no Linux é mais livre do que você pensa e mais estrito do que você pensa, em
lugares diferentes dos que você está acostumado. Quatro regras, e cada uma custa uma tarde de
alguém na primeira vez.

## 1 · Maiúscula importa

```
ana@vm:~/case$ ls
NOTES.TXT
Notes.txt
notes.txt
```

**Três arquivos diferentes**, num diretório só, ao mesmo tempo. O Windows e o macOS teriam recusado
criar o segundo: neles, `Notes.txt` e `notes.txt` são o mesmo nome escrito de dois jeitos.

Essa é a regra que quebra deploy. Um projeto funciona no Mac de alguém, onde `Header.css` e
`header.css` são um arquivo só, e falha no servidor Linux que o serve, onde são dois e só um
existe. O código não mudou. O sistema de arquivos deixou de ser tolerante.

O hábito que evita tudo isso: **minúsculas, sempre**, e um hífen onde você quer um espaço.

## 2 · A extensão não decide nada

```
ana@vm:~/case$ file report.pdf
report.pdf: ASCII text
```

Aquele arquivo se chama `report.pdf` e é um arquivo de texto. O Linux não conferiu, não avisou e
não se importou — porque **a extensão faz parte do nome e nada além disso.** Não existe registro de
tipos de arquivo, nem associação entre `.pdf` e um programa.

O `file` é o comando que de fato olha:

```
ana@vm:~$ file /bin/ls
/bin/ls: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked
```

O `/bin/ls` não tem extensão nenhuma e é um programa. Ele lê os primeiros bytes do conteúdo e
reporta o que achou, que é o único jeito honesto de responder.

Duas consequências:

- **Renomear não converte.** `mv a.txt a.pdf` produz um arquivo de texto com nome enganoso.
- **Quem decide se algo executa é um bit de permissão**, não o `.exe`. A aula 4 é sobre esse bit, e
  o `file` dizendo "executable" acima está reportando ele.

## 3 · Um ponto na frente esconde

Um nome que começa com `.` fica de fora de uma listagem comum. É esse o mecanismo inteiro — não
existe atributo de oculto em lugar nenhum, só uma convenção que o `ls` respeita:

```
ana@vm:~/plain$ ls
folder	readme.txt
ana@vm:~/plain$ ls -a
.  ..  .hidden	folder	readme.txt
```

Não é sigilo e não é proteção. É um jeito de manter configuração fora do seu caminho: o seu
diretório pessoal guarda dezenas desses — `.bashrc`, `.ssh`, `.gitconfig` — e você nunca ia querer
eles atrapalhando quando lista seus documentos.

O `.` e o `..` naquela saída são o diretório atual e o pai. São entradas como qualquer outra, e é
por isso que o `-a` mostra eles e por isso que `cd ..` funciona.

## 4 · Quase todo caractere é permitido, e você não deveria

Um nome de arquivo no Linux pode conter qualquer coisa exceto duas: uma `/`, que separa diretórios,
e um byte zero. **Todo o resto é legal** — espaços, aspas, quebras de linha, emoji, um hífen na
frente.

Legal não é sensato, e a seção 07 já mostrou por quê:

```
ana@vm:~/demo$ ls with space.txt
ls: cannot access 'with': No such file or directory
ls: cannot access 'space.txt': No such file or directory
```

O arquivo existe. O shell quebrou a linha antes de o `ls` ver. Um nome com espaço é um nome que
você vai ter de colocar entre aspas pelo resto da vida dele, e um nome que começa com `-` precisa
de `--` na frente para sempre.

**Então a regra é um hábito, não uma restrição:** minúsculas, letras, dígitos, hifens, sublinhados
e pontos. Nada além disso. Você vai ler nomes de outras pessoas que quebram isso, e as aspas são
como você sobrevive a eles.

## As quatro, juntas

| | |
|---|---|
| maiúsculas | `Notes.txt` e `notes.txt` são dois arquivos |
| extensão | parte do nome; quem de fato sabe é o `file` |
| ponto na frente | oculto do `ls`, por convenção, não por uma flag |
| o resto | legal não quer dizer aconselhável |
