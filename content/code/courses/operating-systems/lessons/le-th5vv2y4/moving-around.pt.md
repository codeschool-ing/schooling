---
title: Andando por aí: onde, o quê, vá
version: 1
---

Três comandos fazem quase tudo: o **`pwd`** diz onde você está, o `ls` lista o que há ali, e o
`cd` vai para outro lugar.

```
ana@server:~$ pwd
/home/ana
ana@server:~$ ls
downloads  office  upgrade.log
ana@server:~$ cd office
ana@server:~/office$ ls
 clients  'invoices 2026'   notes.txt   scans
ana@server:~/office$ cd clients
ana@server:~/office/clients$ pwd
/home/ana/office/clients
ana@server:~/office/clients$ cd ..
ana@server:~/office$ cd /etc
ana@server:/etc$ pwd
/etc
ana@server:/etc$ cd -
/home/ana/office
ana@server:~/office$ cd ~
ana@server:~$ pwd
/home/ana
```

Todo o resto desse registro é sobre **caminhos**, e eles são de dois tipos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma árvore: a barra no topo, com etc e home; home contém ana; ana contém office; office contém clients, invoices 2026 e scans. Você está em office. Quatro comandos: cd clients desce para clients, relativo a onde você está; cd .. sobe para /home/ana; cd /etc começa do topo e funciona de qualquer lugar, porque é absoluto; cd ~ vai para casa de qualquer lugar.\"><defs><marker id=\"pa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60.0 44 L65.0 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 44 L170.0 64\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170.0 88 L165.0 108\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M165.0 132 L175.0 152\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M175.0 176 L100.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M175.0 176 L215.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M175.0 176 L310.0 206\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"40\" y=\"20\" width=\"40\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60.0\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/</text><rect x=\"40\" y=\"64\" width=\"50\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etc</text><rect x=\"140\" y=\"64\" width=\"60\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">home</text><rect x=\"140\" y=\"108\" width=\"50\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ana</text><rect x=\"140\" y=\"152\" width=\"70\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"175.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">office</text><rect x=\"60\" y=\"206\" width=\"80\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">clients</text><rect x=\"160\" y=\"206\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">invoices 2026</text><rect x=\"280\" y=\"206\" width=\"60\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scans</text><text x=\"222\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">você está aqui</text><text x=\"420\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">relativo: começa onde você está</text><text x=\"420\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd clients</text><text x=\"520\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desce para clients</text><text x=\"420\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd ..</text><text x=\"520\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobe para /home/ana</text><text x=\"420\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">absoluto: começa em /</text><text x=\"420\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd /etc</text><text x=\"520\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">do topo, de qualquer lugar</text><text x=\"420\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cd ~</text><text x=\"520\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para casa, de qualquer lugar</text></svg>", "caption": "Um caminho absoluto funciona de qualquer lugar e avisa isso começando com /. Um relativo é mais curto e quer dizer uma coisa diferente em cada pasta."}
```

- Caminhos **absolutos** começam com `/`, o topo da árvore da aula 3, e querem dizer a mesma coisa
  onde quer que você esteja. O `cd /etc` funcionou a partir da pasta pessoal e funcionaria de qualquer
  lugar.
- Caminhos **relativos** partem de onde você está. O `cd clients` funcionou porque `office` tem uma
  pasta chamada `clients`; digitado em outro lugar, falha.
- Três atalhos: `..` é a pasta de cima, `~` é a sua pasta pessoal, e **`cd -`** volta para a
  pasta anterior e imprime qual era.

## Pedindo mais ao ls

O `ls` sozinho mostra nomes. As **opções**, as letras depois de um traço, mudam o que ele mostra:

```
ana@server:~$ ls -l office
total 16
drwxrwxr-x 2 ana ana 4096 Sep  1 09:00 clients
drwxrwxr-x 2 ana ana 4096 Sep  1 09:00 invoices 2026
-rw-rw-r-- 1 ana ana   25 Sep  1 09:00 notes.txt
drwxrwxr-x 2 ana ana 4096 Sep  1 09:00 scans
ana@server:~$ ls -a office
.
..
.backup-settings
clients
invoices 2026
notes.txt
scans
ana@server:~$ ls -lh office/"invoices 2026"
total 48K
-rw-rw-r-- 1 ana ana 48K Sep  1 09:00 march.pdf
```

- **`-l`**, *long*, longo, acrescenta uma linha por item: permissões (aula 9), dono, tamanho em bytes,
  data. Um `d` no começo da linha é um diretório.
- **`-a`**, *all*, tudo, inclui os nomes que começam com ponto, que o `ls` esconde. O
  `.backup-settings` estava lá o tempo todo. O `.` é a própria pasta e o `..` a de cima, o mesmo `..`
  do `cd ..`.
- **`-h`**, *human*, humano, escreve os tamanhos como `48K` em vez de uma contagem de bytes. Só importa
  onde os tamanhos aparecem, como com `-l`.

As opções se combinam, `-lh` ou `-la`, e a ordem não importa.
