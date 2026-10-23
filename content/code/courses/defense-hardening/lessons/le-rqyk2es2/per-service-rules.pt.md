---
title: Regras por serviço
version: 1
---

**O systemd inicia cada serviço num grupo de controle próprio, e um grupo de controle pode carregar
regras de rede.** O grupo é o serviço: todo processo que o serviço inicia, com qualquer conta, fica
nele. Isso dá mais dois jeitos de escrever uma regra sobre um programa, e os dois sobrevivem a uma
troca de conta que a regra por conta não sobrevive.

## Na unidade, com o systemd

O systemd consegue negar acesso à rede a um serviço por endereço, escrito na própria configuração do
serviço. Salve isto no `web` como `10-network.conf`; é um drop-in, um arquivo que acrescenta opções a
uma unidade sem editar o arquivo da própria unidade:

```schooling-example
{"language": "ini", "file": "10-network.conf", "parts": [{"code": "[Service]\nIPAddressDeny=any\nIPAddressAllow=localhost", "note": "A mesma promessa, feita pelo systemd em vez do firewall: todo endereço é negado a este serviço, menos a faixa de loopback. O systemd a impõe com um pequeno filtro preso ao grupo de controle do próprio serviço, então ela acompanha o serviço aonde ele for rodar, e fica escrita ao lado do serviço, e não num conjunto de regras que outra pessoa mantém."}]}
```

Ponha-o no diretório de drop-ins do portal, recarregue o systemd para que ele o leia e reinicie o
portal:

```
ana@web:~$ sudo mkdir -p /etc/systemd/system/portal.service.d && sudo cp 10-network.conf /etc/systemd/system/portal.service.d/
ana@web:~$ sudo systemctl daemon-reload && sudo systemctl restart portal && systemctl show portal -p IPAddressDeny -p IPAddressAllow
IPAddressAllow=::1/128 127.0.0.0/8
IPAddressDeny=0.0.0.0/0 ::/0
ana@desk:~$ curl -s http://web/
Jatobá Contabilidade: client portal
```

O systemd aceitou as opções e as mostra, convertidas em faixas de endereços, e o portal continua
servindo o `desk`. Agora confira se a regra recusa alguma coisa, que é a parte que as pessoas pulam.
Um serviço avulso com as mesmas duas opções, pedindo para alcançar o `desk`:

```
ana@web:~$ sudo systemd-run -q --wait --pipe -p IPAddressDeny=any -p IPAddressAllow=localhost nc -zv -w2 desk 22 2>&1
Connection to desk (192.168.60.20) 22 port [tcp/ssh] succeeded!
```

**Conectou.** As opções estão em vigor no papel e não fazem nada aqui. O systemd as impõe com
pequenos programas BPF presos ao grupo de controle do serviço, e dentro dos contêineres deste
laboratório o kernel não deixa o systemd prendê-los; o systemd segue sem eles e sem erro na tela. Na
sua própria máquina virtual, fora dos contêineres, o mesmo comando é recusado pelo kernel, como a
documentação do systemd descreve; isso não foi executado para este curso.

Essa é a regra da aula 1 na forma mais afiada: **uma configuração é uma afirmação até um cliente ser
recusado.** Uma configuração de firewall que em silêncio não faz nada é pior que nenhuma, porque todo
mundo acredita nela.

## No nftables, por grupo de controle

O nftables consegue casar o grupo de controle a que um socket pertence pelo caminho dele, que é como
uma regra de firewall nomeia um serviço em vez de uma conta. Há uma surpresa, e o primeiro comando a
mostra:

```
ana@web:~$ sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/probe.service" counter reject
Error: cgroupv2 path fails: No such file or directory
add rule inet portal_out output socket cgroupv2 level 2 system.slice/probe.service counter reject
                                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^
ana@web:~$ sudo systemd-run -q --unit probe sh -c "sleep 3; nc -zv -w2 desk 22"
ana@web:~$ sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/probe.service" counter reject
ana@web:~$ sleep 4; sudo journalctl -u probe -o cat --no-pager | grep nc:
nc: connect to desk (192.168.60.20) port 22 (tcp) failed: Connection refused
ana@web:~$ sudo nft add rule inet portal_out output socket cgroupv2 level 2 "system.slice/portal.service" counter
ana@desk:~$ for i in 1 2 3; do curl -s -o /dev/null http://web/; done
ana@web:~$ sudo nft list chain inet portal_out output | grep cgroupv2
		socket cgroupv2 level 2 27005 counter packets 1 bytes 60 reject
		socket cgroupv2 level 2 "system.slice/portal.service" counter packets 6 bytes 312
```

A primeira tentativa falha porque **o nftables procura o grupo no momento em que a regra é
carregada**, e um serviço que não está rodando não tem grupo. Então a segunda tentativa inicia o
serviço antes, uma sonda que espera três segundos e depois tenta o `desk`, e acrescenta a regra
enquanto ela espera. A conexão da sonda é recusada, e desta vez a recusa vem da regra. Uma segunda
regra, que só conta, mostra os pacotes do próprio portal sendo atribuídos ao `portal.service`.

Veja como a listagem imprime a regra da sonda agora que a sonda terminou: um número onde estava o
caminho. A regra guarda a identidade do grupo, não o nome, e um serviço reiniciado ganha um grupo
novo. **Uma regra escrita assim tem de ser recarregada toda vez que o serviço sobe**, e por isso ela
pertence à inicialização do próprio serviço, ou por isso a regra por conta da seção anterior costuma
ser a escolha mais simples.
