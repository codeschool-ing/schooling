---
title: A saída é por onde o estrago vai embora
version: 1
---

**A maioria dos firewalls de host é escrita para o que entra e deixada aberta para o que sai.** O
próprio `ufw` do Ubuntu vem assim, negando a entrada e permitindo a saída, e o firewall do Windows
também. Para um notebook, é um padrão razoável. Para um servidor, ele joga fora o melhor sinal que
quem defende tem: **o tráfego de saída de um servidor é curto e previsível**, então qualquer coisa
fora dele vale um alerta, e bloqueá-la não custa nada.

Quase toda intrusão que importa precisa de uma saída: para buscar a próxima ferramenta, para
alcançar quem a controla ou para mandar os dados que veio buscar. Um servidor que não consegue abrir
conexões para o mundo barra as três coisas, e a aula 9 mostrou a mesma ideia de lista numa estação
de trabalho. No `web`, o que o portal precisa na saída é um servidor de nomes e mais nada. Salve isto
como `web-egress.nft`:

```schooling-example
{"language": "conf", "file": "web-egress.nft", "parts": [{"code": "table inet web_egress {\n\tchain output {\n\t\ttype filter hook output priority filter; policy drop;\n\t\toif \"lo\" accept\n\t\tct state established,related accept\n\t\tip daddr 192.168.60.53 udp dport 53 accept\n\t\tcounter comment \"web starts nothing else\"\n\t}\n}", "note": "Toda a política de saída do servidor em quatro regras: loopback, respostas a conversas que outros começaram e DNS para o servidor de nomes do escritório. Um servidor é o caso fácil para uma lista de saída, porque ninguém navega a partir dele: tudo o que ele precisa alcançar pode ser escrito, e o contador mostra o que tentou ir para qualquer outro lugar."}]}
```

Carregue e tente as duas direções:

```
ana@web:~$ sudo nft -f web-egress.nft
ana@web:~$ nc -zv -w2 desk 22 2>&1; echo "exit $?"
nc: connect to desk (192.168.60.20) port 22 (tcp) timed out: Operation now in progress
exit 1
ana@desk:~$ curl -s http://web/; ssh web hostname
Jatobá Contabilidade: client portal
web
ana@web:~$ sudo nft list chain inet web_egress output | grep counter
		counter packets 2 bytes 120 comment "web starts nothing else"
```

O `web` não consegue mais iniciar uma conexão com o `desk`, e a tentativa aparece no contador. Mas o
`desk` continua recebendo o portal e entrando no `web` por SSH, porque essas conversas começaram de
fora e o `web` só responde, o que `ct state established` permite.

## O que um servidor precisa, por escrito

A lista é curta no `web` porque o laboratório é pequeno. Num servidor de verdade é o mesmo
exercício, feito uma vez e guardado com a documentação do servidor:

| necessidade | destino |
|---|---|
| nomes | os resolvedores do escritório, porta 53 |
| hora | os servidores NTP do escritório, porta 123 |
| atualizações | o espelho de pacotes do escritório, ou os espelhos da distribuição |
| logs e telemetria | o coletor de logs, o console do EDR |
| o próprio trabalho | um banco de dados, uma API que ele chama |

Tudo o que não está na lista é uma pergunta, e o contador é onde a pergunta aparece. **Um contador
ainda em zero um mês depois é tão interessante quanto um que sobe**: ou nada nunca tenta aquela
saída, ou a regra está no lugar errado.
