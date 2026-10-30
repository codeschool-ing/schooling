---
title: Pagando por pod
version: 1
---

No Standard a conta são nós, e um nó meio vazio custa o mesmo que um cheio. **No Autopilot a
conta é a CPU, a memória e o armazenamento efêmero que os pods requisitam, enquanto rodam**, mais
a mesma taxa de cluster que a lição 13 calculou. Nenhum dos dois é mais barato em geral; qual
ganha depende de quão bem os seus pods encheriam os nós, e isso dá para calcular antes de
escolher.

## As taxas

```
ana@laptop:~/gcp$ python3 prices.py serverless | grep Autopilot
  Autopilot pod vCPU                                  0.0445  per vCPU-hour
  Autopilot pod memory                             0.0049225  per GiB-hour
```

**0,0445 por vCPU-hora e 0,0049225 por GiB-hora.** Para comparar, uma `e2-standard-4` custa 0,134
por hora por quatro vCPUs e 16 GiB, uns 0,034 por vCPU se a memória viesse de graça. A taxa do
Autopilot é maior por unidade, e o que ela compra é que nenhuma unidade é paga enquanto fica vazia.

O Autopilot também tem um preço Spot para pods que podem ser interrompidos, a mesma ideia que a
lição 6 aplica a máquinas. A página de preços do GKE lista esse preço em 30 de outubro de 2026 a
0,0133 por vCPU-hora e 0,0014767 por GiB-hora, em Iowa; um pod o pede com um node selector, e a
seção 04 volta a quais pods da loja se qualificam.

## Um programa que compara os dois

A comparação é aritmética, e vale tê-la como programa, porque a resposta muda a cada mudança nos
pods. **Salve isto como `~/gcp/autopilot.py`, ao lado do `prices.py`**, que ele importa:

```schooling-example
{"language": "python", "file": "autopilot.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Autopilot or Standard, for the same pods.\n\nEach argument is COUNT:VCPU:GIB, a number of pods and what each one requests.\nAutopilot bills the requests; Standard bills the nodes they are packed onto.\nPrices are prices.py's: Iowa, 30 October 2026, on demand.\n\n    python3 autopilot.py 6:0.5:1 2:1:4\n\"\"\"\n", "note": "A docstring diz quais são os argumentos e de onde vêm os preços. Cada formato de pod se escreve COUNT:VCPU:GIB, então uma mistura de serviços são vários argumentos."}, {"code": "import math\nimport sys\n\nfrom prices import MONTH, VM\n\nPOD_VCPU = 0.0445     # Autopilot, per vCPU-hour of requests\nPOD_GIB = 0.0049225   # Autopilot, per GiB-hour of requests\nNODE = 'e2-standard-4'\n\n\n", "note": "O programa importa o mês e a tabela de máquinas do prices.py, e por isso precisa ficar ao lado dele em ~/gcp. As duas taxas do Autopilot estão na mesma página de preços do GKE que a taxa do cluster, e o prices.py também as imprime."}, {"code": "def allocatable(cpus, gib):\n    \"\"\"What GKE leaves for pods on a Standard node, by its documented reservation.\"\"\"\n    cpu_steps = [(1, 0.06), (1, 0.01), (2, 0.005)]\n    cpu_reserved, left = 0.0, cpus\n    for size, share in cpu_steps:\n        take = min(size, left)\n        cpu_reserved += take * share\n        left -= take\n    cpu_reserved += left * 0.0025\n    mem_steps = [(4, 0.25), (4, 0.20), (8, 0.10), (112, 0.06)]\n    mem_reserved, left = 0.0, gib\n    for size, share in mem_steps:\n        take = min(size, left)\n        mem_reserved += take * share\n        left -= take\n    mem_reserved += left * 0.02 + 0.1   # and the eviction threshold, 100 MiB\n    return cpus - cpu_reserved, gib - mem_reserved\n\n\n", "note": "O que um nó Standard guarda para o sistema antes de qualquer pod chegar: uma fatia decrescente de cada vCPU e de cada GiB, nos degraus da documentação do GKE sobre recursos alocáveis do nó, mais os 100 MiB que o kubelet segura para despejo. Ficam de fora os pods de sistema que o GKE roda em todo nó, então o espaço real é um pouco menor ainda."}, {"code": "def main():\n    pods = [tuple(float(x) for x in arg.split(':')) for arg in sys.argv[1:]]\n    cpu = sum(n * c for n, c, _ in pods)\n    gib = sum(n * g for n, _, g in pods)\n    print(f'{int(sum(n for n, _, _ in pods))} pods requesting {cpu:g} vCPU and {gib:g} GiB')\n\n    auto = (cpu * POD_VCPU + gib * POD_GIB) * MONTH\n    print(f'  Autopilot, the requests:          {auto:8.2f} a month')\n", "note": "Primeiro o Autopilot: a soma das requisições, cobrada por vCPU-hora e por GiB-hora, durante 730 horas."}, {"code": "\n    node_cpu, node_gib, hourly, _ = VM[NODE]\n    free_cpu, free_gib = allocatable(node_cpu, node_gib)\n    nodes = math.ceil(max(cpu / free_cpu, gib / free_gib))\n    std = nodes * hourly * MONTH\n    print(f'  {NODE} leaves {free_cpu:.2f} vCPU and {free_gib:.2f} GiB for pods')\n    print(f'  Standard, {nodes} x {NODE}:          {std:8.2f} a month')\n    print('  (both also pay the cluster fee, and Standard rounds up to whole nodes)')\n\n\nif __name__ == '__main__':\n    main()\n", "note": "Depois o Standard: nós inteiros suficientes para o maior dos dois totais, CPU ou memória, e o preço desses nós. O encaixe real é pod a pod e nunca perfeito, então isto é o piso, não a conta."}]}
```

Rode para a loja: três pods de `web` e três de `orders` de meia vCPU e 1 GiB, e dois pods de
`photos` de uma vCPU e 4 GiB:

```
ana@laptop:~/gcp$ python3 autopilot.py 6:0.5:1 2:1:4
8 pods requesting 5 vCPU and 14 GiB
  Autopilot, the requests:            212.73 a month
  e2-standard-4 leaves 3.92 vCPU and 13.30 GiB for pods
  Standard, 2 x e2-standard-4:            195.67 a month
  (both also pay the cluster fee, and Standard rounds up to whole nodes)
```

**Perto, e o Standard um pouco à frente, 195,67 contra 212,73**; mas esse valor do Standard é um
piso que supõe dois nós numa zona encaixados com perfeição. A lição 13 pôs um pool regional em um
nó por zona, três no mínimo, o que dá 293,51 por mês; o Autopilot espalha os pods pelas zonas sem
cobrar pelo espaço vazio que isso exige.

Agora uma equipe com serviços minúsculos, dois pods de um quarto de vCPU e meio GiB:

```
ana@laptop:~/gcp$ python3 autopilot.py 2:0.25:0.5
2 pods requesting 0.5 vCPU and 1 GiB
  Autopilot, the requests:             19.84 a month
  e2-standard-4 leaves 3.92 vCPU and 13.30 GiB for pods
  Standard, 1 x e2-standard-4:             97.84 a month
  (both also pay the cluster fee, and Standard rounds up to whole nodes)
```

**19,84 contra 97,84.** Um nó é o menor tamanho que o Standard pode ter, e esses pods usam um
dezesseis avos dele. E uma equipe que roda pods grandes e estáveis que enchem nós:

```
ana@laptop:~/gcp$ python3 autopilot.py 12:1:4
12 pods requesting 12 vCPU and 48 GiB
  Autopilot, the requests:            562.30 a month
  e2-standard-4 leaves 3.92 vCPU and 13.30 GiB for pods
  Standard, 4 x e2-standard-4:            391.35 a month
  (both also pay the cluster fee, and Standard rounds up to whole nodes)
```

**391,35 contra 562,30.** Doze pods de uma vCPU e 4 GiB cabem em quatro nós com pouca sobra, e o
preço do nó por vCPU é menor que o do Autopilot.

O padrão é o que vale lembrar: **o Autopilot ganha quando os nós ficariam meio vazios, e o Standard
ganha quando os pods enchem os nós de forma constante.** Serviços pequenos, carga irregular e
clusters ociosos à noite pendem para o Autopilot. Frotas grandes e estáveis pendem para o Standard.

## O que o programa deixa de fora

É uma primeira resposta, não uma fatura, e ele diz três coisas que não modela. Os nós do Standard
rodam pods de sistema próprios, então comportam menos do que o `allocatable` diz. O Autopilot
**aumenta requisições abaixo dos mínimos dele ou fora da proporção permitida de memória por CPU**,
e cobra pelos valores aumentados; a documentação do Google tem a tabela atual, e um pod pedindo
0,1 vCPU pode ser cobrado por mais. E os dois pagam a taxa do cluster, que o programa deixa de fora
porque é igual dos dois lados.
