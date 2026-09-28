---
title: Fora do host, enquanto acontece
version: 1
---

Tudo até aqui está em `fw`, e um log na própria máquina que ele descreve tem uma fraqueza conhecida:
quem toma a máquina pode editá-lo. A aula 16 prometeu a resposta, que é **enviar cada linha para outro
lugar assim que ela é escrita**, para uma máquina que a origem não consegue alcançar de volta.

Aqui o coletor é `admin`, na rede de gerência. `fw` roda o **rsyslog** com esta configuração:

```schooling-example
{"language": "conf", "file": "rsyslog.conf", "parts": [{"code": "global(workDirectory=\"/var/log/lab/rsyslog\")\nmodule(load=\"imfile\")", "note": "O diretório onde o rsyslog lembra até onde já leu cada arquivo, para que um reinício não envie tudo de novo."}, {"code": "input(type=\"imfile\" file=\"/var/log/lab/drops.json\" tag=\"drops\" ruleset=\"ship\" reopenOnTruncate=\"on\")\ninput(type=\"imfile\" file=\"/var/log/lab/flows.json\" tag=\"flows\" ruleset=\"ship\" reopenOnTruncate=\"on\")", "note": "Seguir os dois arquivos e entregar cada linha nova ao conjunto de regras ship. A tag vira o nome do arquivo no coletor. reopenOnTruncate recomeça do início quando um arquivo é esvaziado, em vez de esperar que ele cresça além de onde estava."}, {"code": "ruleset(name=\"ship\") {\n  action(type=\"omfwd\" target=\"192.168.99.10\" port=\"514\" protocol=\"tcp\"\n         queue.type=\"LinkedList\" queue.filename=\"ship\" queue.saveOnShutdown=\"on\"\n         action.resumeRetryCount=\"-1\")\n}", "note": "Enviar cada linha por TCP para admin. A fila mantém as linhas em disco enquanto o coletor está inalcançável, e a contagem de tentativas -1 significa nunca desistir."}]}
```

`admin` também roda o rsyslog, escutando na porta TCP 514 e gravando as linhas de cada máquina em um
diretório próprio, e um firewall de host decide quem pode falar com ele:

```
root@admin:~# nft list ruleset
table inet host {
	chain input {
		type filter hook input priority filter; policy drop;
		ct state established,related accept
		iifname "lo" accept
		ip saddr 192.168.99.1 tcp dport 514 accept comment "logs from fw, and nothing else from it"
	}
}
root@admin:~# ls /var/log/lab/remote/fw/
drops.json
flows.json
root@admin:~# wc -l /var/log/lab/remote/fw/*.json
   4 /var/log/lab/remote/fw/drops.json
   7 /var/log/lab/remote/fw/flows.json
  11 total
```

As mesmas linhas agora estão em dois lugares. Agora suponha que alguém com root em `fw` queira começar
do zero, e esvazie o log de descartes:

```
root@fw:~# : > /var/log/lab/drops.json; wc -l /var/log/lab/drops.json
0 /var/log/lab/drops.json
root@admin:~# wc -l /var/log/lab/remote/fw/drops.json
4 /var/log/lab/remote/fw/drops.json
```

O coletor ainda guarda as quatro. E o registro continua depois da limpeza: `remote` tenta mais uma
porta, e a linha chega a `admin` em segundos:

```
ana@remote:~$ probe 192.0.2.80:23
192.0.2.80:23          blocked
root@admin:~# tail -1 /var/log/lab/remote/fw/drops.json | jq -c '[.timestamp, .src_ip, .dest_port]'
["2026-09-28T18:55:35.444049-0300","203.0.113.50",23]
```

O último requisito é o que faz o arranjo se sustentar. `fw` pode entregar linhas, e nada
mais:

```
root@fw:~# nc -z -v -w1 admin 22; nc -z -v -w1 admin 514
nc: connect to admin (192.168.99.10) port 22 (tcp) timed out: Operation now in progress
Connection to admin (192.168.99.10) 514 port [tcp/shell] succeeded!
```

A porta 22 dá timeout, porque o conjunto de regras de `admin` a descarta. Um intruso em `fw` pode,
portanto, **acrescentar** ruído à coleção, e não pode **alterar** o que já está lá. Três detalhes a
tornam mais robusta em produção:

- **TLS no caminho.** O rsyslog pode envolver a porta 514 em TLS e verificar os dois certificados, como
  as aulas 12 e 20 fizeram para outros serviços. O laboratório conta com a rede de gerência ser um
  segmento próprio.
- **Uma fila para quando o coletor está fora.** `queue.saveOnShutdown` e `action.resumeRetryCount="-1"`
  mantêm as linhas em disco e tentam de novo para sempre, então um reinício em `admin` não perde nada.
- **Um alarme para o silêncio.** Uma origem que para de enviar ou foi desligada, ou foi desligada por
  alguém. Um coletor deveria perceber quando uma origem fica calada por mais tempo do que jamais fica,
  como uma verificação à parte.
