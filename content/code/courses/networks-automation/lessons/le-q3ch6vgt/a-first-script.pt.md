---
title: Um primeiro script
version: 1
---

A mesma mudança, escrita uma vez em Python e executada nos três roteadores. Ela usa o
**Netmiko**, a biblioteca que a aula 8 desmonta direito: ele abre uma sessão SSH, reconhece o
prompt do roteador e envia comandos como uma pessoa enviaria.

```schooling-example
{
  "language": "python",
  "file": "mgmt.py",
  "parts": [
    {
      "code": "from netmiko import ConnectHandler\n\nROUTERS = [\"core1\", \"edge1\", \"edge2\"]\nLINE = \"ip prefix-list MGMT seq 10 permit 192.0.2.0/24\"\n",
      "note": "**A lista de roteadores é dado.** Três nomes hoje; o laço abaixo não se importa se são três ou trezentos."
    },
    {
      "code": "for name in ROUTERS:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")",
      "note": "**Um login por roteador**, com a chave SSH da ana em vez de uma senha escrita no arquivo. `cisco_ios` é o driver cujos prompts batem com o CLI do FRR; a aula 8 explica por que essa é a escolha aqui."
    },
    {
      "code": "    router.send_config_set([LINE])\n    router.save_config()\n    router.disconnect()\n    print(f\"{name}: MGMT set\")",
      "note": "**As mesmas duas linhas em todos os roteadores**, enviadas no modo de configuração e depois salvas. Nada aqui pode sair digitado errado em um roteador e certo nos outros."
    }
  ]
}
```

**O script faz exatamente o que as três sessões fizeram**: entra, vai ao modo de configuração,
envia a linha, salva. A diferença é que a linha existe num lugar só, `LINE`, e a lista de
roteadores em outro, `ROUTERS`. Nenhuma das duas é digitada num prompt.

Rodando, no `ctl`:

```
ana@ctl:~$ time python mgmt.py
core1: MGMT set
edge1: MGMT set
edge2: MGMT set

real	0m3.539s
user	0m0.238s
sys	0m0.137s
```

E a pergunta da primeira seção, feita de novo:

```
ana@ctl:~$ for r in core1 edge1 edge2; do echo "== $r"; ssh netops@$r "show running-config" | grep MGMT; done
== core1
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
== edge1
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
== edge2
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
```

Os três concordam. O `edge1` agora tem a rede certa, e só uma entrada, porque **uma entrada de
prefix list no FRR é identificada pelo número de sequência**: o `seq 10` do script substituiu o
`seq 10` digitado errado em vez de ser acrescentado ao lado dele. Isso é uma propriedade do CLI
deste roteador, e vale conferir em cada plataforma antes de confiar num script para sobrescrever
qualquer coisa. Uma linha com outro número de sequência teria deixado o erro no lugar.

`send_config_set` entra e sai do modo de configuração sozinho, e `save_config` é o
`write memory` deste driver. **Salvar faz parte do script**, então o erro da primeira seção,
esquecer de salvar, não pode acontecer em um roteador e não nos outros.
