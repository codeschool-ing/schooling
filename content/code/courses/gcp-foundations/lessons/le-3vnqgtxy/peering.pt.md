---
title: Peering de VPC, e o que ele não repassa
version: 1
---

**O peering de VPC une duas redes separadas para que as máquinas delas se alcancem por endereços internos.** As
duas podem estar em projetos diferentes e organizações diferentes, que é o caso que o Shared VPC não cobre: a
rede de um parceiro, ou a rede de uma empresa que o planner comprou. Cada lado mantém a própria rede, as
próprias regras de firewall e os próprios administradores.

Três regras decidem o que um peering faz:

- **Os dois lados têm de criá-lo.** Um peering do planner para o parceiro fica inativo até o parceiro criar um
  de volta. Nenhum lado consegue se juntar a uma rede que não concordou.
- **Nenhuma faixa de um lado pode se sobrepor a uma faixa do outro.** O peering troca rotas de sub-rede, e duas
  rotas para os mesmos endereços seriam duas respostas para uma pergunta. O Google recusa o peering quando ele é
  criado.
- **O peering não é transitivo.** Se o planner faz peering com o parceiro e com uma rede de analytics, o
  parceiro e analytics não se alcançam pelo planner. Cada par que precisa conversar precisa de um peering
  próprio.

O que ele não troca importa tanto quanto. **As regras de firewall ficam em cada lado**: as regras do planner
filtram o que chega às máquinas do planner, as do parceiro o que chega às dele, e um peering não abre nada até
os dois terem escrito regras que permitam. **Rotas personalizadas não são trocadas a menos que se peça**, que é
a opção `export_custom_routes` mais abaixo.

## A aritmética de quem alcança quem

As três regras podem ser conferidas antes de alguém criar qualquer coisa. Salve as redes e os peerings do
planner como `~/gcp/peering/peerings.json`. `acquired` é a rede de uma pequena empresa que o planner acabou de
comprar, que numerou a sub-rede de São Paulo do mesmo jeito que o planner:

```sh
mkdir -p ~/gcp/peering && cd ~/gcp/peering
```

```json
{
  "networks": {
    "planner": ["10.10.0.0/16", "10.11.0.0/16"],
    "partner": ["10.128.0.0/9"],
    "analytics": ["10.30.0.0/16"],
    "acquired": ["10.10.0.0/20", "192.168.0.0/24"]
  },
  "peerings": [["planner", "partner"], ["planner", "analytics"]]
}
```

E o programa, como `reach.py`:

```schooling-example
{"language": "python", "file": "reach.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Says whether one network reaches another through VPC peering.\n\n    python3 reach.py FROM TO\n\nThe networks, their ranges and the peerings that exist are read from\npeerings.json. A pair that is not peered is also checked for whether a\npeering between them could be made at all.\n\"\"\"\nimport ipaddress\nimport json\nimport sys\n\n", "note": "Como é chamado: dois nomes de rede. O que ele responde vem do arquivo, então o mesmo programa confere qualquer ambiente."}, {"code": "data = json.load(open('peerings.json'))\nranges = {name: [ipaddress.ip_network(r) for r in rs] for name, rs in data['networks'].items()}\npeered = {frozenset(pair) for pair in data['peerings']}\n\n", "note": "Ler as redes com as faixas delas, e os peerings como pares sem ordem: um peering entre o planner e o parceiro é o mesmo peering lido de qualquer ponta."}, {"code": "a, b = sys.argv[1], sys.argv[2]\nif frozenset((a, b)) in peered:\n    print(f'{a} -> {b}: reachable, they are peered')\n    sys.exit(0)\n\n", "note": "Um par com peering se alcança, e essa é a resposta inteira."}, {"code": "via = sorted(n for n in ranges if frozenset((a, n)) in peered and frozenset((n, b)) in peered)\nif via:\n    print(f'{a} -> {b}: not reachable; both peer with {\", \".join(via)}, and peering is not transitive')\nelse:\n    print(f'{a} -> {b}: not reachable, no peering')\n\n", "note": "Senão, achar qualquer rede com que os dois façam peering. Esse é o caso que as pessoas esperam que funcione, então o programa o nomeia: alcançar um vizinho comum não é se alcançar."}, {"code": "clash = [(x, y) for x in ranges[a] for y in ranges[b] if x.overlaps(y)]\nfor x, y in clash:\n    print(f'  a peering would be refused: {x} overlaps {y}')\nif not clash:\n    print('  a peering could be made: no ranges overlap')\nsys.exit(1)\n", "note": "Se um peering entre os dois poderia ser feito: todo par de faixas comparado, e qualquer sobreposição nomeada, já que o Google recusaria o peering por ela."}]}
```

O planner e o parceiro, depois o parceiro e analytics:

```
ana@laptop:~/gcp/peering$ python3 reach.py planner partner
planner -> partner: reachable, they are peered
ana@laptop:~/gcp/peering$ python3 reach.py partner analytics
partner -> analytics: not reachable; both peer with planner, and peering is not transitive
  a peering could be made: no ranges overlap
```

**Os dois fazem peering com o planner e ainda assim não se alcançam.** Se precisarem, fazem peering direto; o
programa diz que isso funcionaria, já que `10.128.0.0/9` e `10.30.0.0/16` não se sobrepõem. E a empresa
comprada:

```
ana@laptop:~/gcp/peering$ python3 reach.py planner acquired
planner -> acquired: not reachable, no peering
  a peering would be refused: 10.10.0.0/16 overlaps 10.10.0.0/20
```

Essa não pode receber peering nenhum até alguém renumerar, e renumerar uma rede que tem máquinas nela é a
mudança cara que a lição 15 disse que as faixas são. Uma VPN também não ajudaria: a mesma sobreposição a
quebra, lição 21.

## Escrevendo um lado

Salve isto como `peering.tf` no mesmo diretório, depois de copiar para lá o arquivo do provider da lição 2:

```sh
cp ~/gcp/hierarchy/provider.tf . && terraform init -input=false
```

```hcl
resource "google_compute_network_peering" "planner_to_partner" {
  name         = "planner-to-partner"
  network      = "projects/planner-network/global/networks/planner"
  peer_network = "projects/partner-prod/global/networks/partner"
}
```

```
ana@laptop:~/gcp/peering$ terraform plan -input=false -no-color | grep -E "^Plan|# google|export_custom|import_custom"
  # google_compute_network_peering.planner_to_partner will be created
      + export_custom_routes                = false
      + import_custom_routes                = false
Plan: 1 to add, 0 to change, 0 to destroy.
```

Um lado, planejado. O parceiro escreve o outro no próprio projeto, com os dois nomes trocados. Os padrões
voltaram **false** para exportar e importar rotas personalizadas: o parceiro aprende as sub-redes do planner e
nada mais, então uma rota que o planner tem para o escritório não vira, sem ninguém ver, uma rota do parceiro
para o escritório do planner.
