---
title: Três tipos de registro
version: 1
---

Toda aula anterior terminou com algo anotado: um descarte registrado pelo firewall na aula 5, um alerta
do sensor na aula 14, uma linha no log de portas do switch na aula 22. Cada um foi lido uma vez, na
máquina que o escreveu, pela pessoa que tinha acabado de causá-lo. Isso é uma demonstração. **Uma defesa
precisa dos registros guardados, em um só lugar, por tempo suficiente para responder a perguntas que
ninguém fez ainda.**

Uma rede produz três tipos, e eles respondem a perguntas diferentes:

| registro | escrito por | um registro é | ele responde |
|---|---|---|---|
| **log do firewall** | uma regra `log` | um pacote com que a regra casou, em geral um recusado | o que foi **tentado** e barrado |
| **registro de fluxo** | o rastreamento de conexões do firewall, ou um roteador | uma conversa: dois endereços, duas portas, bytes e pacotes em cada sentido, início e fim | o que **aconteceu**, entre quais pares, e quanto |
| **alerta de IDS** | o sensor | um casamento com uma assinatura, com os detalhes de HTTP, DNS ou TLS em volta | o que **parecia errado**, e por que o sensor achou isso |

Nenhum deles guarda o conteúdo da conversa. Isso é proposital: a captura completa de pacotes é guardada
por minutos ou horas em um link movimentado, e estes três são guardados por meses.

Os registros de fluxo (flow records) são os que este curso ainda não construiu. Em roteadores eles
trafegam como **NetFlow** ou IPFIX, um formato binário enviado a um coletor. Em um firewall Linux,
os mesmos campos já existem no **conntrack**, a tabela que as aulas 1 e 21 leram: toda conexão que o
firewall rastreia tem seus endereços e portas e, com a contabilização ligada, também suas contagens de
pacotes e bytes. O laboratório escreve tanto o log quanto os fluxos com o **ulogd**, um objeto JSON por
linha:

```schooling-example
{"language": "conf", "file": "ulogd.conf", "parts": [{"code": "[global]\nlogfile=\"/var/log/lab/ulogd.log\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_inpflow_NFCT.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_inppkt_NFLOG.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_raw2packet_BASE.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_filter_IFINDEX.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_filter_IP2STR.so\"\nplugin=\"/usr/lib/x86_64-linux-gnu/ulogd/ulogd_output_JSON.so\"", "note": "Onde o ulogd relata sobre si mesmo, e os plugins que ele carrega: duas entradas, um decodificador de pacotes, dois filtros que transformam números em nomes, e a saída JSON."}, {"code": "# one record per connection, written when the firewall forgets it\nstack=ct1:NFCT,ip2str1:IP2STR,flows:JSON\n# one record per packet a log rule sends to group 1\nstack=log1:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str2:IP2STR,drops:JSON", "note": "Duas pilhas. A primeira lê o rastreamento de conexões e escreve um registro de fluxo quando uma conexão termina. A segunda lê os pacotes enviados por uma regra de log ao grupo 1."}, {"code": "[ct1]\nevent_mask=0x00000005", "note": "0x5 pede dois eventos, uma conexão nova e uma destruída, então cada registro carrega o seu início além do seu fim."}, {"code": "[log1]\ngroup=1", "note": "O número do grupo coincide com o da regra de log do firewall."}, {"code": "[flows]\nfile=\"/var/log/lab/flows.json\"\nsync=1\n\n[drops]\nfile=\"/var/log/lab/drops.json\"\nsync=1", "note": "Cada pilha escreve o seu próprio arquivo, um objeto JSON por linha, descarregado à medida que é escrito."}]}
```

O administrador liga os contadores, acrescenta uma regra de log no fim da chain forward, onde ela só vê
o que todas as regras acima dela recusaram, e inicia o ulogd:

```
root@fw:~# sysctl net.netfilter.nf_conntrack_acct=1 net.netfilter.nf_conntrack_timestamp=1
net.netfilter.nf_conntrack_acct = 1
net.netfilter.nf_conntrack_timestamp = 1
root@fw:~# nft 'add rule ip filter forward log group 1 prefix "forward-drop"'
root@fw:~# ulogd -d -c /root/ulogd.conf
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Onde os registros da aula são feitos e onde vão parar. No fw, o ulogd escreve drops.json a partir da regra de log e flows.json a partir do rastreamento de conexões, e o rsyslog manda cada linha nova por TCP, porta 514, para o admin, na rede de gerência. O sensor escreve eve.json, que numa rede real chega ao admin por um link de gerência próprio. O firewall do admin aceita a porta 514 vinda do fw e mais nada, então o fw consegue acrescentar linhas mas não consegue entrar para alterá-las.\"><defs><marker id=\"co-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"co-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"co-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"250\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><rect x=\"35\" y=\"60\" width=\"105\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">drops.json</text><text x=\"45\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">regra de log</text><rect x=\"150\" y=\"60\" width=\"105\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">flows.json</text><text x=\"160\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conntrack</text><text x=\"32\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o ulogd escreve, o rsyslog envia</text><rect x=\"20\" y=\"180\" width=\"250\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sensor</text><text x=\"30\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">eve.json: alertas, HTTP, fluxos</text><rect x=\"450\" y=\"30\" width=\"250\" height=\"200\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><text x=\"462\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">coletor, na rede de gerência</text><rect x=\"465\" y=\"85\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/var/log/lab/remote/</text><text x=\"475\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">fw/drops.json  fw/flows.json</text><rect x=\"465\" y=\"145\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"475\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">correlate.py</text><text x=\"475\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma linha do tempo por endereço</text><path d=\"M270 80 L450 80\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#co-ah-phosphor)\"></path><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">tcp/514</text><path d=\"M270 120 L450 120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#co-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">ssh: descartado</text><path d=\"M270 205 L450 205\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#co-ah-paper-dim)\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">link de gerência próprio</text></svg>", "caption": "Os registros são escritos onde as coisas acontecem e guardados onde ninguém que é vigiado alcança.", "same": ["conntrack"]}
```

Depois, um trecho curto e comum de tráfego. Duas requisições da equipe e uma que a política recusa:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/
200
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" http://app:8080/
200
ana@laptop:~$ probe db:5432
db:5432                blocked
```

E um estranho na internet, `remote`, que carrega a página inicial da loja, pede um arquivo que nunca
deveria ser público, e então tenta três máquinas:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/
200
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/.env
404
ana@remote:~$ probe 192.0.2.80:22 192.0.2.53:22 192.168.20.30:5432
192.0.2.80:22          blocked
192.0.2.53:22          blocked
192.168.20.30:5432     blocked
```

A próxima seção lê o que isso deixou para trás.
