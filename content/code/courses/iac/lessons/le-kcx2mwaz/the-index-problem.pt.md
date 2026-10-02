---
title: O problema do índice
version: 1
---

**Um endereço de `count` é uma posição, não um nome.** `aws_subnet.app[1]` não quer dizer "a
sub-rede de 10.20.2.0/24"; quer dizer "o que estiver em segundo na lista". Tire algo do meio da
lista e cada elemento depois dele desce uma posição. O Terraform casa o arquivo com o state pelo
endereço, então ele não vê uma sub-rede removida. Ele vê cópias cujos argumentos mudaram.

A Ana decide que a loja não precisa mais da sub-rede do meio. Ela não mexe no `main.tf`; define a
variável num `terraform.tfvars` ao lado dele, que a aula 2 mostrou sobrepor o default:

```hcl
subnets = ["10.20.1.0/24", "10.20.3.0/24"]
```

O que ela quer dizer é "uma sub-rede a menos". Eis o que o plano diz, com o meio cortado até a
parte que importa:

```
Terraform will perform the following actions:

  # aws_subnet.app[1] must be replaced
-/+ resource "aws_subnet" "app" {
      ~ arn                                            = "arn:aws:ec2:sa-east-1:123456789012:subnet/subnet-d8ac29fa3f1f0aab7" -> (known after apply)
      ~ availability_zone                              = "sa-east-1b" -> (known after apply)
      ~ availability_zone_id                           = "sae1-az2" -> (known after apply)
      ~ cidr_block                                     = "10.20.2.0/24" -> "10.20.3.0/24" # forces replacement
      - enable_lni_at_device_index                     = 0 -> null
      ~ id                                             = "subnet-d8ac29fa3f1f0aab7" -> (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      - map_customer_owned_ip_on_launch                = false -> null
      ~ owner_id                                       = "123456789012" -> (known after apply)
      ~ private_dns_hostname_type_on_launch            = "ip-name" -> (known after apply)
        tags                                           = {
            "Project" = "shop"
        }
        # (11 unchanged attributes hidden)
    }

  # aws_subnet.app[2] will be destroyed
  # (because index [2] is out of range for count)
```
```
Plan: 1 to add, 0 to change, 2 to destroy.
```

Dois recursos são tocados por uma mudança que devia tocar um. A cópia `[1]` era `10.20.2.0/24` e o
argumento dela agora é a terceira faixa, `10.20.3.0/24`. A faixa de uma sub-rede não pode ser
editada no lugar, então o plano marca essa linha com `# forces replacement` e a sub-rede inteira é
destruída e criada de novo. A cópia `[2]` não tem mais um elemento de onde vir, e o plano diz isso
com todas as letras: **out of range for count**. Ela é destruída.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Dois painéis. À esquerda, count: antes, app[0], app[1] e app[2] guardam 10.20.1.0/24, 10.20.2.0/24 e 10.20.3.0/24. Depois que a faixa do meio sai, app[0] é mantida, app[1] passa a ter de guardar 10.20.3.0/24 e é substituída, e app[2] é destruída. À direita, for_each: web, app e db guardam as mesmas três faixas; ao remover app, web e db são mantidas e só app é destruída.\"><defs><marker id=\"ix-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ix-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"8\" width=\"340\" height=\"254\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">count</text><text x=\"69.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um endereço é uma posição</text><text x=\"24.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes</text><text x=\"24.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois de remover 10.20.2.0/24</text><rect x=\"20\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[0]</text><text x=\"70.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><path d=\"M70 108 L70 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-phosphor)\"></path><rect x=\"20\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[0]</text><text x=\"70.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"70.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mantida</text><rect x=\"130\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[1]</text><text x=\"180.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><path d=\"M180 108 L180 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-amber)\"></path><rect x=\"130\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[1]</text><text x=\"180.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"180.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">substituída</text><rect x=\"240\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[2]</text><text x=\"290.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M290 108 L290 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ix-ah-amber)\"></path><rect x=\"240\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"290.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app[2]</text><text x=\"290.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">destruída</text><rect x=\"370\" y=\"8\" width=\"340\" height=\"254\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">for_each</text><text x=\"450.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um endereço é uma chave</text><text x=\"384.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes</text><text x=\"384.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois de remover 10.20.2.0/24</text><rect x=\"380\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"web\"]</text><text x=\"430.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><path d=\"M430 108 L430 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-phosphor)\"></path><rect x=\"380\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"web\"]</text><text x=\"430.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"430.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mantida</text><rect x=\"490\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"app\"]</text><text x=\"540.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><path d=\"M540 108 L540 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ix-ah-amber)\"></path><rect x=\"490\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app[\"app\"]</text><text x=\"540.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">destruída</text><rect x=\"600\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"db\"]</text><text x=\"650.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M650 108 L650 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-phosphor)\"></path><rect x=\"600\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"db\"]</text><text x=\"650.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"650.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">mantida</text></svg>", "caption": "Removendo a faixa do meio. Com count, as cópias depois dela descem uma posição; com for_each, só sai a cópia chamada app."}
```

Acompanhe a terceira faixa nessa história. Antes, `10.20.3.0/24` era uma sub-rede com um id que a
AWS deu no primeiro apply. Depois, `10.20.3.0/24` continua lá, mas é outra sub-rede, com um id
novo, e a antiga sumiu. Neste laboratório as sub-redes estão vazias, porque o moto não roda
máquinas. Numa conta real, o que estivesse naquela sub-rede, uma máquina ou um banco de dados, foi
colocado lá pelo id, e o plano acabou de destruir a sub-rede debaixo dele.

**O plano é honesto; o pedido de mudança é que não era.** Nada aqui é bug do Terraform. A
ferramenta faz exatamente o que os endereços dizem, e imprime cada linha disso. O perigo é quem lê
o plano: uma mudança descrita como "remover uma sub-rede" cujo resumo diz
`1 to add, 2 to destroy` é a linha onde parar, e a aula 9 transforma isso em hábito.

Vale saber exatamente onde o problema morde e onde não:

- **Acrescentar no fim** da lista só acrescenta uma cópia, porque nenhum índice existente se move.
- **Remover o último elemento** só remove um.
- **Inserir no começo, remover do meio ou ordenar a lista** desloca cada elemento depois da
  mudança. Cada cópia deslocada é substituída se o argumento que mudou força substituição.
- Se o argumento que muda puder ser alterado no lugar, como uma tag, o plano mostra atualizações
  em vez de substituições. Cada recurso assume em silêncio o nome do vizinho, o que é mais difícil
  de perceber e igualmente errado.

Daria para conviver com o `count` prometendo nunca editar a lista a não ser no fim. Essa é uma
regra que alguém vai quebrar numa tarde corrida, e o custo cai sobre o que vive nas sub-redes. A
correção é parar de identificar as cópias pela posição, que é o que o `for_each` faz.

A Ana não aplica esse plano. Ela apaga o `terraform.tfvars`, e a rede fica como estava.
