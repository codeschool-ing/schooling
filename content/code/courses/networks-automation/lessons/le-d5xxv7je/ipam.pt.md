---
title: Pedindo um endereço ao NetBox
version: 1
---

O lado IPAM do NetBox, os prefixos e os endereços dentro deles, responde a uma pergunta que
planilhas respondem mal: qual endereço está livre. Um prefixo tem um endpoint `available-ips`, e
criar um endereço nele pega o primeiro livre:

```schooling-example
{
  "language": "python",
  "file": "allocate.py",
  "parts": [
    {
      "code": "import sys\n\nfrom nb import connect\n\nnb = connect()\nprefix = nb.ipam.prefixes.get(prefix=\"203.0.113.0/26\")"
    },
    {
      "code": "ip = prefix.available_ips.create({\"status\": \"active\", \"description\": sys.argv[1]})\nprint(f\"{ip.address} for {ip.description}\")",
      "note": "**O NetBox escolhe o endereço.** `available_ips` é a lista de endereços livres do prefixo; criar nele pega o primeiro e o registra, numa requisição só."
    }
  ]
}
```

**A escolha e o registro acontecem numa só requisição**, e esse é o ponto inteiro: duas pessoas
lendo uma planilha no mesmo instante podem as duas escolher o `.2`, enquanto o NetBox entrega cada
endereço uma vez só. Rodando duas vezes, com a mesma descrição:

```
ana@ctl:~$ cd sot && python allocate.py "printer, branch 1"
203.0.113.2/26 for printer, branch 1
ana@ctl:~$ cd sot && python allocate.py "printer, branch 1"
203.0.113.3/26 for printer, branch 1
```

Endereços para duas impressoras, para uma impressora só. **`create` não é idempotente**: o NetBox
fez exatamente o que pediram, duas vezes, e nada na requisição dizia "a impressora já tem um". É a
pergunta de idempotência da aula 9 de novo, feita a uma API em vez de a um playbook. Um script que
aloca tem de procurar primeiro, por um endereço com aquela descrição ou nome DNS, e criar só
quando não houver nenhum. Ou o endereço tem de estar ligado a algo único, como uma interface, para
que uma segunda tentativa falhe em vez de dar certo duas vezes.

`203.0.113.10`, o endereço do pc1, não foi entregue, e só porque ele não está no NetBox. Os hosts
pc nunca foram registrados, então o NetBox acredita que os endereços deles estão livres. **Uma
fonte da verdade só é tão verdadeira quanto o que foi posto nela**, e um endereço em uso que ela
não conhece é a próxima duplicata que ela vai entregar.
