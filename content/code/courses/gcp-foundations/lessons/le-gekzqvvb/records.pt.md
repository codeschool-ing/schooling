---
title: Registros, e uma zona respondendo
version: 1
---

**Um registro é um nome, um tipo, um tempo de vida e os dados**, e uma zona é uma lista deles. Os tipos que o
planner usa são os que quase todo mundo usa:

| tipo | diz | exemplo |
|---|---|---|
| `A` | o endereço IPv4 do nome | `api` → `203.0.113.20` |
| `CNAME` | o nome é outro nome; pergunte por aquele | `www` → `planner.example.com.` |
| `MX` | para onde vai o e-mail do domínio, com uma preferência | `10 mail.example.net.` |
| `TXT` | texto livre, lido sobretudo por máquinas: políticas de e-mail, provas de posse | `v=spf1 …` |
| `NS`, `SOA` | que servidores respondem pela zona, e as configurações da própria zona | criados pelo Cloud DNS com a zona |

O **TTL** é por quantos segundos um resolvedor pode guardar uma resposta antes de perguntar de novo. É o número
que decide quanto tempo uma mudança leva para ser vista: com 300 segundos, um endereço mudado chega a todos em
cinco minutos; com um dia, em um dia. O planner baixa o TTL de um registro um dia antes de mudá-lo, e sobe de
novo depois.

## Uma zona no laptop

O Cloud DNS responde dos servidores de nomes do Google, em que o laboratório não consegue criar uma zona. Ele
consegue a segunda melhor coisa: responder os mesmos registros a partir de um **arquivo de zona**, o formato de
texto que o DNS usa desde os anos 1980 e o que o Cloud DNS importa e exporta. O `gcloud dns record-sets import`
o lê:

```
ana@laptop:~/gcp$ gcloud dns record-sets import --help | grep -A2 "zone-file-format$"
     --zone-file-format
        Indicates that the input records-file is in BIND zone format. If
        omitted, indicates that the records-file is in YAML format.
```

O laboratório precisa de duas coisas que ainda não tem: o `dig`, a ferramenta padrão para fazer perguntas a
servidores DNS, e o `dnslib`, uma pequena biblioteca Python que consegue respondê-las:

```sh
sudo apt install -y bind9-dnsutils
~/gcp/venv/bin/pip install -q 'dnslib==0.9.26'
mkdir -p ~/gcp/dns && cd ~/gcp/dns
```

Salve a zona pública do planner como `~/gcp/dns/planner.example.com.zone`. Os endereços são de
`203.0.113.0/24`, uma faixa reservada para documentação, e os servidores de nomes estão escritos do jeito que o
Cloud DNS nomeia os seus:

```ini
$ORIGIN planner.example.com.
$TTL 300
@        IN SOA  ns-cloud-a1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300
@        IN NS   ns-cloud-a1.googledomains.com.
@        IN NS   ns-cloud-a2.googledomains.com.
@        IN A    203.0.113.10
www      IN CNAME planner.example.com.
api      IN A    203.0.113.20
@        IN MX   10 mail.example.net.
@        IN TXT  "v=spf1 include:mail.example.net -all"
```

E um servidor que responde a partir dela, como `serve.py`:

```schooling-example
{"language": "python", "file": "serve.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Answers DNS questions from one zone file, on this laptop only.\n\n    python3 serve.py ZONEFILE\n\nListens on 127.0.0.1, UDP port 5353, until it is stopped.\n\"\"\"\nimport sys\nimport time\n\n", "note": "Como é chamado: um arquivo de zona. Ele responde só no endereço do próprio laptop, na porta 5353, então nada na rede consegue perguntar a ele e ele não precisa de direitos de administrador."}, {"code": "from dnslib.server import DNSServer\nfrom dnslib.zoneresolver import ZoneResolver\n\n", "note": "O `dnslib` é uma pequena biblioteca de DNS, instalada no ambiente do laboratório acima. O `ZoneResolver` dele lê um arquivo de zona no mesmo formato BIND que o Cloud DNS importa."}, {"code": "resolver = ZoneResolver(open(sys.argv[1]).read(), glob=True)\nserver = DNSServer(resolver, address='127.0.0.1', port=5353)\nserver.start_thread()\n", "note": "Ler a zona e iniciar o servidor. Ele responde o que a zona tem, diz que um nome que não está lá não existe, e não tem opinião sobre nada fora da zona."}, {"code": "print(f'answering for {sys.argv[1]} on 127.0.0.1:5353')\nwhile server.isAlive():\n    time.sleep(1)\n", "note": "Dizer que está pronto, e continuar rodando até ser parado com Control-C."}]}
```

Num segundo terminal, depois de `source ~/gcp/env.sh`:

```
ana@laptop:~/gcp/dns$ python3 serve.py planner.example.com.zone
answering for planner.example.com.zone on 127.0.0.1:5353
```

De volta ao primeiro, faça quatro perguntas num comando só:

```
ana@laptop:~/gcp/dns$ dig @127.0.0.1 -p 5353 +noall +answer planner.example.com A www.planner.example.com A planner.example.com MX planner.example.com TXT
planner.example.com.	300	IN	A	203.0.113.10
www.planner.example.com. 300	IN	CNAME	planner.example.com.
planner.example.com.	300	IN	MX	10 mail.example.net.
planner.example.com.	300	IN	TXT	"v=spf1 include:mail.example.net -all"
```

**O `www` respondeu com um CNAME e nada mais**: o servidor diz o que `www` é, outro nome, e um resolvedor
seguiria perguntando pelo próprio `planner.example.com`. Toda resposta leva o TTL dela, 300, do `$TTL` da zona.
Agora um nome que não está na zona:

```
ana@laptop:~/gcp/dns$ dig @127.0.0.1 -p 5353 nothing.planner.example.com A | grep -o "status: [A-Z]*"
status: NXDOMAIN
```

`NXDOMAIN`: o nome não existe. Essa é uma resposta real, guardada em cache como qualquer outra, e é por isso
que criar um registro poucos segundos depois de alguém perguntar por ele ainda pode parecer faltar para essa
pessoa por um tempo.

Duas regras que este servidor não impõe e o Cloud DNS impõe. **Um CNAME não pode ficar ao lado de outros
registros do mesmo nome**, então o ápice, o próprio `planner.example.com.`, que tem de ter o seu `SOA` e o seu
`NS`, nunca pode ser um CNAME. E todo conjunto de registros no Cloud DNS é um recurso próprio,
`google_dns_record_set` no Terraform, um por nome e tipo, com todos os valores numa lista.

Pare o servidor com Control-C no terminal dele quando terminar.
