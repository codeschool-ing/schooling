---
title: O fail2ban, da linha de log ao banimento
version: 1
---

**O fail2ban lê logs, conta falhas por endereço e bane um endereço que falha demais.** É o HIPS mais
comum em servidores Linux, e o Ubuntu o instala com uma jail para o SSH já ligada. Olhe o que já está
lá antes de mudar qualquer coisa:

```
ana@web:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed:	0
|  |- Total failed:	0
|  `- Journal matches:	_SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned:	0
   |- Total banned:	0
   `- Banned IP list:	
ana@web:~$ sudo fail2ban-client get sshd maxretry; sudo fail2ban-client get sshd actions
5
The jail sshd has the following actions:
nftables
```

A jail existe e ainda não contou nada. Baniria depois de cinco falhas, e a ação dela é `nftables`, que
é o que o Ubuntu 24.04 define e aquilo com que o sistema filtra. **Essa escolha importa mais do que
parece.** Um banimento só é real se a ação tem efeito, e uma ação escrita para um firewall que a
máquina não usa falha com um erro num log que ninguém lê, enquanto o `fail2ban-client status` continua
listando o endereço como banido. Um HIPS cuja ação não tem efeito é um HIDS que acredita ser um HIPS,
então esta seção confere o banimento do outro lado.

Cinco é generoso. Uma pessoa que entra com chave raramente falha, e um chutador ganha duas tentativas a
mais do que precisa; três bastam. Salve isto como `jail.local` no `web`:

```schooling-example
{"language": "ini", "file": "jail.local", "parts": [{"code": "[sshd]\nenabled = true\nmaxretry = 3\nfindtime = 10m\nbantime = 10m", "note": "A jail do SSH: três falhas em dez minutos vindas de um endereço, e esse endereço é recusado por dez minutos. Cada número é uma troca, que a seção sobre ajuste pesa. Tudo o que não está escrito aqui, o log a ler e a ação que bane, fica como o Ubuntu deixou."}]}
```

O `jail.local` é lido depois do próprio `jail.conf` do pacote e o sobrescreve, então o arquivo do
pacote fica intocado para a próxima atualização. Copie-o e reinicie o fail2ban:

```
ana@web:~$ sudo cp jail.local /etc/fail2ban/ && sudo systemctl restart fail2ban && sleep 2 && sudo fail2ban-client get sshd maxretry
3
```

## Um cliente que insiste em falhar

A partir do `desk`, peça ao `web` quatro vezes uma conta que não existe. É a sua própria estação
falhando contra o seu próprio servidor, e isso é tudo o que o fail2ban precisa ver:

```
ana@desk:~$ for i in 1 2 3 4; do ssh -o BatchMode=yes visitor@web true; done
visitor@web: Permission denied (publickey,password).
visitor@web: Permission denied (publickey,password).
visitor@web: Permission denied (publickey,password).
visitor@web: Permission denied (publickey,password).
```

Quatro recusas, cada uma uma linha no journal do `web` dizendo que um usuário inválido tentou entrar a
partir de `192.168.60.20`. O fail2ban as lê à medida que chegam:

```
ana@web:~$ sleep 2; sudo fail2ban-client status sshd | tail -3
   |- Currently banned:	1
   |- Total banned:	1
   `- Banned IP list:	192.168.60.20
ana@web:~$ sudo nft list table inet f2b-table
table inet f2b-table {
	set addr-set-sshd {
		type ipv4_addr
		elements = { 192.168.60.20 }
	}

	chain f2b-chain {
		type filter hook input priority filter - 1; policy accept;
		tcp dport 22 ip saddr @addr-set-sshd reject with icmp port-unreachable
	}
}
ana@desk:~$ nc -zv -w3 web 22 2>&1; curl -s -m3 http://web/
nc: connect to web (192.168.60.10) port 22 (tcp) failed: Connection refused
Jatobá Contabilidade: client portal
```

O `desk` está banido. A tabela que o fail2ban fez para ele mora no `nftables` ao lado de todo o resto,
com um conjunto de endereços banidos e uma regra que os recusa na porta 22. Do `desk`, o SSH agora é
recusado, e o portal na porta 80 continua respondendo: `multiport` bane as portas da jail e mais nada,
então um cliente que errou uma senha não perde o site junto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l11-ban\" aria-label=\"Como o fail2ban transforma linhas de log num banimento. O sshd grava no journal uma linha por login que falhou. O filtro do fail2ban para o sshd casa a linha e tira dela o endereço. A jail conta as falhas por endereço dentro do findtime. No maxretry, a ação acrescenta o endereço a um conjunto no nftables, e uma regra ali o recusa na porta 22 durante o bantime.\"><defs><marker id=\"l11-ban-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sshd</text><text x=\"80.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">registra cada falha</text><path d=\"M140.0 88.0 L160.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"160.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">filtro</text><text x=\"220.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">acha o endereço</text><path d=\"M280.0 88.0 L300.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"300.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">jail</text><text x=\"360.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conta por endereço</text><path d=\"M420.0 88.0 L440.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ação</text><text x=\"500.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">põe num conjunto</text><path d=\"M560.0 88.0 L580.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-ban-dh-ah-paper-dim)\"></path><rect x=\"580.0\" y=\"60.0\" width=\"120.0\" height=\"56.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nftables</text><text x=\"640.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recusa a porta 22</text><text x=\"300.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">maxretry = 3, findtime = 10m</text><text x=\"580.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bantime = 10m</text><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">de uma linha de log a uma conexão recusada</text></svg>", "caption": "A última caixa é a que precisa ser conferida: um banimento só é real se o firewall recusar.", "same": ["jail", "nftables", "sshd"]}
```

O próprio log do fail2ban diz o que ele viu e o que fez, uma linha por falha e uma por banimento:

```
ana@web:~$ sudo grep -E "Found|Ban" /var/log/fail2ban.log | cut -d" " -f2,6-
09:30:21,329       [125]: INFO    [sshd] Found 192.168.60.20 - 2026-10-23 09:30:21
09:30:21,330       [125]: INFO    [sshd] Found 192.168.60.20 - 2026-10-23 09:30:21
09:30:21,330       [125]: INFO    [sshd] Found 192.168.60.20 - 2026-10-23 09:30:21
09:30:21,432      [125]: NOTICE  [sshd] Ban 192.168.60.20
```

## Tirando um banimento

Um banimento termina sozinho depois do `bantime`. Quando foi um colega que esqueceu a chave, ele
termina antes, à mão:

```
ana@web:~$ sudo fail2ban-client set sshd unbanip 192.168.60.20
1
ana@desk:~$ ssh web hostname
web
```

O banimento sai e o `desk` volta a entrar. **Uma pessoa tirando um banimento é um evento que vale uma
linha no registro de mudanças**, porque o próximo banimento do mesmo endereço é uma pergunta sobre se o
primeiro deveria ter sido tirado.
