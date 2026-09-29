---
title: Paramiko, SSH e nada mais
version: 1
---

O script da aula 1 usou o Netmiko sem explicá-lo, e as aulas 2 a 4 usaram APIs. **A maior parte
dos equipamentos de rede em serviço hoje ainda é configurada pelo CLI via SSH**, então as
bibliotecas Python que conduzem um CLI são onde a maior parte da automação começa. São quatro, e
cada uma fica sobre a de baixo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"As quatro bibliotecas como camadas. O Paramiko é SSH: uma conexão e um comando. O Netmiko fica sobre ele e conhece prompts, paginação e modo de configuração de cada equipamento. O NAPALM fica sobre um driver, aqui o Netmiko, e dá os mesmos getters e métodos de configuração em toda plataforma. O Nornir fica acima de todos: guarda o inventário e roda uma tarefa em muitos hosts ao mesmo tempo.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Nornir</text><text x=\"260.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inventário, tarefas, muitos hosts de uma vez</text><rect x=\"40\" y=\"95\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NAPALM</text><text x=\"260.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os mesmos métodos em toda plataforma</text><rect x=\"40\" y=\"170\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Netmiko</text><text x=\"260.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">prompts, paginação, modo de configuração</text><rect x=\"40\" y=\"245\" width=\"440\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Paramiko</text><text x=\"260.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma conexão SSH e um comando</text><rect x=\"520\" y=\"95\" width=\"180\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"610.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o equipamento</text><text x=\"610.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">core1, edge1, edge2</text><path d=\"M482 275 L516 275\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que cada camada acrescenta</text></svg>", "caption": "Cada biblioteca usa a de baixo. Um script escolhe a camada mais alta que faz o que ele precisa.", "same": ["Nornir", "NAPALM", "Netmiko", "Paramiko", "core1, edge1, edge2"]}
```

Na base está o **Paramiko**, uma implementação de SSH em Python puro. Ele abre uma conexão,
autentica, confere a chave do host e executa um comando, e não sabe nada sobre o que está do outro
lado:

```schooling-example
{
  "language": "python",
  "file": "para.py",
  "parts": [
    {
      "code": "import paramiko\n\nclient = paramiko.SSHClient()",
      "note": "**O Paramiko é SSH em Python, e nada mais.** Ele sabe abrir uma conexão, conferir a chave do host e rodar um comando; não sabe nada de roteadores."
    },
    {
      "code": "client.load_system_host_keys(\"/home/ana/.ssh/known_hosts\")\nclient.set_missing_host_key_policy(paramiko.RejectPolicy())\nclient.connect(\"edge1\", username=\"netops\", key_filename=\"/home/ana/.ssh/id_ed25519\")\n",
      "note": "**Recuse um host cuja chave não está em `known_hosts`.** O `AutoAddPolicy` do Paramiko aceita qualquer chave na primeira vez, que é exatamente o que um atacante no meio precisa."
    },
    {
      "code": "stdin, stdout, stderr = client.exec_command(\"show ip ospf neighbor\")\nprint(stdout.read().decode())\nprint(\"exit status\", stdout.channel.recv_exit_status())\nclient.close()",
      "note": "**Um comando, um canal.** O shell de login do roteador é o CLI dele, então o comando roda ali, e o que volta são bytes."
    }
  ]
}
```

```
ana@ctl:~$ python para.py

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
203.0.113.251     1 Full/-          10.906s           39.092s 198.51.100.1    eth1:198.51.100.2                    0     0     0


exit status 0
```

O shell de login do roteador é o seu CLI, então `exec_command` executou `show ip ospf neighbor` ali
e a saída voltou como bytes, com linhas em branco e tudo, junto com um status de saída. **Isso é
tudo o que o Paramiko oferece**, e para um comando num tipo de equipamento é o bastante.

Ele deixa de bastar depressa. A maioria dos equipamentos não aceita um comando como argumento do
jeito que o shell de login do FRR aceita; eles precisam de uma sessão interativa em que o script
espera um prompt, envia uma linha e espera de novo. A paginação tem de ser desligada, ou uma saída
longa para em `--More--`. É preciso entrar no modo de configuração e sair dele. **Cada fabricante
faz tudo isso de um jeito diferente**, e escrever isso para cada um é para o que serve a próxima
camada.

A única coisa a guardar desta seção é a política de chave do host. `RejectPolicy` recusa um
equipamento cuja chave não está em `known_hosts`; a `AutoAddPolicy` que muitos exemplos na internet
usam aceita qualquer chave que ainda não viu, o que **desliga a proteção que o SSH existe para
dar**, o mesmo erro do `verify=False` da aula 2.
