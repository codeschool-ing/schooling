---
title: Mudando um registro, e a "propagação"
version: 1
---

O site está mudando para um servidor novo, `192.0.2.81`. No `ns1`, o arquivo da zona recebe o endereço
novo, e o **número de série** dela sobe um, que é como os servidores secundários sabem que a zona mudou:

```
ana@ns1:~$ grep -E "^www|SOA" /etc/bind/db.example.com
@            SOA    ns1.example.com. hostmaster.example.com. 2026092501 3600 900 1209600 300
www    300   A      192.0.2.80
www    300   AAAA   2001:db8:10::80
ana@ns1:~$ sudo sed -i 's/2026092501/2026092502/; s/^www    300   A      192.0.2.80/www    300   A      192.0.2.81/' /etc/bind/db.example.com
ana@ns1:~$ sudo named-checkzone example.com /etc/bind/db.example.com
zone example.com/IN: loaded serial 2026092502
OK
ana@laptop:~$ dig @ns1.example.com +noall +answer www.example.com
www.example.com.        300     IN      A       192.0.2.81
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        293     IN      A       192.0.2.80
```

**O `named-checkzone` antes de recarregar**, sempre: um erro de digitação num arquivo de zona pode
tirar o domínio inteiro da internet, e a checagem custa um segundo. Depois o `ns1` foi mandado
recarregar, e as duas perguntas do fim contam a história. O `ns1` responde **`192.0.2.81`** na hora.
O resolver ainda responde **`192.0.2.80`**, com 293 segundos pela frente: ele perguntou antes da
mudança, e ouviu que podia guardar a resposta por 300 segundos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"Uma linha do tempo da mudança de endereço, lida dos TTLs que o resolver deu. O resolver responde 192.0.2.80 com TTL 299. Cinco segundos depois, 192.0.2.80 com 294. Então o ns1 muda para 192.0.2.81. Perguntado de novo, o resolver ainda responde .80, com 293 segundos restantes. Depois de o cache ser limpo, ele responde .81 com um TTL novo de 300. Sem limpar, continuaria respondendo .80 até o TTL chegar a zero, 300 segundos depois de ter guardado o registro.\"><defs><marker id=\"tl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 70 L690 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tl-ah)\"></path><text x=\"650\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><circle cx=\"40\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"34\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resposta .80, TTL 299</text><circle cx=\"180\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"174\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">de novo: .80, TTL 294</text><circle cx=\"320\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"314\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ns1 mudou para .81</text><circle cx=\"450\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"444\" y=\"30\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resolver: .80, TTL 293</text><circle cx=\"580\" cy=\"70\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"574\" y=\"48\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">limpo: .81, TTL 300</text><rect x=\"40\" y=\"118\" width=\"640\" height=\"26\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"52\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem limpar: .80 até o TTL chegar a zero, 300 segundos depois de guardado</text></svg>", "caption": "O que chamam de propagação é cache expirando. Todo resolver que perguntou antes da mudança fica com a resposta antiga pelo TTL que recebeu.", "same": ["resolver: .80, TTL 293"]}
```

**A "propagação do DNS" é só isso**: todo resolver do mundo que perguntou antes da mudança fica com a
resposta antiga até o TTL dela acabar. Nada está sendo enviado a lugar nenhum. Quem opera o resolver
pode encurtar:

```
ana@resolver:~$ sudo unbound-control -c /etc/unbound/unbound.conf flush www.example.com
ok
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        300     IN      A       192.0.2.81
```

Só que ninguém consegue limpar todos os resolvers do mundo, e por isso uma mudança é planejada em
torno do TTL. **Baixe-o dias antes da mudança**, para 300 segundos ou menos, espere o TTL antigo, mais
longo, acabar, faça a mudança, e suba o TTL de novo depois. Aí a "propagação" leva minutos. Com um TTL
de um dia, o que é comum, leva um dia, e não há nada que alguém possa fazer na manhã da mudança.
