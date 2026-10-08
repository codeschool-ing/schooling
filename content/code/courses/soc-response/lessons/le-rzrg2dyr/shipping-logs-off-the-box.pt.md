---
title: Despachar os logs para fora da máquina
version: 1
---

Um log guardado só na máquina que o escreveu tem o mesmo destino que ela. **Um disco que falha, uma
reinstalação, um erro de administrador ou uma conta comprometida naquela máquina alcançam o log também.**
A resposta é mandar cada linha para uma segunda máquina assim que ela é escrita, operada por outras
pessoas, para que o dia ruim de uma máquina não seja também o fim do registro dela.

No laboratório, o `soc` é essa segunda máquina. O rsyslog dele ganha uma segunda entrada, um listener TCP
no endereço que o `gw` alcança, e uma regra que arquiva as linhas de cada remetente com o nome dele. Ponha
isto em `/etc/rsyslog.d/10-remote.conf`:

```conf
module(load="imtcp")
template(name="perhost" type="string" string="/var/log/remote/%HOSTNAME%.log")
ruleset(name="remote") {
  action(type="omfile" dynaFile="perhost"
         fileCreateMode="0640" fileOwner="syslog" fileGroup="adm")
}
input(type="imtcp" address="192.168.99.10" port="514" ruleset="remote")
```

O modo, o dono e o grupo do arquivo estão escritos por extenso porque esse tipo de ação não herda o
antigo `$FileCreateMode` do `rsyslog.conf`: sem eles, as cópias saem legíveis por qualquer usuário do
`soc`. Crie a pasta, reinicie o rsyslog com `systemctl restart rsyslog` (a máquina da gravação não tinha
systemd e o reiniciou à mão) e confira que ele está escutando:

```
root@soc:~# mkdir -p /var/log/remote && chown syslog:adm /var/log/remote && chmod 750 /var/log/remote
root@soc:~# ss -ltn src 192.168.99.10
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      25     192.168.99.10:514       0.0.0.0:*          
```

No `gw`, um segundo rsyslog acompanha o log de SSH e encaminha cada linha nova. Salve isto como
`/etc/soclab/gw-rsyslog.conf`:

```schooling-example
{"language": "conf", "file": "gw-rsyslog.conf", "parts": [{"code": "global(localHostname=\"gw\" workDirectory=\"/var/spool/rsyslog-gw\")", "note": "Quem este rsyslog diz que é, e onde guarda a fila. Sem `localHostname` ele pegaria o nome do seu computador, porque o namespace o compartilha."}, {"code": "module(load=\"imfile\")\ninput(type=\"imfile\" file=\"/var/log/soclab/gw-auth.log\" tag=\"gw-auth:\")", "note": "O `imfile` acompanha um arquivo de texto como o `tail -f` faz, e transforma cada linha nova numa mensagem marcada `gw-auth:`."}, {"code": "action(type=\"omfwd\" target=\"192.168.99.10\" port=\"514\" protocol=\"tcp\"\n       template=\"RSYSLOG_SyslogProtocol23Format\"", "note": "Mandar toda mensagem ao soc por TCP, no formato da RFC 5424, que leva o fuso junto com a hora."}, {"code": "       queue.type=\"LinkedList\" queue.filename=\"to-soc\" queue.saveOnShutdown=\"on\"\n       action.resumeRetryCount=\"-1\")", "note": "Uma fila na memória e no disco, salva se o rsyslog parar, repetida até dar certo: se o soc cair, as linhas esperam no gw em vez de se perder."}]}
```

Inicie-o dentro do `gw`, provoque um login falho a partir do `outside` e olhe no `soc`:

```
root@soc:~# mkdir -p /var/spool/rsyslog-gw
root@soc:~# ip netns exec gw rsyslogd -f /etc/soclab/gw-rsyslog.conf -i /run/rsyslogd-gw.pid
root@soc:~# ip netns exec outside ssh -o BatchMode=yes -o StrictHostKeyChecking=no admin@198.51.100.22 true
admin@198.51.100.22: Permission denied (publickey,password).
root@soc:~# cat /var/log/remote/gw.log
2026-10-07T04:51:42.824635-03:00 gw gw-auth 2026-10-07T04:51:39-0300 gw sshd: Server listening on 198.51.100.22 port 22.
2026-10-07T04:51:43.986525-03:00 gw gw-auth 2026-10-07T04:51:43-0300 gw sshd: Invalid user admin from 203.0.113.66 port 32906
2026-10-07T04:51:43.991050-03:00 gw gw-auth 2026-10-07T04:51:43-0300 gw sshd: Connection closed by invalid user admin 203.0.113.66 port 32906 [preauth]
```

Cada linha agora carrega **dois carimbos de hora**: o primeiro é quando o rsyslog do `gw` leu a linha,
com microssegundos e o fuso, e o segundo é o que o `ts` já tinha escrito. Aqui estão a menos de um
segundo um do outro; num dia em que o coletor caiu e a fila segurou as linhas, estariam a minutos de
distância, e essa diferença é como um analista vê que o coletor ficou fora do ar.

Dois cuidados. Syslog sobre TCP puro viaja **em texto claro**, então numa rede de verdade a mesma ação
`omfwd` recebe configurações de TLS, e o coletor só aceita os remetentes que conhece. E **encaminhar é uma
estrada entre várias**: máquinas Windows usam o Windows Event Forwarding ou um agente, e serviços de nuvem
empurram os logs por uma API. A aula 4 recebe todos eles num mesmo lugar.
