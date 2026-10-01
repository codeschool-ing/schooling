---
title: O que o equipamento serve
version: 1
---

O `gnmic` lê as configurações dele do `~/.gnmic.yaml`, então o usuário, a autoridade certificadora
e a codificação são escritos uma vez só em vez de em todo comando:

```yaml
username: netops
tls-ca: lab-ca.pem
encoding: json_ietf
```

A senha vai para o mesmo arquivo, acrescentada a partir do `~/.netops-password` para nunca ser
digitada, e o arquivo fica legível só pela `ana`:

```
ana@ctl:~$ echo "password: $(cat .netops-password)" >> .gnmic.yaml; chmod 600 .gnmic.yaml
```

**`Capabilities` é a primeira pergunta a fazer a qualquer equipamento**, pelo mesmo motivo que o
hello do NETCONF foi na aula 3: ela diz o que o resto da conversa pode usar.

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 capabilities
gNMI version: 0.8.0
supported models:
  - openconfig-interfaces, OpenConfig working group, 3.11.0
  - openconfig-system, OpenConfig working group, 3.3.0
supported encodings:
  - JSON
  - JSON_IETF
```

Três respostas. Os **modelos** são os módulos YANG a partir dos quais o equipamento sabe responder,
cada um com a organização que o publica e uma versão: aqui `openconfig-interfaces` 3.11.0 e
`openconfig-system` 3.3.0. As **codificações** são as formas em que os valores podem viajar; as duas
são JSON, sendo `JSON_IETF` a variante da RFC 7951 com prefixos de módulo que o RESTCONF usou na
aula 3. Equipamentos reais acrescentam `PROTO`, valores como Protocol Buffers, que é menor e mais
rápido de interpretar. A **versão do gNMI** é a versão do protocolo, não do software do
equipamento.

**A versão de um modelo importa mais do que parece.** Os modelos OpenConfig mudam entre versões,
uma folha muda de lugar ou uma lista ganha uma chave, e um coletor escrito contra a 3.11.0 pode
pedir a um equipamento com uma versão mais antiga um caminho que não existe lá. Um script que lê as
capacidades primeiro consegue dizer isso com clareza em vez de falhar num `NotFound` que não sabe
explicar.

Uma senha errada é recusada antes de qualquer outra coisa, com o código de status do próprio gRPC:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 -p guess capabilities
target "edge1.example.net:9339", capabilities request failed: "edge1.example.net:9339" CapabilitiesRequest failed: rpc error: code = Unauthenticated desc = wrong or missing username and password
Error: one or more requests failed
```

O `-p guess` na linha de comando sobrepõe o arquivo, e é por isso que este falhou. O status,
`Unauthenticated`, é um dos códigos de status do próprio gRPC, que fazem o papel que os códigos de
status do HTTP fizeram na aula 2.
