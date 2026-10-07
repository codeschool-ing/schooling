---
title: Quem pode se conectar
version: 1
---

Todo controle deste curso até aqui confiou em uma coisa sem dizer: que o que estiver conectado à LAN
do escritório tem direito de estar ali. A aula 7 mostrou o que uma máquina no segmento pode fazer com as
vizinhas, e a aula 21 isolou os servidores uns dos outros. Nenhuma das duas faz a pergunta que está por
baixo: **quem decidiu que esta máquina podia entrar na rede?**

Na maioria das redes de escritório, ninguém decidiu. Uma tomada de rede na sala de reunião é uma porta
ativa de um switch, e um laptop ligado nela recebe um endereço, uma rota e a LAN inteira, seja de quem
for. **Controle de acesso à rede (NAC, *network access control*)** é o nome de transformar isso em uma
decisão. O **IEEE 802.1X** é a forma padrão de tomá-la numa porta de switch ou numa rede Wi-Fi.

O 802.1X nomeia três participantes:

| participante | nesta aula | sua função |
|---|---|---|
| **suplicante** (*supplicant*) | `newpc` e `visitor` | a máquina que pede para entrar, e o software nela que prova quem ela é |
| **autenticador** (*authenticator*) | `sw`, o switch de acesso | mantém a porta fechada, repassa a troca e abre a porta quando mandam |
| **servidor de autenticação** | o próprio servidor EAP do hostapd, dentro do `sw` | confere as credenciais e diz sim ou não; numa rede real, é um servidor **RADIUS** |

O autenticador nunca julga as credenciais por conta própria. Ele leva mensagens **EAP** entre os outros
dois, embrulhadas em quadros EAPOL (EAP over LAN) no cabo e em RADIUS no caminho até o servidor. É
essa divisão que permite a um único servidor de políticas decidir por centenas de switches e pontos de
acesso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"O 802.1X no switch de acesso do laboratório. newpc, na porta p1, é o suplicante e fala EAPOL com o switch, o autenticador. O switch repassa a troca ao servidor de autenticação, RADIUS numa rede real, e só abre p1 para a LAN do escritório depois do sucesso. visitor, na porta p2, oferece um certificado que ele mesmo assinou; o servidor recusa e p2 continua fechada para tudo menos EAPOL.\"><defs><marker id=\"dx-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dx-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dx-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">newpc</text><text x=\"30\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">suplicante</text><rect x=\"20\" y=\"150\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">visitor</text><text x=\"30\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">certificado próprio</text><rect x=\"280\" y=\"30\" width=\"170\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw</text><text x=\"290\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">autenticador</text><rect x=\"280\" y=\"72\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">p1</text><rect x=\"280\" y=\"160\" width=\"40\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">p2</text><path d=\"M170 72 L280 82\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-phosphor)\" marker-start=\"url(#dx-ah-phosphor)\"></path><text x=\"225\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">EAPOL</text><path d=\"M170 176 L280 173\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-amber)\" marker-start=\"url(#dx-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"225\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado</text><rect x=\"540\" y=\"30\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">servidor EAP</text><text x=\"550\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RADIUS numa rede real</text><path d=\"M450 55 L540 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-paper-dim)\" marker-start=\"url(#dx-ah-paper-dim)\"></path><text x=\"495\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RADIUS</text><rect x=\"540\" y=\"140\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">192.168.10.0/24</text><text x=\"550\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">LAN do escritório</text><path d=\"M450 160 L540 160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dx-ah-phosphor)\"></path><text x=\"495\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">depois do sucesso</text></svg>", "caption": "Três partes, e uma porta que fica fechada até a terceira dizer sim.", "same": ["EAPOL", "RADIUS"]}
```

O laboratório acrescenta um switch de acesso, o `sw`, à LAN do escritório. Na porta `p1` dele está um
laptop da empresa, o `newpc`, e na `p2` está o `visitor`, a máquina pessoal de alguém. Nenhum deles faz parte do
laboratório da aula 1, então esta aula os acrescenta com mais um script. Salve-o ao lado do `nslab.sh`
e rode-o depois do `reset`:

```sh
cd ~/nslab
sudo bash nslab.sh reset
sudo bash nac.sh
```

```schooling-example
{"language": "sh", "file": "nac.sh", "parts": [{"code": "#!/bin/bash\n# nac.sh: run after nslab.sh up, from the same directory.\n#   sudo bash nac.sh\nset -euo pipefail\nLAB=/lab\nME=${SUDO_USER:?run it with sudo, from your own account}\nca=\"$LAB/ca\"\n[ -e /run/netns/wire ] || { echo \"the lab is not up: sudo bash nslab.sh up\" >&2; exit 1; }\n[ -e /run/netns/sw ] && { echo \"the switch is already there: sudo bash nslab.sh reset, then run this again\" >&2; exit 1; }\nip netns add sw; ip -n sw link set lo up\nip -n sw link add br0 type bridge\nip link add up1 type veth peer name v-swup\nip link set up1 netns sw; ip -n sw link set up1 master br0\nip link set v-swup netns wire; ip -n wire link set v-swup master br-lan; ip -n wire link set v-swup up\nfor pair in \"p1 newpc 192.168.10.30 52:54:00:a8:0a:1e\" \"p2 visitor 192.168.10.31 52:54:00:a8:0a:1f\"; do\n  set -- $pair\n  ip netns add \"$2\"; ip -n \"$2\" link set lo up\n  ip link add \"$1\" type veth peer name lab-nac\n  ip link set \"$1\" netns sw; ip -n sw link set \"$1\" master br0; ip -n sw link set \"$1\" up\n  ip link set lab-nac netns \"$2\"; ip -n \"$2\" link set lab-nac name eth0\n  ip -n \"$2\" link set eth0 address \"$4\"\n  ip -n \"$2\" addr add \"$3/24\" dev eth0; ip -n \"$2\" link set eth0 up\n  ip -n \"$2\" route add default via 192.168.10.1\n  mkdir -p \"/etc/netns/$2\" \"$LAB/$2/root\" \"$LAB/$2/home/$ME\" \"$LAB/$2/var/log/lab\" \"$LAB/$2/run/wireguard\"\n  printf '%s\\n' \"$2\" > \"/etc/netns/$2/hostname\"\n  cp /etc/netns/laptop/hosts /etc/netns/laptop/resolv.conf \"/etc/netns/$2/\"\n  cp -a /etc/skel/. \"$LAB/$2/home/$ME/\"; chown -R \"$ME:\" \"$LAB/$2/home/$ME\"\ndone\nip -n sw link set up1 up; ip -n sw link set br0 up\nmkdir -p /etc/netns/sw \"$LAB/sw/root\" \"$LAB/sw/var/log/lab\" \"$LAB/sw/run/wireguard\"\nprintf 'sw\\n' > /etc/netns/sw/hostname", "note": "O switch de acesso da aula 22, acrescentado a um laboratório em funcionamento. O `sw` é um switch num namespace: uma bridge que liga o seu uplink, plugado na LAN da equipe, a duas portas de acesso, `p1` e `p2`. O `newpc` está ligado na primeira e o `visitor` na segunda."}, {"code": "( cd \"$ca\"\n  for n in \"nac.corp.example.com server DNS:nac.corp.example.com\" \"newpc.corp.example.com client\"; do\n    set -- $n\n    openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj \"/CN=$1\" -keyout \"$1.key\" -out \"$1.csr\" 2>/dev/null\n    { sed -n \"/^\\[$2\\]/,/^\\[/p\" ca.cnf | sed '$d'; [ -n \"${3:-}\" ] && echo \"subjectAltName = $3\"; } > \"$1.ext\"\n    openssl ca -batch -config ca.cnf -cert issuing.crt -keyfile issuing.key -extfile \"$1.ext\" -extensions \"$2\" \\\n      -startdate 20260928000000Z -enddate 20261228000000Z -in \"$1.csr\" -out \"$1.crt\" -notext 2>/dev/null\n  done )\ncp \"$ca/nac.corp.example.com.crt\" \"$LAB/sw/root/server.crt\"; cp \"$ca/nac.corp.example.com.key\" \"$LAB/sw/root/server.key\"\ncat \"$ca/issuing.crt\" \"$ca/root.crt\" > \"$LAB/sw/root/ca.crt\"\nfor h in newpc visitor; do cat \"$ca/issuing.crt\" \"$ca/root.crt\" > \"$LAB/$h/root/ca.crt\"; done\ncp \"$ca/newpc.corp.example.com.crt\" \"$LAB/newpc/root/client.crt\"; cp \"$ca/newpc.corp.example.com.key\" \"$LAB/newpc/root/client.key\"\nopenssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 -subj \"/CN=visitor\" \\\n  -keyout \"$LAB/visitor/root/client.key\" -out \"$LAB/visitor/root/client.crt\" 2>/dev/null", "note": "Os certificados, emitidos pela CA emissora da empresa: um para o autenticador, `nac.corp.example.com`, e um para o `newpc`. O `visitor` assina o seu próprio, que é tudo o que um dispositivo não gerenciado consegue oferecer."}, {"code": "for h in newpc visitor; do\n  cat > \"$LAB/$h/root/wpa.conf\" <<C\nctrl_interface=/root/wpa-ctrl\nap_scan=0\nnetwork={\n    key_mgmt=IEEE8021X\n    eap=TLS\n    identity=\"$h.corp.example.com\"\n    ca_cert=\"/root/ca.crt\"\n    client_cert=\"/root/client.crt\"\n    private_key=\"/root/client.key\"\n    eapol_flags=0\n}\nC\ndone\nfor port in p1 p2; do\n  cat > \"$LAB/sw/root/hostapd-$port.conf\" <<C\ninterface=$port\ndriver=wired\nlogger_stdout=-1\nlogger_stdout_level=2\nieee8021x=1\neap_server=1\neap_user_file=/root/eap_user\nca_cert=/root/ca.crt\nserver_cert=/root/server.crt\nprivate_key=/root/server.key\nctrl_interface=/root/hostapd-ctrl\nC\ndone\nprintf '* TLS\\n' > \"$LAB/sw/root/eap_user\"", "note": "A configuração do suplicante nas duas máquinas, `wpa.conf`, e a do autenticador no switch, uma por porta. A aula lê cada uma delas."}, {"code": "cat > \"$LAB/sw/root/port-control.sh\" <<'SH'\n#!/bin/bash\n# called by hostapd_cli -a: $1 interface, $2 event, $3 the client's MAC\n# the port opens for that address alone, and the line in ports.log says who\ncase $2 in\n  AP-STA-CONNECTED)\n    nft add element netdev ports authorised \"{ $1 . $3 }\"\n    who=$(hostapd_cli -p /root/hostapd-ctrl -i \"$1\" sta \"$3\" | sed -n 's/^dot1xAuthSessionUserName=//p')\n    echo \"$(date +%FT%T%z) $1 $3 open $who\" >> /var/log/lab/ports.log ;;\n  AP-STA-DISCONNECTED)\n    nft delete element netdev ports authorised \"{ $1 . $3 }\"\n    echo \"$(date +%FT%T%z) $1 $3 closed\" >> /var/log/lab/ports.log ;;\nesac\nSH\nchmod +x \"$LAB/sw/root/port-control.sh\"\ncat > \"$LAB/sw/root/ports.nft\" <<'NFT'\ntable netdev ports {\n\tset authorised {\n\t\ttype ifname . ether_addr\n\t}\n\n\tchain p1 {\n\t\ttype filter hook ingress device \"p1\" priority filter; policy drop;\n\t\tether type 0x888e accept\n\t\tiifname . ether saddr @authorised accept\n\t}\n\n\tchain p2 {\n\t\ttype filter hook ingress device \"p2\" priority filter; policy drop;\n\t\tether type 0x888e accept\n\t\tiifname . ether saddr @authorised accept\n\t}\n}\nNFT\nip netns exec sw nft -f \"$LAB/sw/root/ports.nft\"", "note": "Um switch de verdade mantém fechada no hardware uma porta não autenticada, e uma bridge Linux não. Então o `port-control.sh` e o `ports.nft` fazem isso do jeito que a aula descreve: cada porta não deixa passar nada além de quadros 802.1X até o hostapd informar um cliente autorizado, e então só o MAC desse cliente."}]}
```

Antes de qualquer autenticação, o filtro do switch é este:

```
root@sw:~# nft list table netdev ports
table netdev ports {
	set authorised {
		type ifname . ether_addr
	}

	chain p1 {
		type filter hook ingress device "p1" priority filter; policy drop;
		ether type 0x888e accept
		iifname . ether saddr @authorised accept
	}

	chain p2 {
		type filter hook ingress device "p2" priority filter; policy drop;
		ether type 0x888e accept
		iifname . ether saddr @authorised accept
	}
}
```

A chain de entrada de cada porta descarta por padrão. A única coisa que ela aceita é o EtherType
`0x888e`, que é o EAPOL, porque a máquina precisa de algum jeito de pedir. Todo o resto espera que a sua
porta e o seu endereço apareçam no conjunto `authorised`, que está vazio.

Então o `newpc` tem um endereço e um cabo, e nenhum lugar para ir:

```
ana@newpc:~$ ip -br address show eth0
eth0@if1856      UP             192.168.10.30/24 
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1025ms
```

**O endereço não é o acesso.** Ele configurou `192.168.10.30` na própria interface, mas nenhum quadro
além do EAPOL chega à LAN ainda, nem o ARP.
