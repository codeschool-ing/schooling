---
title: Cortando as faixas
version: 1
---

**As faixas são a única decisão numa rede que é cara de mudar**, porque todo o resto está preso a elas:
máquinas tiram endereços delas, regras de firewall as nomeiam, e toda rede a que o planner um dia se unir,
lições 18 e 21, não pode se sobrepor a elas. Escolhê-las é aritmética, e aritmética pode ser feita antes de
qualquer coisa existir.

Três regras do Google dão o contorno:

- **O Google guarda quatro endereços da faixa primária de toda sub-rede**: o primeiro, que é a própria rede; o
  segundo, o gateway da sub-rede; o penúltimo, guardado para uso futuro do Google; e o último, o endereço de
  broadcast. Um `/24` deixa 252 para máquinas, um `/29`, o menor que uma sub-rede pode ser, deixa quatro.
- **Uma faixa primária pode ser expandida e nunca encolhida.** A ajuda do gcloud para `subnets
  expand-ip-range` diz que o novo comprimento de prefixo *must be smaller than the original*, ou seja, uma
  faixa maior, e os endereços ao lado da faixa antiga têm de estar livres para ela crescer. Deixar espaço ao
  lado de cada faixa é mais barato que acertar o tamanho dela.
- **Duas sub-redes de uma rede não podem se sobrepor**, e o Google confere isso quando uma sub-rede é criada.

O provider não confere nada da terceira regra. Acrescente ao `~/gcp/network/network.tf` uma sub-rede de
staging cuja faixa cai dentro da de São Paulo:

```hcl
resource "google_compute_subnetwork" "staging" {
  project       = "planner-dev"
  name          = "planner-staging"
  network       = google_compute_network.planner.id
  region        = "southamerica-east1"
  ip_cidr_range = "10.10.8.0/21"
}
```

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color | grep -E "^Plan:"
Plan: 4 to add, 0 to change, 0 to destroy.
```

**O plano sai limpo, e o apply falharia**: `10.10.8.0/21` é a metade de cima de `10.10.0.0/20`, e o Google
recusaria a sub-rede de staging quando lhe pedissem para criá-la, depois de a rede e as outras sub-redes já
terem sido feitas. Essa recusa não foi produzida aqui; é a regra acima, da documentação do Google. O jeito de
vê-la antes de um apply é conferir as faixas no laptop. Salve isto como `~/gcp/ranges.py`:

```schooling-example
{"language": "python", "file": "ranges.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Checks a plan of subnet ranges before any of them is created.\n\n    python3 ranges.py NAME=CIDR [NAME=CIDR ...]\n\nPrints how many addresses each range leaves for machines, then every pair that overlaps, and exits 1 if\nany do. A range is also compared with 10.128.0.0/9, the block every\nauto mode network takes its subnets from.\n\"\"\"\nimport ipaddress\nimport sys\n\n", "note": "O que o programa confere, e como é chamado: um argumento `NAME=CIDR` por faixa, só com o `ipaddress` da biblioteca padrão."}, {"code": "AUTO = ipaddress.ip_network('10.128.0.0/9')\nRESERVED = 4  # network, gateway, second-to-last, broadcast\n\n", "note": "Dois fatos do Google de que o programa precisa: o bloco de onde redes automáticas cortam as sub-redes, e os quatro endereços que o Google guarda na faixa primária de toda sub-rede."}, {"code": "plan = []\nfor arg in sys.argv[1:]:\n    name, cidr = arg.split('=')\n    plan.append((name, ipaddress.ip_network(cidr)))\n\n", "note": "Ler o plano. O `ip_network` recusa uma faixa escrita com bits de host ligados, `10.10.0.1/20` por exemplo, e essa é a primeira conferência do programa, que não custa nada escrever."}, {"code": "for name, net in plan:\n    note = '' if net.is_private else '  (not a private range)'\n    print(f'{name:18} {str(net):16} {net.num_addresses - RESERVED:>7} usable{note}')\n\n", "note": "Uma linha por faixa: o nome, a faixa, e quantos endereços ela deixa para máquinas depois que os quatro do Google são tirados. Uma faixa fora dos blocos privados é marcada, porque pode ser de alguém na internet."}, {"code": "clashes = [(a, b) for i, (a, x) in enumerate(plan) for b, y in plan[i + 1:] if x.overlaps(y)]\nclashes += [(name, 'any auto mode network') for name, net in plan if net.overlaps(AUTO)]\nfor a, b in clashes:\n    print(f'overlap: {a} and {b}')\nsys.exit(1 if clashes else 0)\n", "note": "Todo par de faixas que se sobrepõem, e toda faixa que cai no bloco automático. Sair com 1 quando há uma significa que o programa pode ficar na frente de um `terraform apply` num pipeline e pará-lo."}]}
```

O plano do planner, três regiões com um `/20` cada e espaço entre elas:

```
ana@laptop:~/gcp$ python3 ranges.py sao-paulo=10.10.0.0/20 santiago=10.11.0.0/20 virginia=10.12.0.0/20; echo "exit $?"
sao-paulo          10.10.0.0/20        4092 usable
santiago           10.11.0.0/20        4092 usable
virginia           10.12.0.0/20        4092 usable
exit 0
```

Saída 0: nenhuma sobreposição, e cada região tem 4.092 endereços com o resto do seu `/16` livre para crescer.
Agora o erro de staging, e uma rede de desenvolvimento que alguém fez em modo automático, cujas sub-redes caem
todas em `10.128.0.0/9`; `10.158.0.0/20` faz o papel de uma delas:

```
ana@laptop:~/gcp$ python3 ranges.py sao-paulo=10.10.0.0/20 staging=10.10.8.0/21 dev=10.158.0.0/20; echo "exit $?"
sao-paulo          10.10.0.0/20        4092 usable
staging            10.10.8.0/21        2044 usable
dev                10.158.0.0/20       4092 usable
overlap: sao-paulo and staging
overlap: dev and any auto mode network
exit 1
```

Os dois achados, e o status de saída diz isso. **A regra prática do planner** sai da mesma aritmética: um
`/16` de `10.0.0.0/8` por rede e ambiente, um `/20` dele por região, e uma lista escrita de que `/16` é de
quem, guardada junto com o Terraform. Os oito bits entre `/8` e `/16` dão 256 blocos assim, que é mais redes
do que o planner vai ter um dia e poucos o bastante para a lista caber numa tela.
