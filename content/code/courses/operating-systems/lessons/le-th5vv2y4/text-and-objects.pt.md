---
title: Texto ou objetos: a diferença que importa
version: 1
---

Os dois shells ligam comandos com um **pipe**, `|`: a saída de um vira a entrada do seguinte. O que
desce pelo pipe é onde eles diferem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" aria-label=\"Dois pipes comparados. No bash, texto desce pelo pipe: o ls -l imprime linhas como -rw-rw-r-- 1 ana ana 25 Sep 1 09:00 acme.txt, e um comando que quer o tamanho tem de achar a quinta palavra. No PowerShell, objetos descem pelo pipe: cada arquivo é um objeto com propriedades, entre elas Name acme.txt e Length 25, e um comando que quer o tamanho pede a propriedade Length.\"><defs><marker id=\"ob-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">bash: texto desce pelo pipe</text><text x=\"380\" y=\"18\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">PowerShell: objetos descem pelo pipe</text><rect x=\"20\" y=\"34\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\" xml:space=\"preserve\">-rw-rw-r-- 1 ana ana 25 Sep  1 09:00 acme.txt</text><rect x=\"20\" y=\"74\" width=\"330\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\" xml:space=\"preserve\">-rw-rw-r-- 1 ana ana 15 Sep  1 09:00 bravo.txt</text><text x=\"20\" y=\"134\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o tamanho é &quot;a quinta palavra&quot;</text><rect x=\"380\" y=\"34\" width=\"156\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Name</text><text x=\"470\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">acme.txt</text><text x=\"390\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Length</text><text x=\"470\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">25</text><rect x=\"550\" y=\"34\" width=\"156\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Name</text><text x=\"640\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">bravo.txt</text><text x=\"560\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Length</text><text x=\"640\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">15</text><text x=\"380\" y=\"134\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o tamanho é .Length</text></svg>", "caption": "Nenhum é melhor em tudo. Texto funciona com todo programa já escrito; objetos deixam o próximo comando independente de como o anterior arrumou as colunas."}
```

```
ana@server:~$ ls -l office/clients
total 8
-rw-rw-r-- 1 ana ana 25 Sep  1 09:00 acme.txt
-rw-rw-r-- 1 ana ana 15 Sep  1 09:00 bravo.txt
PS /home/ana> Get-ChildItem office/clients | Select-Object Name, Length, LastWriteTime

Name      Length LastWriteTime
----      ------ -------------
acme.txt      25 09/01/2026 09:00:00
bravo.txt     15 09/01/2026 09:00:00

PS /home/ana> Get-ChildItem office/clients | Where-Object Length -gt 20

    Directory: /home/ana/office/clients

UnixMode         User Group         LastWriteTime         Size Name
--------         ---- -----         -------------         ---- ----
-rw-rw-r--        ana ana        09/01/2026 09:00           25 acme.txt
```

- **O bash passa texto.** O `ls -l` imprime linhas, e um comando que quer o tamanho tem de saber que ele
  é a quinta palavra de cada linha. A aula 12 faz exatamente isso, e funciona porque o formato do
  `ls -l` quase não mudou em cinquenta anos.
- **O PowerShell passa objetos.** O `Get-ChildItem` manda objetos de arquivo, e o `Select-Object` escolhe
  propriedades **pelo nome**, `Name`, `Length`, `LastWriteTime`, seja qual for a coluna em que teriam
  sido impressas. O `Where-Object Length -gt 20` ficou só com os arquivos maiores que 20 bytes, o
  `acme.txt`, sem ninguém contar colunas.

A consequência para o trabalho de suporte: **uma linha de PowerShell continua funcionando** quando uma
atualização do Windows muda a arrumação de uma tabela, porque ela nunca leu a tabela. Uma linha de bash
é **mais curta, e funciona com todo programa**, inclusive os escritos em 1985 que não sabem nada de
objetos.

## Três hábitos para qualquer shell

- O *Tab* completa nomes, a checagem de segurança da seção 03.
- A *seta para cima* traz de volta o comando anterior, e o *Ctrl+R* busca em todos eles.
- O *Ctrl+C* para um comando que está rodando, e é o que apertar quando algo rola sem parar.

O shell guarda a lista, e sabe mostrá-la:

```
ana@server:~$ cd office
ana@server:~/office$ ls
 clients  'invoices 2026'   notes.txt   scans
ana@server:~/office$ cd clients
ana@server:~/office/clients$ history
    1  cd office
    2  ls
    3  cd clients
    4  history
```

Um registro numerado do que você digitou é também o que torna a linha de comando **repetível**: os
passos que consertaram uma máquina podem ser copiados, conferidos e rodados na seguinte.
