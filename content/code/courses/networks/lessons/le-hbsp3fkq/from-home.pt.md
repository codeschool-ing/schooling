---
title: Chegando ao escritório de casa
version: 1
---

O servidor tem um endereço privado, `192.168.10.10`, que não quer dizer nada na internet (aula 2). De
casa, o único endereço do escritório que alguém alcança é o do router, `203.0.113.2`, para onde
`office.example.com` aponta. Então o router precisa de uma regra: conexões que chegam pelo lado
público na porta 2222 vão para a porta 22 do servidor.

```
ana@router:~$ sudo nft add table ip nat
ana@router:~$ sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority dstnat; }'
ana@router:~$ sudo nft add rule ip nat prerouting iifname "eth1" tcp dport 2222 dnat to 192.168.10.10:22
ana@router:~$ sudo nft list chain ip nat prerouting
table ip nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                iifname "eth1" tcp dport 2222 dnat to 192.168.10.10:22
        }
}
```

Isso é **redirecionamento de porta** (*port forwarding*), NAT de destino: o router reescreve para onde
a conexão vai. De casa:

```
ana@home:~$ ssh -p 2222 office.example.com
The authenticity of host '[office.example.com]:2222 ([203.0.113.2]:2222)' can't be established.
ED25519 key fingerprint is SHA256:lnt8eQvQ3cgVbp6gskjE+zbhlBcPdROpmRKsk6xZHN8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[office.example.com]:2222' (ED25519) to the list of known hosts.
Enter passphrase for key '/home/ana/.ssh/id_ed25519': 
Last login: Fri Sep 25 15:10:53 2026 from 192.168.10.20
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@server:~$ hostname; who
server
ana      pts/1        2026-09-25 15:11 (198.51.100.77)
ana@server:~$ exit
logout
Connection to office.example.com closed.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Chegando ao servidor do escritório a partir de casa. O home, em 198.51.100.77, na internet, conecta ao endereço público do escritório, 203.0.113.2, porta 2222. A regra do router reescreve o destino para o endereço privado do servidor, 192.168.10.10, porta 22, e passa a conexão adiante. O endereço de origem não muda, então o servidor vê a conexão vindo de 198.51.100.77.\"><defs><marker id=\"ou-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a internet</text><rect x=\"300\" y=\"16\" width=\"410\" height=\"180\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"312\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o escritório</text><rect x=\"20\" y=\"80\" width=\"110\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">home</text><text x=\"32\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"320\" y=\"80\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"332\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">router</text><text x=\"332\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"566\" y=\"80\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"578\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><text x=\"578\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><path d=\"M130 105 L318 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ou-ah)\"></path><text x=\"138\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">para 203.0.113.2, porta 2222</text><path d=\"M440 105 L564 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ou-ah)\"></path><text x=\"452\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reescrito para 192.168.10.10, porta 22</text><text x=\"452\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a origem continua 198.51.100.77</text></svg>", "caption": "O NAT de destino muda para onde uma conexão vai e nada sobre de onde ela veio, e é por isso que o who do servidor mostrou o endereço de casa. A porta 2222 é só do router; o servidor continua escutando na 22."}
```

O ssh perguntou de novo pela chave de host, porque para o ssh `[office.example.com]:2222` é uma máquina
diferente de `192.168.10.10`. A impressão digital é a mesma, `SHA256:lnt8eQ…`, e é exatamente assim
que se sabe que o router a entregou ao servidor de verdade. O `who` no servidor mostra a conexão vindo
de `198.51.100.77`, o endereço de casa: a regra mudou o destino e deixou a origem em paz.

**A porta 2222 não esconde nada.** Scanners tentam toda porta de todo endereço, e um servidor SSH na
internet recebe tentativas de login poucas horas depois de aparecer. O que o protege é a seção 11:
só chaves, nenhuma senha. Muitos escritórios vão além e não expõem SSH nenhum, só uma VPN, e chegam
ao servidor de dentro dela.
