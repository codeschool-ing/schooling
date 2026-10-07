---
title: A anatomia de uma regra
version: 1
---

No seu laboratório esta aula começa com `sudo bash nslab.sh reset`, com a política da empresa
carregada no `fw` por `nft -f baseline.nft`. A regra que esta aula carrega no `sensor`, escrita no seu
arquivo de regras vazio, conta tentativas de login que chegam de fora:

```
root@sensor:~# cat /etc/suricata/rules/local.rules
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"login form posted from outside"; flow:to_server,established; http.method; content:"POST"; http.uri; content:"/login"; startswith; detection_filter:track by_src, count 10, seconds 60; classtype:attempted-user; sid:1000201; rev:1;)
```

Os motores leem uma regra como uma linha só, e uma barra invertida no fim de uma linha a continua, que é como ela está dividida aqui. Cada parte faz alguma coisa:

```schooling-example
{"language": "conf", "file": "/etc/suricata/rules/local.rules", "parts": [{"code": "alert http \\", "note": "A **ação** e o **protocolo**. `alert` grava um evento; a aula 14 usou `drop`. `http` significa o protocolo de aplicação tal como o Suricata o reconheceu, em qualquer porta. O Snort 2 escreve `tcp` aqui e casa a porta no lugar."}, {"code": "$EXTERNAL_NET any -> $HOME_NET any \\", "note": "O **cabeçalho**: de qualquer endereço fora da empresa, qualquer porta de origem, para qualquer endereço dentro, qualquer porta. As variáveis vêm do `suricata.yaml`, onde o `HOME_NET` deste laboratório lista as faixas dele."}, {"code": "(msg:\"login form posted from outside\"; \\", "note": "O texto que um analista lê. Escrito para a pessoa, não para o motor."}, {"code": " flow:to_server,established; \\", "note": "Só a metade do cliente de uma conexão cujo handshake se completou. Regras que pulam isto casam pacotes perdidos e forjados."}, {"code": " http.method; content:\"POST\"; http.uri; content:\"/login\"; startswith; \\", "note": "Dois **buffers fixos** (*sticky buffers*): `http.method` aponta o próximo `content` para o método do pedido, `http.uri` aponta o seguinte para o caminho. Cada content só casa dentro do seu buffer, então `/login` em um cookie ou em um campo de formulário não conta."}, {"code": " detection_filter:track by_src, count 10, seconds 60; \\", "note": "A **contagem**: por endereço de origem, a regra só dispara depois que aquela origem casou mais de 10 vezes em 60 segundos. Um login é um cliente; o décimo primeiro em um minuto é outra coisa."}, {"code": " classtype:attempted-user; sid:1000201; rev:1;)", "note": "A categoria, que define a prioridade; o número da regra; a revisão dela, aumentada a cada mudança para que um alerta diga qual versão da regra o produziu."}]}
```

Antes de qualquer coisa rodar, a configuração é testada, arquivos de regras incluídos. Esta também carrega
o `http-events.rules`, regras que vêm com o Suricata e disparam com HTTP malformado, que a seção sobre
anomalias usa. Uma linha no `suricata.yaml` o acrescenta à lista:

```sh
sed -i "/^rule-files:/,/^[a-z]/{s#^  - local.rules#  - local.rules\n  - http-events.rules#}" /etc/suricata/suricata.yaml
```

```
root@sensor:~# grep -A2 "^rule-files" /etc/suricata/suricata.yaml; ls /etc/suricata/rules/http-events.rules
rule-files:
  - local.rules
  - http-events.rules
/etc/suricata/rules/http-events.rules
root@sensor:~# suricata -T -c /etc/suricata/suricata.yaml 2>&1 | tail -1
i: suricata: Configuration provided was successfully loaded. Exiting.
```

Então o sensor sobe na DMZ:

```
root@sensor:~# suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

**Escreva regras contra um buffer, nunca contra o pacote bruto, sempre que existir um buffer.** Um `content`
sem buffer procura no payload inteiro: as mesmas cinco letras em um cabeçalho, um cookie ou uma descrição
de produto, todas casam, e os falsos positivos que vêm depois são o motivo de as pessoas pararem de ler alertas.
