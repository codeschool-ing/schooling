---
title: Netmiko, que conhece o equipamento
version: 1
---

**O Netmiko é o Paramiko mais o conhecimento do CLI de cada equipamento**: o prompt, como desligar
a paginação, como entrar no modo de configuração, como salvar. Esse conhecimento fica em drivers,
escolhidos por `device_type`, e há drivers para mais de cem plataformas.

```schooling-example
{
  "language": "python",
  "file": "nm.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n"
    },
    {
      "code": "edge1 = ConnectHandler(device_type=\"cisco_ios\", host=\"edge1\", username=\"netops\",\n                       use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")\nprint(repr(edge1.find_prompt()))",
      "note": "**O Netmiko acrescenta o que falta ao Paramiko: o equipamento.** `device_type` escolhe um driver que conhece o prompt, como desligar a paginação, como entrar no modo de configuração e como salvar."
    },
    {
      "code": "print(edge1.send_command(\"show ip route ospf\"))\nedge1.disconnect()",
      "note": "**`send_command` manda uma linha e espera o prompt voltar**, então a saída vem completa, por maior que seja."
    }
  ]
}
```

```
ana@ctl:~$ python nm.py
'edge1#'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   192.0.2.0/24 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:01
O   198.51.100.0/30 [110/10] is directly connected, eth1, weight 1, 00:00:22
O>* 198.51.100.4/30 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:02
O   203.0.113.0/26 [110/10] is directly connected, eth2, weight 1, 00:00:22
O>* 203.0.113.64/26 [110/30] via 198.51.100.1, eth1, weight 1, 00:00:02
O>* 203.0.113.251/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:01
O>* 203.0.113.253/32 [110/20] via 198.51.100.1, eth1, weight 1, 00:00:01
```

`find_prompt` devolveu `edge1#`, e `send_command` esperou esse prompt voltar depois do comando,
então devolve a saída inteira, seja qual for o tamanho. O Netmiko também desligou a paginação ao
entrar, e é por isso que nada parou ao encher a tela.

**O laboratório usa o driver `cisco_ios`**, e essa é uma escolha sobre a qual vale ser honesto. O
Netmiko não tem driver para FRR. O CLI do FRR é modelado no da Cisco, com os mesmos prompts,
`configure terminal`, `end` e `write memory`, então o driver da Cisco o conduz corretamente em tudo o
que este curso faz. O único comando que ele envia ao entrar, `terminal width 511`, é um que o FRR
não tem, e a recusa do FRR é ignorada. Num roteador Cisco de verdade o driver seria o mesmo, e em
Junos, EOS ou RouterOS o nome mudaria e o resto do script não.

A saída acima é o problema que a próxima seção resolve. Ela é uma tela, feita para uma pessoa:
códigos explicados no topo, colunas alinhadas com espaços, um tempo que muda a cada segundo. **Um
script que recorta campos dela por posição quebra no dia em que uma atualização de software
acrescenta uma coluna.**
