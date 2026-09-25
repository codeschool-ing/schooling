---
title: O que o prompt diz
version: 1
---

A linha em que o cursor fica é o **prompt**, e ele é informação, não enfeite. Três comandos confirmam o
que o prompt padrão do Ubuntu já diz:

```
ana@server:~$ whoami
ana
ana@server:~$ hostname
server
ana@server:~$ pwd
/home/ana
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro prompts desmontados. ana@server:~/office$ diz quem você é, ana; qual máquina, server; onde você está, ~/office; e o cifrão quer dizer um usuário comum. root@server:/home/ana# é o administrador, root, e o sinal de cerquilha diz cuidado. PS /home/ana/office&gt; é o PowerShell, seguido de onde você está. C:\\Users\\ana&gt; é o cmd.exe no Windows, mostrando onde você está.\"><defs><marker id=\"pr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ana@server:~/office$</text><text x=\"300\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">ana</text><text x=\"440\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">quem você é</text><text x=\"300\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">server</text><text x=\"440\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">qual máquina</text><text x=\"300\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">~/office</text><text x=\"440\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde você está</text><text x=\"300\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">$</text><text x=\"440\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um usuário comum</text><rect x=\"20\" y=\"96\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">root@server:/home/ana#</text><text x=\"300\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">root</text><text x=\"440\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o administrador</text><text x=\"300\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">#</text><text x=\"440\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cuidado: root</text><rect x=\"20\" y=\"160\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PS /home/ana/office&gt;</text><text x=\"300\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">PS</text><text x=\"440\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">PowerShell</text><text x=\"300\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">/home/ana/office</text><text x=\"440\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde você está</text><rect x=\"20\" y=\"224\" width=\"250\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">C:\\Users\\ana&gt;</text><text x=\"300\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C:\\Users\\ana</text><text x=\"440\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cmd.exe no Windows: onde você está</text></svg>", "caption": "Leia o prompt antes de digitar. Ele responde as três perguntas que decidem se um comando é seguro: quem, em qual máquina, e onde.", "same": ["PowerShell"]}
```

O último caractere é o que mais importa. **`$` é um usuário comum; `#` é o root**, o administrador da
aula 3, para quem nada é recusado. O `sudo -s` abre um shell inteiro como root, e o prompt muda na
hora:

```
ana@server:~$ sudo -s
root@server:/home/ana# whoami

root
root@server:/home/ana# exit

exit
```

**Um prompt com `#` quer dizer que todo comando passa direto**, sem senha e sem segunda chance. Faça o
que precisa de root, e dê `exit` assim que terminar. A aula 10 explica por que trabalhar como usuário
comum e pegar o root emprestado por comando, como o `sudo` faz, é o hábito mais seguro.

## Os outros prompts

Os mesmos três dados aparecem, arrumados de outro jeito, nos outros sistemas:

```sh
C:\Users\ana> cd Documents
C:\Users\ana\Documents> dir
C:\Users\ana\Documents> cd ..
C:\Users\ana> echo %USERPROFILE%
```

```sh
ana@Anas-MacBook-Air ~ % cd Documents
ana@Anas-MacBook-Air Documents % ls -l
ana@Anas-MacBook-Air Documents % echo $SHELL      # /bin/zsh
```

**Nenhum dos dois foi rodado para esta aula.** O primeiro é o **Prompt de Comando**, o `cmd.exe`, o
shell do Windows que descende do MS-DOS. Ele mostra só o caminho. O segundo é o
**zsh** do macOS, o shell padrão do Mac desde 2019: usuário, nome da máquina, o nome da pasta atual, e
`%` onde o bash mostra `$`.
