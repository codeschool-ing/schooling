---
title: Onde o Linux guarda as contas
version: 1
---

Toda conta numa máquina Linux é uma linha no **`/etc/passwd`**, sete campos separados por dois-pontos. O
`getent` imprime as linhas das contas que você nomeia:

```
ana@server:~$ getent passwd root ana www-data nobody
root:x:0:0:root:/root:/bin/bash
ana:x:1000:1000::/home/ana:/bin/bash
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
ana@server:~$ awk -F: '$3 < 1000' /etc/passwd | wc -l
22
ana@server:~$ awk -F: '$3 >= 1000 && $3 < 65534' /etc/passwd
ana:x:1000:1000::/home/ana:/bin/bash
```

Desmontando a linha da `ana`: *nome*, `x` (a senha fica em outro lugar), *ID de usuário* 1000, *ID
de grupo* 1000, um comentário para o nome completo da pessoa (vazio para a ana), *pasta pessoal*, e o
*shell* que inicia quando ela entra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" aria-label=\"Os números de ID de usuário no Ubuntu, da esquerda para a direita. 0 é o root, o administrador. 1 a 999 são contas de sistema, para serviços e não para pessoas; www-data, a do servidor web, é 33. 1000 para cima são pessoas: ana é 1000, a próxima pessoa 1001. 65534 é nobody, uma conta que não é dona de nada, de propósito.\"><defs><marker id=\"ui-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"90\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"65.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0</text><text x=\"65.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">root</text><text x=\"65.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o administrador</text><rect x=\"114\" y=\"20\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1 a 999</text><text x=\"214.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">contas de sistema</text><text x=\"214.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">serviços, nenhuma pessoa: www-data é 33</text><rect x=\"318\" y=\"20\" width=\"240\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"438.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1000 para cima</text><text x=\"438.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pessoas</text><text x=\"438.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ana é 1000, a próxima pessoa 1001</text><rect x=\"562\" y=\"20\" width=\"138\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"631.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">65534</text><text x=\"631.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nobody</text><text x=\"631.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não é dono de nada, de propósito</text></svg>", "caption": "O sistema decide pelo número, não pelo nome. Uma conta chamada admin com ID 1005 é um usuário comum; qualquer conta com ID 0 é root, tenha o nome que tiver.", "same": ["root", "nobody"]}
```

O servidor tem **22 contas abaixo de 1000 e uma pessoa**, a ana. A maior parte das contas de uma máquina
Linux não são pessoas: `www-data` é a conta com que um servidor web roda, então uma falha no servidor web
só alcança o que a `www-data` pode tocar. O shell delas é **`/usr/sbin/nologin`**, que recusa qualquer
tentativa de entrar como elas.

## Grupos

```
ana@server:~$ groups
ana sudo
ana@server:~$ getent group sudo
sudo:x:27:ana
```

O **`/etc/group`** é a mesma ideia para grupos: o nome, um `x`, o ID do grupo e os membros. **Estar no
grupo `sudo` é o que faz da ana uma administradora no Ubuntu**. Fora isso, nada na conta dela é
especial. Outras distribuições chamam esse grupo de `wheel`.

## A senha não está no passwd

O `/etc/passwd` tem de ser legível por todos, porque todo `ls -l` transforma IDs de usuário em nomes.
Então os hashes das senhas moram no **`/etc/shadow`**, legível só pelo root. O `passwd -S` informa sobre
eles sem mostrá-los, e a seção 02 o usa.
