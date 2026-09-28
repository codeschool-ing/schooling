---
title: Related, invalid, e a leitura dos contadores
version: 1
---

Dois estados são fáceis de escrever e fáceis de entender errado.

**`related` é o que deixa um erro voltar.** Quando um pacote não pode ser entregue, o roteador ou o
host que falhou responde com uma mensagem ICMP, e essa mensagem não faz parte do fluxo da própria
conversa: tem protocolo e endereços próprios. O conntrack a reconhece como pertencente a uma entrada
conhecida e a marca como `related`.

Este conjunto de regras separa os dois estados em regras distintas, para que cada um tenha o seu
contador, e deixa a LAN perguntar duas coisas na porta UDP 53: ao servidor de nomes de verdade na
DMZ, e a `app`, que não roda DNS nenhum:

```
root@fw:~# nft -f related.nft
ana@laptop:~$ dig +short @192.0.2.53 www.example.com
192.0.2.80
```

A resposta voltou como `established`, e a tabela mostra a entrada UDP com que ela casou: `29`
segundos restantes, porque o UDP não tem handshake e o conntrack simplesmente esquece um fluxo
parado. Agora a pergunta a `app`:

```
root@fw:~# conntrack -L -p udp 2>/dev/null
udp      17 29 src=192.168.10.20 dst=192.0.2.53 sport=44628 dport=53 src=192.0.2.53 dst=192.168.10.20 sport=53 dport=44628 mark=0 use=1
ana@laptop:~$ dig +tries=1 @192.168.20.10 www.example.com
;; communications error to 192.168.20.10#53: connection refused

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> +tries=1 @192.168.20.10 www.example.com
; (1 server found)
;; global options: +cmd
;; no servers could be reached
```

`app` respondeu à pergunta com um ICMP *port unreachable*, e a regra `related` o deixou passar, um
pacote de 112 bytes. **O `dig` relatou a recusa na hora, em vez de esperar o próprio tempo
esgotar.** Tire o `related` e todo erro desses some no firewall, e os programas esperam e tentam de
novo onde poderiam ter falhado de imediato. Pior: a mensagem ICMP que avisa quem envia que seus
pacotes são grandes demais também é `related`, e perdê-la quebra conexões de jeitos que parecem
qualquer coisa, menos um firewall.

**`invalid` é descartado de propósito.** Um pacote que não pertence a conversa nenhuma e não pode
iniciar uma, como uma confirmação TCP para uma conexão que a tabela nunca viu, não tem o que fazer
aqui.

## Os contadores dizem o que as regras fizeram de fato

Uma regra com `counter` conta os pacotes e bytes com que casou. Depois de três pedidos do `laptop` e
uma tentativa de `remote` no banco de dados:

```
root@fw:~# nft -f stateful.nft
ana@laptop:~$ for i in 1 2 3; do curl -s -m2 -o /dev/null http://192.168.20.10:8080/health; done
ana@remote:~$ nc -w2 192.168.20.30 5432 </dev/null; echo "exit $?"
exit 1
root@fw:~# nft list chain ip filter forward
table ip filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related counter packets 34 bytes 2689 accept
		ct state invalid counter packets 0 bytes 0 drop
		iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new counter packets 3 bytes 180 accept
		counter packets 2 bytes 120 comment "everything else, about to be dropped"
	}
}
```

Leia de baixo para cima. A última linha não tem veredito próprio, então só conta o que passou por
todas as regras: os dois pacotes de `remote`, a primeira tentativa e uma retransmissão, logo antes
de a política descartá-los. A regra de `new` casou com **três pacotes**, um por pedido, porque uma
conversa começa uma vez só. Todo o resto, 34 pacotes, foi tráfego `established`.

**Essa proporção é normal e vale guardar.** Num firewall movimentado, quase todo pacote bate na
primeira regra, e é por isso que ela é a primeira. A aula 18 volta ao que custa a ordem das regras.
