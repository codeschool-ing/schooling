---
title: Um escritório, e mais duas redes
version: 2
---

Para ver um convidado pelo outro lado, precisa existir um outro lado. Num escritório, é a rede do
escritório, e um convidado em ponte entra nela pela placa do próprio host. Fazer isso na rede da sua casa
traz os riscos que a seção 06 lista, e um notebook no Wi-Fi quase nunca consegue, porque a maioria das
placas sem fio se recusa a levar quadros de endereços que não sejam os dela. Então esta aula monta uma
rede de escritório pequena **dentro do host**, do mesmo jeito em qualquer computador. Salve isto como
`office.sh`:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# office.sh: a small office network on this computer, for lessons 11 and 15.\n# sudo bash office.sh        builds it\n# sudo bash office.sh down   takes it away\nset -euo pipefail\nif [ \"${1:-}\" = down ]; then\n  kill \"$(cat /run/office-dhcp.pid)\" 2>/dev/null || true\n  ip netns pids printer 2>/dev/null | xargs -r kill 2>/dev/null || true\n  ip netns del printer 2>/dev/null || true\n  ip link del lan0 2>/dev/null || true\n  exit\nfi\nip link show lan0 >/dev/null 2>&1 && { echo \"the office is already up\"; exit; }", "note": "Rode como root, porque cada linha muda a rede do host. `down` desfaz tudo, na ordem inversa, e uma segunda execução com o escritório já de pé diz isso em vez de falhar no meio."}, {"code": "ip link add lan0 type bridge\nip addr add 10.0.0.1/24 dev lan0\nip link set lan0 up", "note": "O switch do escritório: uma **ponte** chamada `lan0`, com o host nela em `10.0.0.1`. Numa rede de escritório de verdade, isso é o switch na parede, e a placa do host está ligada nele."}, {"code": "ip netns add printer\nip link add prn0 type veth peer name prn0-lan\nip link set prn0-lan master lan0 up\nip link set prn0 netns printer\nip -n printer addr add 10.0.0.50/24 dev prn0\nip -n printer link set prn0 up\nip -n printer link set lo up", "note": "A impressora. Um **namespace de rede** é uma segunda pilha de rede, separada, dentro do mesmo kernel, com placas e endereços próprios, que é todo o computador de que uma impressora precisa. Um par **veth** é um cabo com duas pontas: uma entra no namespace como a placa da impressora, `10.0.0.50`, e a outra é ligada na `lan0`."}, {"code": "ip netns exec printer dnsmasq --interface=prn0 --bind-interfaces --port=0 \\\n  --dhcp-range=10.0.0.100,10.0.0.150,12h --dhcp-option=option:router,10.0.0.1 \\\n  --dhcp-leasefile=/run/office-dhcp.leases --pid-file=/run/office-dhcp.pid", "note": "O DHCP do escritório, rodado pela impressora: endereços de `10.0.0.100` a `10.0.0.150`, com o host como saída. O `dnsmasq` é o mesmo programa que o libvirt usa nas próprias redes. `--port=0` desliga o DNS dele, porque aqui só o DHCP interessa, e o arquivo de concessões é onde a aula 11 lê quem recebeu o quê."}, {"code": "mkdir -p /var/tmp/office-www\necho \"office printer: ready\" > /var/tmp/office-www/index.html\nip netns exec printer setsid python3 -m http.server 80 --directory /var/tmp/office-www \\\n  >/var/log/office-http.log 2>&1 < /dev/null &\nfor i in $(seq 40); do\n  ip netns exec printer bash -c ': > /dev/tcp/127.0.0.1/80' 2>/dev/null && break\n  sleep 0.25\ndone", "note": "A página web da impressora: o servidor web que vem com o Python, que escreve uma linha por visitante em `/var/log/office-http.log`. O laço espera até dez segundos que ele responda, para o próximo comando não sair na frente."}]}
```

É uma ponte chamada `lan0`, onde o host é `10.0.0.1`, e um outro aparelho nela, uma **impressora** em
`10.0.0.50` que responde a pedidos web, anota quem pediu e roda o DHCP do escritório. Uma conferência
antes de rodar: se o `ip -br addr` do seu computador já mostra um endereço começando com `10.0.0.`, a sua
rede de verdade usa essa faixa, e o escritório a esconderia. Escolha outra, por exemplo `10.99.0.`, e troque
em todo lugar, no script e nos comandos desta aula. Depois, `sudo bash office.sh`, e o escritório está lá:

```
ana@host:~$ ip -br addr show lan0
lan0             UP             10.0.0.1/24 
ana@host:~$ curl -sS http://10.0.0.50/
office printer: ready
```

Depois, duas redes do libvirt, cada uma descrita em algumas linhas de XML. A `lan` é **em ponte**: une
os convidados à própria `lan0`, a rede do escritório, sem NAT e sem DHCP do libvirt. A `isolated` tem
endereço e faixa de DHCP mas **nenhum elemento `forward`**, então nada que ela carrega vai para outro
lugar:

```
ana@host:~$ cat lan.xml
<network>
  <name>lan</name>
  <forward mode="bridge"/>
  <bridge name="lan0"/>
</network>
ana@host:~$ virsh net-define lan.xml && virsh net-start lan
Network lan defined from lan.xml

Network lan started

ana@host:~$ cat isolated.xml
<network>
  <name>isolated</name>
  <bridge name="virbr1"/>
  <ip address="10.10.10.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.10.10.10" end="10.10.10.50"/>
    </dhcp>
  </ip>
</network>
ana@host:~$ virsh net-define isolated.xml && virsh net-start isolated
Network isolated defined from isolated.xml

Network isolated started

ana@host:~$ virsh net-list
 Name       State    Autostart   Persistent
---------------------------------------------
 default    active   yes         yes
 isolated   active   no          yes
 lan        active   no          yes
```

Num host de verdade, uma rede em ponte é unida à placa real do host, e a ponte precisa existir antes: o
Ubuntu faz uma com o netplan, o Proxmox fez a `vmbr0` na instalação, aula 6. Depois foi feito um
convidado em cada rede com o `newvm.sh` da aula 1, com a rede como segundo argumento: a `vmn` na
`default`, a `vmb` na `lan`, a `vmi` na `isolated`. O disco base tem o nginx instalado e desligado, então
`ssh vmn sudo systemctl start nginx`, e o mesmo na vmb, deu a duas delas uma página para servir.
