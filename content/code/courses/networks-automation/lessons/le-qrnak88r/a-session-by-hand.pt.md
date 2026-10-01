---
title: Uma sessão NETCONF, à mão
version: 1
---

Antes de qualquer biblioteca, o próprio protocolo. O NETCONF roda sobre SSH, na porta 830, como
um **subsystem** SSH chamado `netconf`: a conexão carrega mensagens XML em vez de um shell. Esta é
a conversa inteira de uma sessão, escrita num arquivo:

```
<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <capabilities><capability>urn:ietf:params:netconf:base:1.0</capability></capabilities>
</hello>]]>]]>
<rpc message-id="1" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <get-config><source><running/></source>
    <filter type="subtree">
      <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces"><interface><name>eth1</name></interface></interfaces>
    </filter>
  </get-config>
</rpc>]]>]]>
<rpc message-id="2" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><close-session/></rpc>]]>]]>
```

Três mensagens, cada uma terminada pelo marcador `]]>]]>`. A primeira é o **hello** do cliente,
dizendo quais versões do protocolo ele fala. A segunda é um **rpc**, uma requisição, pedindo parte
da configuração running. A terceira fecha a sessão. `ssh -s` abre o subsystem, o arquivo entra, e
o `frames.py` só indenta o que volta para que uma pessoa consiga ler:

```
ana@ctl:~$ (cat hello.xml; sleep 2) | ssh -p 830 -s netops@nc1.example.net netconf | python3 frames.py
<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
  <capabilities>
    <capability>urn:ietf:params:netconf:base:1.1</capability>
    <capability>urn:ietf:params:netconf:base:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:yang-library:1.1?revision=2019-01-04&amp;module-set-id=0</capability>
    <capability>urn:ietf:params:netconf:capability:candidate:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:validate:1.1</capability>
    <capability>urn:ietf:params:netconf:capability:startup:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:xpath:1.0</capability>
    <capability>urn:ietf:params:netconf:capability:with-defaults:1.0?basic-mode=explicit&amp;also-supported=report-all,trim,report-all-tagged</capability>
    <capability>urn:ietf:params:netconf:capability:notification:1.0</capability>
    <capability>urn:ietf:params:xml:ns:yang:ietf-netconf-monitoring</capability>
    <capability>urn:ietf:params:netconf:capability:confirmed-commit:1.1</capability>
  </capabilities>
  <session-id>1</session-id>
</hello>
]]>]]>
<rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="1">
  <data>
    <interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces">
      <interface xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type">
        <name>eth1</name>
        <description>uplink to core1</description>
        <type>ianaift:ethernetCsmacd</type>
        <enabled>true</enabled>
      </interface>
    </interfaces>
  </data>
</rpc-reply>
]]>]]>
<rpc-reply xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="2">
  <ok/>
</rpc-reply>
]]>]]>
```

**O hello do servidor lista as capacidades dele**, e cada uma é uma promessa. `candidate` quer
dizer que existe um datastore candidate. `validate` quer dizer que ele consegue verificar uma
configuração sem aplicá-la. `confirmed-commit` quer dizer que commits podem se desfazer sozinhos.
Um cliente que precisa de uma delas lê o hello primeiro, porque um equipamento sem `candidate` tem
que ser configurado de outro jeito.

Depois, a resposta a `message-id="1"`. O filtro pediu a interface chamada `eth1`, e o servidor
devolveu exatamente essa entrada, **com cada elemento no seu namespace**: `interfaces` pertence a
`urn:ietf:params:xml:ns:yang:ietf-interfaces`, o modelo que o define, e o valor de `type` é
escrito com o prefixo de outro modelo, `iana-if-type`. A última resposta, `<ok/>`, confirma o
fechamento.

Ninguém escreve isso à mão duas vezes. O enquadramento, os ids das mensagens e o subsystem SSH são
o que o `ncclient` faz por você, e o resto da aula usa ele. **O que ele não esconde é o XML**, e
os namespaces dentro dele são a primeira coisa que dá errado.
