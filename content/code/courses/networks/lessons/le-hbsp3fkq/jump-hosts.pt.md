---
title: Saltando por uma máquina
version: 1
---

O servidor web da empresa, `www`, só aceita SSH do endereço público do escritório, uma regra comum e
sensata. De casa, a conexão não vai a lugar nenhum:

```
ana@home:~$ ssh -o ConnectTimeout=5 192.0.2.80 hostname
ssh: connect to host 192.0.2.80 port 22: Connection timed out
ana@home:~$ eval $(ssh-agent) >/dev/null
ana@home:~$ ssh-add
Enter passphrase for /home/ana/.ssh/id_ed25519: 
Identity added: /home/ana/.ssh/id_ed25519 (ana@laptop)
ana@home:~$ ssh -J ana@office.example.com:2222 www.example.com
The authenticity of host 'www.example.com (<no hostip for proxy command>)' can't be established.
ED25519 key fingerprint is SHA256:U+Bkk5q+PbWG3Mc+gWmCF0v3GJIoOHojfGM7BzNHKBo.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'www.example.com' (ED25519) to the list of known hosts.
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@www:~$ hostname
www
ana@www:~$ exit
logout
Connection to www.example.com closed.
```

A tentativa direta desistiu depois dos cinco segundos que o `ConnectTimeout=5` deu: o firewall do www a
descartou sem responder (a diferença da aula 3 entre descartar e recusar). O `ssh -J` passa pelo
servidor do escritório. O ssh conecta primeiro ao servidor, pede a ele que abra uma conexão até
`www.example.com` porta 22, e então roda uma segunda sessão SSH, completa, por dentro dessa conexão.
Visto do www, a conexão vem do endereço do escritório, e entra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Um jump host. O home, em 198.51.100.77, tenta chegar direto ao www em 192.0.2.80, e a conexão é descartada, porque o www só aceita SSH do endereço do escritório, 203.0.113.2. Com ssh -J, o home primeiro conecta ao servidor do escritório pela porta 2222 do router. O servidor então abre uma conexão até o www, que sai do escritório por 203.0.113.2 e é permitida. A sessão SSH com o www corre por dentro desse caminho, de ponta a ponta, do home ao www.\"><defs><marker id=\"jp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">home</text><text x=\"32\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"295\" y=\"118\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"307\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><text x=\"307\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"592\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www</text><text x=\"592\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.0.2.80</text><path d=\"M140 48 L578 48\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\" stroke-dasharray=\"5 4\"></path><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">descartada: o www só aceita SSH de 203.0.113.2</text><path d=\"M140 84 L293 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\"></path><text x=\"24\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">primeiro salto, via router:2222</text><path d=\"M425 134 L578 84\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\"></path><text x=\"456\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de 203.0.113.2: permitida</text><path d=\"M140 68 L360 106 L578 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#jp-ah)\" stroke-dasharray=\"2 3\"></path><text x=\"360\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">a sessão com o www corre por dentro, de ponta a ponta</text></svg>", "caption": "O servidor só repassa bytes que não consegue ler. Chaves, senhas e a conferência da chave de host ficam entre o home e o www, e é por isso que o known_hosts do home, e não o do servidor, ganhou a chave do www."}
```

**O servidor do meio só repassa bytes.** A sessão com o www é cifrada de ponta a ponta entre o home e o
www, e a chave nunca sai do home. A chave de host pela qual o ssh perguntou era a do www, guardada no
`known_hosts` do home. `<no hostip for proxy command>` é o ssh dizendo que nunca soube o endereço do www,
porque foi o servidor que fez a conexão. No `~/.ssh/config`, uma linha `ProxyJump office` no bloco do
www faz toda conexão seguir esse caminho.

Uma máquina que existe para se saltar por ela se chama **jump host**, ou bastion, e é a única porta
por onde se chega a uma rede inteira de servidores.
