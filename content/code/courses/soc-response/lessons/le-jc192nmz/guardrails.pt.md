---
title: Proteções, e como desfazer
version: 1
---

A automação falha de um jeito particular: **depressa, em escala e com confiança.** Uma regra que erra uma vez
põe um alerta errado numa fila; um playbook que erra bloqueia um endereço num segundo, e se esse endereço é
o do provedor de backup, o backup da noite não aconteceu e ninguém sabe. As defesas são escritas no
playbook antes da primeira execução:

| proteção | o que evita |
|---|---|
| **uma lista de nunca bloquear** | bloquear um parceiro, um fornecedor, um gateway de pagamento, ou a equipe trabalhando de casa |
| **as redes da própria empresa** | uma ação automática contra a infraestrutura que ela defende |
| **um alvo por ação** | uma regra que bloqueia uma faixa, uma sub-rede ou um país por acidente |
| **quem aprova, nomeado** | uma ação sobre a qual ninguém pode ser perguntado depois |
| **um limite de taxa** | uma enxurrada de alertas virar uma enxurrada de bloqueios |
| **um desfazer para cada ação** | um erro que sobrevive à manhã em que foi cometido |

Duas delas, acionadas de propósito:

```
root@soc:~# python3 playbook.py /home/ana/week/siem.db 203.0.113.150 --approve ana
203.0.113.150: 0 failed logins over 0 accounts, 0 accepted
  refused to block: 203.0.113.150 is on the never-block list
  ticket written: ticket-203.0.113.150.json
root@soc:~# python3 playbook.py /home/ana/week/siem.db 192.168.20.10 --approve ana
192.168.20.10: 0 failed logins over 0 accounts, 0 accepted
  refused to block: 192.168.20.10 is one of the company's own addresses
  ticket written: ticket-192.168.20.10.json
```

O provedor de backup é recusado porque uma pessoa o pôs na lista. O servidor de arquivos é recusado porque
fica numa das redes da empresa. As duas execuções escreveram chamado mesmo assim, então a própria recusa
fica registrada.

O playbook desta aula não tem limite de taxa; um de produção conta as próprias ações por hora e para, e
avisa alguém, quando a contagem parece uma enxurrada. E toda ação precisa do seu desfazer, escrito e testado
**antes** de ser necessário. Aqui o desfazer são dois comandos: listar a cadeia com os handles e apagar a
regra que o playbook acrescentou.

```
root@soc:~# ip netns exec fw nft -a list chain ip fw forward
table ip fw {
	chain forward { # handle 1
		type filter hook forward priority filter; policy accept;
		ip saddr 203.0.113.66 drop comment "playbook, approved by ana" # handle 3
		ct state new log prefix "fw-new " group 1 # handle 2
	}
}
root@soc:~# ip netns exec fw nft delete rule ip fw forward handle 3
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o BatchMode=yes -o ConnectTimeout=3 ana@198.51.100.22 hostname
gw
```

O bloqueio sumiu e a conexão funciona de novo. Uma ação que não se desfaz no tempo que levou para ser feita
pertence a uma pessoa, não a um playbook.
