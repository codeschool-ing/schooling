---
title: Desenhando as zonas
version: 1
---

A política da livraria cabe em três frases, e cada uma vira uma regra:

1. a internet pode alcançar o servidor web da loja, na porta web, e nada mais;
2. o servidor web da loja pode alcançar o banco, na porta do banco, e nada mais;
3. o escritório pode alcançar a internet e a loja.

Tudo o que não foi nomeado é recusado. Essa última frase é a linha mais importante da política e não
é uma regra: é o **padrão** do firewall. Uma política que lista o que é permitido e recusa todo o
resto se chama **negar por padrão** (*default deny*), e é a única que continua segura quando alguém
acrescenta uma máquina e esquece de pensar nela.

Aqui estão as regras como o firewall do laboratório as lê, em `nftables`, o firewall embutido no
Linux. O administrador mostra o arquivo e depois o carrega:

```
root@fw:~# cat zones.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport 80 accept comment "the internet reaches the shop"
    iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.30 tcp dport 5432 accept comment "the shop reaches its database"
    iifname "eth2" oifname { "eth0", "eth1" } accept comment "the office reaches the internet and the shop"
  }
}
root@fw:~# nft -f zones.nft
```

Você não precisa aprender a sintaxe para ler. `policy drop` é negar por padrão: tudo o que chega ao
fim da lista é descartado. A linha que começa com `ct state established,related` deixa voltar as
respostas de conexões que já foram permitidas, então cada regra só precisa descrever o lado que começa
a conversa. As três linhas depois dela são as três frases acima, cada uma com um comentário dizendo
isso. `eth0` é a perna do firewall na internet, `eth1` na DMZ, `eth2` no escritório e `eth3` nos
servidores.

Agora as mesmas sondagens, dos mesmos três lugares:

```
ana@outside:~$ probe www:80 db:5432
www:80                 open
db:5432                blocked
ana@www:~$ probe db:5432 db:22 laptop:22
db:5432                open
db:22                  blocked
laptop:22              blocked
ana@laptop:~$ probe www:80 db:5432
www:80                 open
db:5432                blocked
```

Cada linha é a política, testada:

| de | para | antes | depois | por quê |
|---|---|---|---|---|
| a internet | `www:80` | open | open | regra 1 |
| a internet | `db:5432` | open | **blocked** | nada permite |
| `www` | `db:5432` | open | open | regra 2 |
| `www` | `db:22` | refused | **blocked** | a regra 2 só nomeia a porta 5432 |
| `www` | `laptop:22` | refused | **blocked** | a DMZ não pode alcançar o escritório |
| o escritório | `www:80` | open | open | regra 3 |
| o escritório | `db:5432` | open | **blocked** | a regra 3 não inclui os servidores |

Duas linhas mudaram de `refused` para `blocked`, e a diferença importa. Antes, a tentativa chegava à
máquina e a máquina dizia não. Agora a tentativa nem chega. Um `www` comprometido não consegue nem
descobrir quais portas o `laptop` tem abertas, que é a primeira coisa que um atacante em movimento
lateral quer saber.

**Testar de cada zona faz parte de escrever a regra.** Um conjunto de regras testado só do escritório,
onde quem o escreveu se senta, não diz nada sobre o que a internet ou um servidor comprometido
conseguem fazer. A tabela acima é o teste, e é curta o bastante para rodar de novo toda vez que uma
regra muda.
