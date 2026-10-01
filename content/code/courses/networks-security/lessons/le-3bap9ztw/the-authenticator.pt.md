---
title: O autenticador
version: 1
---

Num switch de verdade, o 802.1X são algumas linhas de configuração por porta e o endereço de um servidor
RADIUS. No laboratório o switch é uma bridge do Linux, e o **hostapd** faz o papel de autenticador. O
daemon é mais conhecido por rodar pontos de acesso Wi-Fi, e o driver `wired` dele faz o mesmo trabalho
num cabo. Esta é a configuração da porta `p1`:

```
root@sw:~# cat hostapd-p1.conf
interface=p1
driver=wired
logger_stdout=-1
logger_stdout_level=2
ieee8021x=1
eap_server=1
eap_user_file=/root/eap_user
ca_cert=/root/ca.crt
server_cert=/root/server.crt
private_key=/root/server.key
ctrl_interface=/root/hostapd-ctrl
```

As linhas que importam:

- `ieee8021x=1` liga a autenticação da porta.
- `eap_server=1` faz o hostapd responder ele mesmo à troca EAP, em vez de encaminhá-la ao RADIUS. É o
  atalho do laboratório, e a troca que um servidor RADIUS conduziria é a mesma.
- `ca_cert` é a CA até a qual o certificado de um cliente precisa formar cadeia. `server_cert` e
  `private_key` são o certificado que o switch apresenta, para que o cliente confira que está falando com
  a rede verdadeira.
- `eap_user_file` nomeia o arquivo que diz qual método cada identidade precisa usar. Aqui ele tem uma
  linha só, `* TLS`: toda identidade precisa usar EAP-TLS, então nenhum método com senha é oferecido.

O hostapd decide e registra; ele não mexe no filtro de pacotes. A ligação entre os dois é um script curto
que o cliente de controle do hostapd executa a cada evento:

```schooling-example
{"language": "sh", "file": "port-control.sh", "parts": [{"code": "#!/bin/bash\n# called by hostapd_cli -a: $1 interface, $2 event, $3 the client's MAC\n# the port opens for that address alone, and the line in ports.log says who\ncase $2 in", "note": "O hostapd_cli chama o script com três argumentos: a porta, o nome do evento e o endereço MAC do cliente."}, {"code": "  AP-STA-CONNECTED)\n    nft add element netdev ports authorised \"{ $1 . $3 }\"", "note": "O sucesso abre a porta para aquele par, esta porta e este MAC, e nada mais amplo. O mesmo MAC em outra porta continua recusado."}, {"code": "    who=$(hostapd_cli -p /root/hostapd-ctrl -i \"$1\" sta \"$3\" | sed -n 's/^dot1xAuthSessionUserName=//p')\n    echo \"$(date +%FT%T%z) $1 $3 open $who\" >> /var/log/lab/ports.log ;;", "note": "Ele pergunta ao hostapd qual identidade se autenticou e escreve uma linha: quando, qual porta, qual MAC e quem."}, {"code": "  AP-STA-DISCONNECTED)\n    nft delete element netdev ports authorised \"{ $1 . $3 }\"\n    echo \"$(date +%FT%T%z) $1 $3 closed\" >> /var/log/lab/ports.log ;;\nesac", "note": "Um logoff, uma reautenticação que falhou ou um link perdido fecham a porta de novo, e dizem isso no mesmo log."}]}
```

Um switch comercial faz tudo isso internamente. Escrito por extenso, mostra a ordem que um switch segue:
a porta abre **porque** a autenticação deu certo, e para o único endereço que deu certo.

O administrador do switch inicia o daemon, com a configuração das duas portas, e um cliente de controle
por porta rodando o script:

```
root@sw:~# hostapd -B -f /var/log/lab/hostapd.log hostapd-p1.conf hostapd-p2.conf
root@sw:~# hostapd_cli -p /root/hostapd-ctrl -i p1 -a /root/port-control.sh -B
root@sw:~# hostapd_cli -p /root/hostapd-ctrl -i p2 -a /root/port-control.sh -B
```

Nenhuma saída quer dizer que cada um iniciou e foi para segundo plano; as mensagens do próprio hostapd vão
para `/var/log/lab/hostapd.log`, que as próximas seções leem.
