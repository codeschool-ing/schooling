---
title: "O balanceador de carga: um endereço, vários servidores"
version: 1
---

Um site movimentado não é uma máquina, mas o endereço dele é um endereço só. **Um balanceador de
carga é dono do endereço público e entrega cada conexão nova a um dos vários servidores atrás
dele**, e assim os servidores podem ser acrescentados, retirados ou reiniciados sem que ninguém de
fora perceba. O engano comum é pensar nele como um roteador com uma lista de servidores. Um roteador
encaminha um pacote para onde o destino já está; um balanceador de carga **troca** o destino,
escolhendo-o a cada conexão.

O balanceador do laboratório é o lb, em 192.0.2.80, com dois servidores web atrás. A configuração
inteira é uma regra em cada sentido:

```
root@lb:~# nft list table ip lb
table ip lb {
	chain prerouting {
		type nat hook prerouting priority dstnat; policy accept;
		ip daddr 192.0.2.80 tcp dport 80 dnat to numgen inc mod 2 map { 0 : 10.99.0.11, 1 : 10.99.0.18 }
	}

	chain postrouting {
		type nat hook postrouting priority srcnat; policy accept;
		oifname { "eth1", "eth2" } masquerade
	}
}
```

A regra de `prerouting` se lê como uma frase: um pacote para `192.0.2.80`, porta TCP `80`, tem o
destino reescrito (`dnat`) para um de dois endereços, escolhido por `numgen inc mod 2`, um contador
que sobe um a cada conexão nova e é tomado módulo 2. Contador 0 é o web1, em 10.99.0.11; contador 1
é o web2, em 10.99.0.18. **Usar os servidores na sua vez, assim, se chama round robin.** A regra de
`postrouting` reescreve também a origem, de modo que os servidores web respondem ao balanceador e o
balanceador responde ao cliente.

Quatro pedidos do pc1, um do pc2, e uma olhada no endereço do próprio web1:

```
ana@pc1:~$ for i in 1 2 3 4; do curl -s http://192.0.2.80/; done
served by web2
served by web1
served by web2
served by web1
ana@pc2:~$ curl -s http://192.0.2.80/
served by web2
root@web1:~# ip -br addr show eth0
eth0@if38        UP             10.99.0.11/28 fe80::a2:feff:fe90:d6b3/64 
```

Os quatro pedidos do pc1 foram **web2, web1, web2, web1**. O único pedido do pc2 foi para o web2,
que é a vez seguinte do mesmo contador, e não um recomeço para um cliente novo: **este balanceador
conta conexões, não clientes**. Uma conexão antes, na seção do firewall, o `curl` do pc1 foi
atendido pelo web1, e a sequência continua a partir dele.

O endereço do web1 é `10.99.0.11/28`, um endereço privado. Ninguém de fora o alcança diretamente, e
ninguém de fora precisa: o endereço em todo pedido é 192.0.2.80, e só o lb sabe qual servidor está
atrás dele desta vez.

## Camada 4 e camada 7

Este balanceador lê o endereço e a porta de destino e nada mais. Isso faz dele um balanceador de
**camada 4**, rápido e simples: ele nunca olha dentro da conexão. Um balanceador de **camada 7** lê
o próprio pedido HTTP, então consegue mandar `/api` para um grupo de servidores e as imagens para
outro, ou manter um usuário no mesmo servidor lendo um cookie. Ele paga por isso participando de
cada conexão, e precisando das chaves para decifrar o HTTPS.

## O que este não faz

**Um balanceador de verdade verifica os servidores e para de mandar conexões para um que não
responde.** Esta regra não tem essa verificação. Se o web2 fosse desligado, uma conexão em cada duas
iria para uma máquina que não está lá, e metade dos visitantes esperaria por uma página que nunca
chega. Sem verificação de saúde (*health check*), dois servidores não são mais confiáveis do que um;
são duas chances de falhar, e a verificação é o que a regra de uma linha do laboratório deixa de
fora.

Há mais uma troca na regra de `masquerade`. Como o lb reescreve a origem, o log do web1 mostra o
endereço do lb em cada pedido, e não o do visitante. Um balanceador de camada 7 contorna isso
acrescentando um cabeçalho com o cliente original; este não consegue, porque só reescreve
endereços e nunca escreve dentro da conexão.
