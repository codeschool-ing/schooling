---
title: O que vale guardar, e por quanto tempo
version: 1
---

Guardar tudo para sempre não é uma política. Custa espaço, deixa toda busca mais lenta, e boa parte é
dado pessoal que, diz a lei, precisa ter um motivo para existir. A coleção do laboratório depois de um
cenário curto:

```
root@admin:~# cd /var/log/lab/remote; wc -lc fw/flows.json fw/drops.json sensor/eve.json
     7   4366 fw/flows.json
     8   6900 fw/drops.json
    43 197592 sensor/eve.json
    58 208858 total
```

Cerca de 600 bytes por registro de fluxo e 860 por descarte, e o `eve.json` bem maior por registro. O
arquivo do sensor, na maior parte, não é de alertas:

```
root@admin:~# jq -r .event_type /var/log/lab/remote/sensor/eve.json | sort | uniq -c | sort -rn
     24 stats
      6 http
      6 flow
      6 fileinfo
      1 alert
```

Um alerta, e 24 registros `stats`, o relatório periódico do sensor sobre si mesmo, que formam a maior
parte do arquivo. **A primeira economia é escolher os tipos de registro**, não encurtar por quanto
tempo são guardados. A mesma conta em escala real: um firewall recusando 50 pacotes por segundo escreve
cerca de 3,7 GB de descartes por dia nesse tamanho, e 20 conexões novas por segundo escrevem cerca de
1,1 GB de fluxos. Os dois comprimem bem, e nenhum é pequeno.

Uma política inicial razoável, a ajustar por empresa:

| registro | guardar | por quê |
|---|---|---|
| alertas de IDS | um ano ou mais | poucos, pequenos, e a história dos ataques contra você |
| registros de fluxo | 90 dias a um ano | o olhar para trás das seções anteriores; intrusões muitas vezes são descobertas semanas depois de começarem |
| descartes do firewall | 30 a 90 dias, depois só as contagens | na maior parte ruído de fundo; os totais por dia mantêm a tendência |
| detalhes de HTTP e DNS do sensor | dias a semanas | URLs e nomes completos podem carregar dados pessoais |
| logs de 802.1X e DHCP | tanto quanto os fluxos que eles explicam | transformam um endereço em uma pessoa, o que é o seu uso e o seu risco |

**A lei define tanto pisos quanto tetos.** No Brasil, o **Marco Civil da Internet** obriga uma empresa
que oferece uma aplicação na internet, como a loja do laboratório, a guardar os seus registros de
acesso por seis meses (artigo 15). Um provedor de conexão precisa guardar os registros de conexão por
um ano (artigo 13). A **LGPD** puxa para o outro lado: os seus princípios incluem finalidade, necessidade
e segurança (artigo 6), então registros que identificam pessoas são guardados por um motivo declarado,
não por mais tempo do que ele exige, e protegidos enquanto existem. A aula 2 levantou a mesma questão
sobre o que um firewall decifra; aqui ela se aplica a cada linha da coleção.

A retenção é imposta pelo coletor, não por boas intenções. Em `admin` é um arquivo:

```schooling-example
{"language": "conf", "file": "logrotate.conf", "parts": [{"code": "/var/log/lab/remote/*/*.json {\n    daily\n    rotate 90", "note": "Todo arquivo da coleção, uma vez por dia. Noventa arquivos antigos são mantidos, então a linha mais antiga tem cerca de noventa dias."}, {"code": "    compress\n    delaycompress", "note": "Os arquivos antigos são comprimidos, exceto o mais recente, que um leitor ainda pode ter aberto."}, {"code": "    missingok\n    notifempty", "note": "Uma origem que não enviou nada hoje não é um erro para o logrotate; o alarme de silêncio é uma verificação separada."}, {"code": "    postrotate\n        kill -HUP $(cat /var/log/lab/rsyslog.pid)\n    endscript\n}", "note": "O rsyslog é avisado para reabrir os seus arquivos, para que as linhas novas vão para o arquivo novo e não para o renomeado."}]}
```

Três últimas regras fecham o fio do curso sobre registros:

- **O acesso à coleção também é registrado.** É o repositório mais sensível da rede, porque diz quem fez
  o quê, e quando.
- **A exclusão é agendada, não lembrada.** Um período de retenção que ninguém impõe dura para
  sempre.
- **Um registro que ninguém lê não protege nada.** Os alertas vão para onde uma pessoa olha, a busca
  pelo feed roda em um agendamento, e uma origem que fica em silêncio dispara o seu próprio alarme.
