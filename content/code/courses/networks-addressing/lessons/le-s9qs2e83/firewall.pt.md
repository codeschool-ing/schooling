---
title: "O firewall: uma regra para cada pacote"
version: 2
---

"Firewall" soa como uma caixa com um muro desenhado, ou como o antivírus de um laptop. **Um
firewall é uma lista de regras contra a qual cada pacote que cruza um ponto da rede é conferido, e
cada regra termina numa decisão: deixar passar, ou descartar.** As regras leem endereços, portas e,
num firewall com estado como o deste laboratório, o estado da conexão a que o pacote pertence. Onde
as regras rodam é detalhe: um equipamento dedicado, o sistema operacional de um laptop, ou um
roteador.

Neste laboratório elas rodam no r1, escritas para o `nftables`, o filtro de pacotes do Linux. Esta
é a cadeia que julga cada pacote que o r1 encaminha:

```
root@r1:~# nft list chain inet filter forward
table inet filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related counter packets 10 bytes 876 accept
		iifname "eth0" oifname "eth1" counter packets 14 bytes 864 accept
		counter packets 0 bytes 0 comment "everything else: dropped"
	}
}
```

Quatro linhas carregam a política, lidas de cima para baixo:

- `policy drop` é o padrão: **um pacote que não casa com nenhuma regra é descartado**. Tudo o que é
  permitido precisa ser dito.
- `ct state established,related ... accept` deixa passar qualquer pacote que pertença a uma
  conexão já aceita, nos dois sentidos. `ct` é o rastreamento de conexões (*connection tracking*):
  o r1 lembra cada conversa que deixou começar.
- `iifname "eth0" oifname "eth1" ... accept` deixa uma conexão *nova* começar se ela entra pelo lado
  do escritório e sai na direção do provedor.
- A última linha só conta o que chega até ela, que é todo o resto, antes de a política descartar.

**Nada nessa lista deixa uma conexão começar de fora.** Cada regra tem também um `counter`, então a
lista diz quanto tráfego cada regra já decidiu: 10 pacotes casaram com a primeira, 14 com a segunda
e nenhum com a última.

Agora uma conexão em cada sentido. O pc1 pede uma página ao serviço web do outro lado do provedor;
o provedor tenta abrir o servidor web de dentro do escritório. (Neste bloco o provedor ganhou uma
rota para a rede privada do escritório, `ip route add 10.20.10.0/24 via 203.0.113.2` num prompt de
root no isp, para que o firewall seja a única coisa no caminho.)

```
ana@pc1:~$ curl -s http://192.0.2.80/
served by web1
root@isp:~# curl -s -m 5 http://10.20.10.10/; echo "exit status $?"
exit status 28
root@r1:~# nft list chain inet filter forward
table inet filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related counter packets 21 bytes 1729 accept
		iifname "eth0" oifname "eth1" counter packets 15 bytes 924 accept
		counter packets 5 bytes 300 comment "everything else: dropped"
	}
}
```

O pc1 recebeu a página, `served by web1`. O `curl` do provedor teve cinco segundos com `-m 5`, não
recebeu nada nesse tempo e desistiu com **exit status 28**, o código do curl para tempo esgotado.
Depois os contadores, comparados com a primeira listagem:

| regra | antes | depois |
|---|---|---|
| estabelecida ou relacionada | 10 pacotes | 21 pacotes |
| nova, do escritório para o provedor | 14 pacotes | 15 pacotes |
| todo o resto, descartado | 0 pacotes | 5 pacotes |

O pedido do pc1 somou **um pacote à segunda regra e onze à primeira**. Só o primeiro pacote de uma
conexão é novo; depois que o firewall o deixou passar, cada pacote seguinte, nos dois sentidos,
pertencia a uma conexão estabelecida. A tentativa do provedor não casou com nenhuma das duas regras
e foi contada pela última linha: 5 pacotes, 300 bytes, todos descartados.

**`drop` não responde nada**, e é por isso que o curl do provedor esperou os cinco segundos em vez
de falhar na hora. A alternativa, `reject`, devolve uma recusa e o remetente fica sabendo
imediatamente. Descartar conta menos a um estranho sobre o que há atrás do roteador; rejeitar
poupa um usuário legítimo, recusado por engano, de esperar uma resposta que não vem.

Este é um firewall **com estado** (*stateful*), e a palavra importa. Uma lista de regras sem
rastreamento de conexões precisaria de uma regra também para as respostas, e não conseguiria
distinguir uma resposta de um estranho batendo com as mesmas portas. A linha `ct state` é o que faz
de "o escritório pode começar conversas, a internet não" uma política de duas linhas. A aula 11 põe
o NAT no mesmo roteador, e os dois se confundem com facilidade: o NAT reescreve endereços, e o
firewall decide o que passa.
