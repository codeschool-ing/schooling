---
title: Fechando as outras portas
version: 1
---

**O bastião vira um controle no dia em que os servidores recusam todo o resto.** Até lá o `desk`
ainda vai direto ao `web`, e uma chave roubada do `desk` ainda funciona ali. A regra pertence ao
próprio `web`, no firewall dele: SSH vindo do `jump`, e de nenhum outro lugar.

```
root@web:~# nft -f - <<'EOF'
table inet admin {
    chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 22 ip saddr 192.168.60.40 accept
        tcp dport 22 counter reject with tcp reset
    }
}
EOF
ana@desk:~$ ssh web hostname; echo "exit $?"
ssh: connect to host web port 22: Connection refused
exit 255
ana@admin:~$ ssh web hostname
web
```

A primeira regra aceita a porta 22 vinda de `192.168.60.40`; a segunda recusa toda outra tentativa na
porta 22 e a conta. `reject with tcp reset` responde à recusa na hora, e é por isso que o `desk` viu
`Connection refused` em vez de esperar o tempo estourar: dentro da sua própria rede, uma recusa rápida
e clara poupa um minuto de dúvida ao administrador que errou. Para o lado da internet, a aula 5 pesa
descartar contra recusar. O `admin` continua chegando ao `web`, pelo `jump`, sem digitar nada
diferente, por causa da entrada de configuração da seção anterior.

O mesmo raciocínio vale um passo antes. Se qualquer máquina pode alcançar o bastião, uma chave roubada
de qualquer máquina alcança o bastião, e a lista dele decide o resto. Então o `jump` só aceita SSH
vindo do `admin`, a estação do próprio administrador:

```
root@jump:~# nft -f - <<'EOF'
table inet admin {
    chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 22 ip saddr 192.168.60.30 accept
        tcp dport 22 counter reject with tcp reset
    }
}
EOF
ana@desk:~$ ssh -J jump web hostname; echo "exit $?"
ssh: connect to host jump port 22: Connection refused
exit 255
root@web:~# nft list chain inet admin input | grep counter
		tcp dport 22 counter packets 1 bytes 60 reject with tcp reset
```

O `desk` agora falha no primeiro salto. E o contador no `web` mostra a única conexão que ele recusou
nesta aula, a do `desk` há pouco. **Vale vigiar esse contador**: numa rede em que todo administrador
passa pelo bastião, qualquer pacote que ele conte é alguém, ou alguma coisa, tentando o caminho
antigo.

Essas regras vivem no nftables, como na aula 5, e como tudo o que é digitado num prompt somem no
próximo reboot, a não ser que sejam gravadas em `/etc/nftables.conf`; a aula 5 mostra como fazê-las
persistir.

## A corrente que isso forma

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l15-chain\" aria-label=\"A corrente que as regras formam. O admin conecta no jump na porta 22, permitido pelo firewall do jump. O jump conecta no web na porta 22, permitido pelo firewall do web e pelo PermitOpen web:22 no jump. O desk tentando o jump é recusado pelo firewall do jump, e o desk tentando o web direto é recusado pelo firewall do web, que conta a tentativa.\"><defs><marker id=\"l15-chain-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-chain-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"50.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">admin</text><text x=\"90.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.30</text><rect x=\"300.0\" y=\"50.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">jump</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.40</text><rect x=\"570.0\" y=\"50.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"630.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.10</text><rect x=\"300.0\" y=\"160.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"360.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.20</text><path d=\"M150.0 72.0 L300.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-chain-dh-ah-phosphor)\"></path><text x=\"225.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">ssh, permitido</text><path d=\"M420.0 72.0 L570.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-chain-dh-ah-phosphor)\"></path><text x=\"495.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">só web:22</text><path d=\"M360.0 160.0 L360.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15-chain-dh-ah-amber)\"></path><text x=\"370.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado pelo jump</text><path d=\"M420.0 182.0 L610.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15-chain-dh-ah-amber)\"></path><text x=\"530.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado e contado pelo web</text></svg>", "caption": "Cada seta é uma regra que dá para ler, e cada recusa é contada."}
```

Cada seta é permitida por uma regra que dá para ler, e cada recusa é contada por uma regra que dá para
ler. **Um caminho de acesso que dá para desenhar a partir das regras é um caminho que dá para
auditar**; um que existe porque ninguém escreveu regra contra ele é um que você vai descobrir por
outra pessoa.
