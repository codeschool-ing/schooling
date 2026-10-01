---
title: Feeds de inteligência de ameaças
version: 1
---

A aula 2 listou os **feeds de inteligência de ameaças (threat intelligence feeds)** entre o que um
firewall de nova geração acrescenta: listas de endereços, nomes de domínio e hashes de arquivos que
alguém viu se comportando mal, publicadas para que outros bloqueiem. Vêm de fornecedores comerciais, de
equipes nacionais de resposta e de projetos abertos. O que chega é um arquivo, e este é o do
laboratório:

```
root@admin:~# cat feed.txt
# example-intel.org list, 2026-09-28, addresses seen scanning for exposed secrets
203.0.113.50
198.51.100.23
198.51.100.140
```

Um feed só vale o que valem a sua data e o seu motivo. Este diz quem o publicou, quando, e o que os
endereços estavam fazendo. Uma lista sem isso é uma lista que ninguém consegue revisar.

**O primeiro uso é olhar para trás.** Antes de bloquear qualquer coisa, a pergunta que vale fazer é se
algum desses endereços já falou conosco. A coleção em `admin` responde:

```
root@admin:~# grep -v '^#' feed.txt | while read a; do jq -r --arg a $a 'select(.src_ip == $a) | .src_ip' /var/log/lab/remote/fw/flows.json /var/log/lab/remote/fw/drops.json; done | sort | uniq -c
      6 203.0.113.50
```

Seis registros de `203.0.113.50`: os dois fluxos e os quatro descartes de antes. Os outros dois
endereços nunca apareceram. Esse olhar para trás, feito sobre meses de registros de fluxo, é muitas
vezes como uma intrusão é descoberta: um endereço citado hoje no relatório de outra pessoa acaba tendo
visitado em julho.

**O segundo uso é bloquear.** O feed vai para um conjunto cujos elementos expiram, e uma regra no topo
da chain forward descarta e registra tudo o que vem dele:

```
root@fw:~# nft add set ip filter intel "{ type ipv4_addr; flags timeout; timeout 1d; }"
root@fw:~# nft 'insert rule ip filter forward ip saddr @intel log group 1 prefix "intel-drop" drop'
root@fw:~# nft add element ip filter intel "{ 203.0.113.50, 198.51.100.23, 198.51.100.140 }"
root@fw:~# nft list set ip filter intel
table ip filter {
	set intel {
		type ipv4_addr
		timeout 1d
		elements = { 198.51.100.23 expires 23h59m59s968ms, 198.51.100.140 expires 23h59m59s968ms,
			     203.0.113.50 expires 23h59m59s968ms }
	}
}
```

`timeout 1d` não é detalhe. Um endereço em um feed hoje pode pertencer a outra pessoa no mês que vem:
endereços de nuvem são reatribuídos, e um único endereço compartilhado pode estar na frente de uma rede
móvel inteira. Uma entrada que é renovada enquanto o feed ainda a lista, e sai quando ele deixa de
listá-la, impede que o bloqueio sobreviva ao seu motivo.

`remote` agora é recusado, e `branch`, no mesmo segmento de internet e fora da lista, não é:

```
ana@remote:~$ curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://www.example.com/
000
ana@branch:~$ curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://www.example.com/
200
```

As recusas levam um prefixo próprio, então um relatório consegue distingui-las das da política:

```
root@admin:~# tail -3 /var/log/lab/remote/fw/drops.json | jq -c '[.src_ip, .dest_port, ."oob.prefix"]'
["203.0.113.50",80,"intel-drop"]
["203.0.113.50",80,"intel-drop"]
["203.0.113.50",80,"intel-drop"]
```

Duas ressalvas. **Um feed é o julgamento de outra pessoa**, então seus bloqueios merecem a mesma
revisão que as próprias regras do firewall, e um cliente que não consegue chegar à loja por causa de um
feed é um custo real. E **uma regra de feed posta em primeiro lugar vê tudo**, inclusive respostas a
conexões que começaram dentro; em geral é isso que se quer, e deve ser decidido em vez de descoberto.
