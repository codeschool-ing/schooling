---
title: Uma chave no lugar da senha
version: 1
---

Uma senha pode ser adivinhada, reusada em outro site, ou lida por cima do ombro de alguém. **Um par de
chaves não se adivinha e nunca sai do laptop.** O `ssh-keygen` cria um:

```
ana@laptop:~$ ssh-keygen -t ed25519 -N "blue kettle on the roof" -C "ana@laptop" -f ~/.ssh/id_ed25519
Generating public/private ed25519 key pair.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg ana@laptop
The key's randomart image is:
+--[ED25519 256]--+
|.++o+.     ..    |
| oo=.*.  ..o .   |
|  + + =...+.+ + .|
|   = o ..+.* = + |
|  + .   S * E +  |
|   . .   o + =   |
|      . o + o .  |
|       . o . .   |
|        ...      |
+----[SHA256]-----+
ana@laptop:~$ ls -l ~/.ssh
total 12
-rw------- 1 ana ana 444 Sep 25 15:10 id_ed25519
-rw-r--r-- 1 ana ana  92 Sep 25 15:10 id_ed25519.pub
-rw-r--r-- 1 ana ana 142 Sep 25 15:10 known_hosts
```

Dois arquivos. `id_ed25519` é a **chave privada**, `-rw-------`, legível só pelo dono. `id_ed25519.pub`
é a **chave pública**, e pode ser entregue a qualquer servidor, ou a qualquer pessoa. Ed25519 é o tipo
moderno, curto e rápido, e o padrão do OpenSSH recente; chaves RSA ainda funcionam e são bem mais
longas. O comentário do `-C` é só um rótulo, para que uma lista de chaves diga de quem é cada uma.

A **frase-senha** (*passphrase*) cifra a chave privada no disco. Sem ela, quem copiar o arquivo, de um
laptop roubado ou de um backup, entra como a Ana em todo servidor que confia na chave. Com ela, o arquivo
sozinho não serve para nada. O `-N` a passou na linha de comando aqui para que a sessão pudesse ser
gravada; digitada no prompt, ela não ficaria no histórico do shell.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois pares de chaves, trabalhando em sentidos opostos. No laptop: a chave privada id_ed25519, trancada por uma frase-senha; a metade pública dela, id_ed25519.pub; e o known_hosts, as chaves de servidor já aceitas. No servidor: a chave privada de host em /etc/ssh, e o authorized_keys da ana, as chaves públicas que podem entrar como ana. A chave de host do servidor é conferida no known_hosts do laptop, e isso prova o servidor para o laptop. O ssh-copy-id copia a chave pública para o authorized_keys, e a cada login a chave privada do laptop prova a Ana para o servidor. Nenhuma chave privada atravessa.\"><defs><marker id=\"ky-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"280\" height=\"250\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><rect x=\"430\" y=\"20\" width=\"280\" height=\"250\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"442\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><rect x=\"22\" y=\"56\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/.ssh/id_ed25519</text><text x=\"34\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sua chave privada, com frase-senha</text><rect x=\"22\" y=\"128\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/.ssh/id_ed25519.pub</text><text x=\"34\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a metade pública dela</text><rect x=\"22\" y=\"200\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/.ssh/known_hosts</text><text x=\"34\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as chaves de servidor aceitas</text><rect x=\"442\" y=\"200\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/etc/ssh/ssh_host_ed25519_key</text><text x=\"454\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a chave privada de host do servidor</text><rect x=\"442\" y=\"128\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">~/.ssh/authorized_keys</text><text x=\"454\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as chaves públicas que entram como ana</text><path d=\"M442 232 L280 232\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ky-ah)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">prova o servidor a você</text><path d=\"M278 153 L440 153\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ky-ah)\"></path><text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ssh-copy-id</text><path d=\"M278 90 L440 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ky-ah)\"></path><text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">prova você ao servidor</text></svg>", "caption": "Dois pares, dois sentidos. A chave de host responde \"este é mesmo o servidor?\" e a sua chave responde \"esta é mesmo a Ana?\". Só as metades públicas viajam; cada chave privada fica na máquina em que foi feita."}
```

O desenho tem dois pares, e é fácil confundi-los. A **chave de host** do servidor prova o servidor para
a Ana, e o `known_hosts` é onde ela guarda as que aceitou. A chave dela prova a Ana para o servidor, e o
servidor guarda a metade pública no `authorized_keys`. A próxima seção a coloca lá.
