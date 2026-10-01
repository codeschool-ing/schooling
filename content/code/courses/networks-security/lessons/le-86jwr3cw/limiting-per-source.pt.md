---
title: Limitando o que uma origem pode manter
version: 1
---

O proxy da aula 3 limitava a velocidade com que um cliente pode **pedir**. O firewall pode limitar
quanto um cliente pode **manter**: quantas conexões ele tem abertas ao mesmo tempo. Um cliente com
cem conexões abertas para a loja ou é muito incomum ou não é um cliente.

O nftables conta conexões por origem com um **conjunto dinâmico** (dynamic set): um conjunto que as
regras preenchem conforme o tráfego chega, um elemento por cliente, cada um carregando a contagem das
conexões abertas daquele cliente:

```
root@fw:~# cat perclient.nft
table ip filter {
  set web_clients {
    type ipv4_addr
    flags dynamic
    size 65535
  }
  chain forward {
    iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter reject with tcp reset comment "at most 4 open connections per client"
  }
}
```

`add @web_clients { ip saddr ct count over 4 }` acrescenta a origem ao conjunto, ou a encontra lá, e
casa quando essa origem já tem **mais de quatro** conexões rastreadas. Um pacote que casa é respondido
com um reset TCP, então o cliente fica sabendo na hora em vez de ficar esperando. A regra tem de vir
antes da regra que aceita a internet na loja, senão o accept decidiria primeiro:

```
root@fw:~# nft list chain ip filter forward | sed -n "3,5p"
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter packets 0 bytes 0 reject with tcp reset comment "at most 4 open connections per client"
```

Então o `remote` abre seis conexões e mantém todas abertas:

```
ana@remote:~$ for i in 1 2 3 4 5 6; do exec {fd}<>/dev/tcp/www.example.com/443 && echo "connection $i: open" || echo "connection $i: refused"; done; sleep 1
connection 1: open
connection 2: open
connection 3: open
connection 4: open
bash: connect: Connection refused
bash: line 1: /dev/tcp/www.example.com/443: Connection refused
connection 5: refused
bash: connect: Connection refused
bash: line 1: /dev/tcp/www.example.com/443: Connection refused
connection 6: refused
```

**Quatro abertas, depois recusadas.** O limite conta por origem, então outro cliente na internet não
é afetado, e o contador mostra as duas recusas:

```
ana@branch:~$ exec {fd}<>/dev/tcp/www.example.com/443 && echo "branch: open"
branch: open
root@fw:~# nft list chain ip filter forward | grep "at most 4"
		iifname "eth0" ip daddr 192.0.2.80 tcp dport 443 ct state new add @web_clients { ip saddr ct count over 4 } counter packets 2 bytes 120 reject with tcp reset comment "at most 4 open connections per client"
```

Quando as conexões do `remote` fecham, a contagem dele cai e ele volta a ser atendido:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
```

## Escolhendo o número

Quatro é uma demonstração. Um limite real é definido a partir do que os clientes reais fazem: um
navegador abre até seis conexões para um host, e um escritório inteiro atrás de um único endereço de
NAT divide uma só contagem, o problema que a aula 3 encontrou com os limites de taxa. Meça primeiro a
origem legítima mais movimentada, depois defina o limite bem acima dela.

**Um limite por origem não faz nada contra um ataque distribuído**, em que cada uma de dez mil origens
fica educadamente abaixo dele. É a ferramenta certa para um cliente barulhento e um componente de uma
defesa contra DDoS, nunca a defesa inteira.
