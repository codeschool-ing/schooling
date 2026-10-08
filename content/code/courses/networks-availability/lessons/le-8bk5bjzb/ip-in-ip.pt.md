---
title: IP-in-IP, o menor túnel que existe
version: 1
---

**IP-in-IP coloca um pacote IP logo depois de outro cabeçalho IP, sem nada entre os dois.** É o
protocolo número 4, e num roteador Linux comum um comando o cria:
`ip link add tun0 type ipip local 203.0.113.2 remote 198.51.100.2`. Este curso monta o mesmo túnel com
um programa pequeno, `tunnel.py`, mostrado inteiro no fim desta seção. Ele mostra que um túnel não tem
nada escondido, e funciona em qualquer kernel, inclusive no kernel em que estas transcrições foram
gravadas, que veio sem o módulo de IP-in-IP. O que ele põe no fio é IP-in-IP padrão, e o `tcpdump` o
decodifica como tal.

Salve-o antes de qualquer outra coisa. Copie a listagem do fim desta seção com o botão dela e, na própria
máquina virtual:

```sh
nano tunnel.py                                  # paste, then Ctrl+O and Ctrl+X
sudo install -m 755 tunnel.py /usr/local/bin/
```

Todas as máquinas da rede enxergam o mesmo `/usr/local/bin`, então essa única cópia serve às duas pontas.

Em `hq` o túnel é uma interface de rede como qualquer outra. Ganha um endereço em cada ponta, e uma rota
manda a rede da filial para dentro dele:

```
ana@hq:~$ sudo setsid tunnel.py ipip tun0 203.0.113.2 198.51.100.2 & sleep 1; ip -br link show tun0
tun0             DOWN           <POINTOPOINT,MULTICAST,NOARP> 
ana@hq:~$ sudo ip addr add 10.0.0.1 peer 10.0.0.2 dev tun0 && sudo ip link set tun0 mtu 1480 up
ana@hq:~$ sudo ip route add 192.168.20.0/24 via 10.0.0.2
```

`POINTOPOINT` diz que existe exatamente uma máquina do outro lado, e `NOARP` diz que ninguém precisa
perguntar o endereço de hardware dela, porque não há hardware. Os endereços `10.0.0.x` pertencem ao
próprio túnel, e a rota é a linha que importa: **tudo que for para `192.168.20.0/24` entra em `tun0`**.
`branch` recebe o espelho disso, digitado num shell próprio, e a tabela de rotas dele mostra o caminho de
volta:

```
ana@branch:~$ sudo setsid tunnel.py ipip tun0 198.51.100.2 203.0.113.2 & sleep 1; sudo ip addr add 10.0.0.2 peer 10.0.0.1 dev tun0 && sudo ip link set tun0 mtu 1480 up && sudo ip route add 192.168.10.0/24 via 10.0.0.1
ana@branch:~$ ip route
default via 198.51.100.1 dev eth1 
10.0.0.1 dev tun0 proto kernel scope link src 10.0.0.2 
192.168.10.0/24 via 10.0.0.1 dev tun0 
192.168.20.0/24 dev eth0 proto kernel scope link src 192.168.20.1 
198.51.100.0/24 dev eth1 proto kernel scope link src 198.51.100.2 
ana@laptop:~$ ping -c 2 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=1 ttl=62 time=2.19 ms
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=0.918 ms

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.918/1.556/2.194/0.638 ms
```

O ping que falhou uma seção atrás agora funciona, e o laptop não fez nada diferente. O `ttl=62` merece
uma olhada: a resposta saiu do caixa com 64 e perdeu um em `branch` e um em `hq`. **O roteador do
provedor não entra na conta**, porque nunca viu o pacote interno, só o externo.

## No fio

Do lado do provedor, capturando no enlace que vai para `hq`, os dois cabeçalhos aparecem:

```
ana@isp:~$ sudo tcpdump -n -t -i eth0 -c 2 ip proto 4
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 203.0.113.2 > 198.51.100.2: IP 192.168.10.20 > 192.168.20.30: ICMP echo request, id 59233, seq 1, length 64
IP 198.51.100.2 > 203.0.113.2: IP 192.168.20.30 > 192.168.10.20: ICMP echo reply, id 59233, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 1 ip proto 4
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 63671, offset 0, flags [DF], proto IPIP (4), length 104)
    203.0.113.2 > 198.51.100.2: IP (tos 0x0, ttl 63, id 15055, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.168.20.30: ICMP echo request, id 59234, seq 1, length 64
```

Cada linha se lê da esquerda para a direita como dois pacotes, um dentro do outro: de `203.0.113.2` para
`198.51.100.2`, e dentro dele do laptop para o caixa. Com `-v` aparecem os tamanhos. O pacote interno
tem **84 bytes**, o externo **104**, e a diferença é o único cabeçalho que o IP-in-IP acrescenta. O
cabeçalho externo diz `proto IPIP (4)`, e é assim que o roteador que recebe sabe que precisa olhar dentro.

## O programa por trás

`tunnel.py` é o túnel inteiro, em umas cinquenta linhas. Ele está aqui porque mostra que um túnel não
tem mágica: ler um pacote, pôr um cabeçalho na frente, enviar; receber um pacote, tirar o cabeçalho,
entregar.

```schooling-example
{"language": "python", "file": "tunnel.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"A point-to-point tunnel: packets read from a TUN device leave inside an\nouter IPv4 header, and packets arriving inside one are written back to it.\n\n    tunnel.py gre|ipip NAME LOCAL REMOTE [KEY]\n\"\"\"", "note": "O que ele é e como se chama. Os cinco argumentos são toda a configuração: qual dos dois formatos, o nome do dispositivo, o endereço público desta ponta, o da outra ponta e uma chave para o GRE."}, {"code": "import fcntl, os, select, socket, struct, sys"}, {"code": "mode, name, local, remote = sys.argv[1:5]\nkey = int(sys.argv[5]) if len(sys.argv) > 5 else None", "note": "Os argumentos, lidos em ordem. A chave é opcional, e só o GRE tem onde guardá-la."}, {"code": "TUNSETIFF, IFF_TUN, IFF_NO_PI = 0x400454ca, 0x0001, 0x1000\ntun = os.open(\"/dev/net/tun\", os.O_RDWR)\nfcntl.ioctl(tun, TUNSETIFF, struct.pack(\"16sH\", name.encode(), IFF_TUN | IFF_NO_PI))", "note": "Pede ao kernel um dispositivo TUN: uma interface de rede cujo outro lado é este programa. O que o kernel rotear para `tun0` sai de `os.read(tun)` como um pacote IP puro, e o que for escrito nele volta como se tivesse chegado por um cabo."}, {"code": "proto = 47 if mode == \"gre\" else 4        # the outer header's protocol field\nwire = socket.socket(socket.AF_INET, socket.SOCK_RAW, proto)\nwire.bind((local, 0))", "note": "Um socket raw para um número de protocolo IP, 47 para GRE ou 4 para IP-in-IP. O próprio kernel escreve o cabeçalho IP externo, com o endereço desta máquina como origem, então o programa nunca monta um."}, {"code": "def wrap(packet):\n    if mode == \"ipip\":\n        return packet                     # nothing between the two IP headers\n    flags = 0x2000 if key is not None else 0     # K bit: a key follows\n    head = struct.pack(\"!HH\", flags, 0x0800)     # 0x0800: the payload is IPv4\n    if key is not None:\n        head += struct.pack(\"!I\", key)\n    return head + packet", "note": "Na saída. Para IP-in-IP não há nada a acrescentar: o pacote é a carga. Para GRE, quatro bytes de cabeçalho vão na frente, os dois últimos dizendo `0x0800`, IPv4 dentro, e mais quatro levam a chave quando existe uma."}, {"code": "def unwrap(outer):\n    inner = outer[(outer[0] & 0x0F) * 4:]  # skip the outer IP header\n    if mode == \"ipip\":\n        return inner\n    flags, ptype = struct.unpack(\"!HH\", inner[:4])\n    if ptype != 0x0800:\n        return None\n    if flags & 0x2000:\n        if struct.unpack(\"!I\", inner[4:8])[0] != key:\n            return None                   # another tunnel's key: not ours\n        return inner[8:]\n    return None if key is not None else inner[4:]", "note": "Na chegada, o inverso. Um socket raw entrega o pacote inteiro, cabeçalho externo incluído, então o tamanho dele é lido do primeiro byte e pulado. Um pacote GRE com a chave errada, ou sem chave quando se espera uma, é descartado: essa é a verificação que a chave compra."}, {"code": "while True:\n    ready, _, _ = select.select([tun, wire], [], [])\n    try:\n        if tun in ready:\n            wire.sendto(wrap(os.read(tun, 65535)), (remote, 0))\n        if wire in ready:\n            outer, (src, _) = wire.recvfrom(65535)\n            packet = unwrap(outer) if src == remote else None\n            if packet:\n                os.write(tun, packet)\n    except OSError:\n        pass    # an ICMP error came back from the far end: this packet is\n                # lost, as it would be in the kernel's own tunnel", "note": "O túnel inteiro. Espera até qualquer um dos lados ter um pacote, passa-o para o outro e repete. Um pacote vindo de qualquer endereço que não seja a outra ponta é ignorado, e um erro ICMP da outra ponta custa um pacote, não o programa."}]}
```

A implementação do próprio kernel faz o mesmo trabalho sem passar pelo espaço de usuário, e é por isso
que um roteador de verdade usa a dela. O formato no fio é idêntico, e é a única coisa que a outra ponta
consegue ver.
