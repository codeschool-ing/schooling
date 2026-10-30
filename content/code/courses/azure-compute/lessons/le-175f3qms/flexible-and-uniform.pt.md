---
title: "Flexible e Uniform: dois jeitos de guardar as instâncias"
version: 1
---

Um scale set tem um **modo de orquestração**, e ele é escolhido uma vez: a documentação da Microsoft
diz que o modo é definido quando o scale set é criado e não pode ser mudado depois. A imagem que muita
gente carrega é a de que o Uniform é o scale set de verdade e o Flexible uma variante para casos
raros. Hoje é o contrário. **O Flexible é o modo que a Microsoft recomenda para scale sets novos, e é
o que o Azure CLI cria quando você não diz nada:**

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o "Allowed values: Flexible, Uniform. Default: [A-Za-z]*"
Allowed values: Flexible, Uniform. Default: Flexible
```

O Uniform é o modo mais antigo, e ainda é a resposta certa em alguns lugares com nome.

## Qual é a diferença

A diferença é que tipo de recurso uma instância é.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Dois painéis. À esquerda, Flexible: dentro de um grupo de recursos, o scale set shop-vmss guarda o modelo e a contagem, e três recursos separados do tipo virtualMachines, cada um com disco, interface de rede e tags próprios, são membros dele. À direita, Uniform: o scale set shop-vmss contém três instâncias do tipo virtualMachines numeradas 0, 1 e 2, que são filhas dele e são geridas pela API do scale set.\"><text x=\"184\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Flexible: cada instância é uma VM</text><text x=\"536\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Uniform: as instâncias vivem dentro do conjunto</text><rect x=\"16\" y=\"36\" width=\"336\" height=\"270\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grupo de recursos</text><rect x=\"56\" y=\"66\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"184\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop-vmss</text><text x=\"184\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o modelo e a contagem</text><text x=\"338\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">membros do conjunto</text><path d=\"M184 116 L80 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"32\" y=\"188\" width=\"96\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">virtualMachines</text><text x=\"80\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">disco e NIC próprios</text><text x=\"80\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">e tags próprias</text><path d=\"M184 116 L184 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"136\" y=\"188\" width=\"96\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"184\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">virtualMachines</text><text x=\"184\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">disco e NIC próprios</text><text x=\"184\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">e tags próprias</text><path d=\"M184 116 L288 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"240\" y=\"188\" width=\"96\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"288\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">virtualMachines</text><text x=\"288\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">disco e NIC próprios</text><text x=\"288\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">e tags próprias</text><rect x=\"368\" y=\"36\" width=\"336\" height=\"270\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"380\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grupo de recursos</text><rect x=\"392\" y=\"66\" width=\"288\" height=\"226\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"536\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop-vmss</text><text x=\"536\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o modelo e a contagem</text><text x=\"536\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">filhas do scale set</text><rect x=\"404\" y=\"150\" width=\"84\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">virtualMachines</text><text x=\"446\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\" font-weight=\"600\">0</text><rect x=\"496\" y=\"150\" width=\"84\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"538\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">virtualMachines</text><text x=\"538\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\" font-weight=\"600\">1</text><rect x=\"588\" y=\"150\" width=\"84\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">virtualMachines</text><text x=\"630\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\" font-weight=\"600\">2</text><text x=\"536\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">geridas pela API do scale set</text></svg>", "caption": "As mesmas três instâncias nos dois modos. No modo Flexible elas são máquinas virtuais comuns que pertencem ao conjunto; no modo Uniform só existem dentro dele, endereçadas por um número."}
```

**Num scale set Flexible toda instância é uma máquina virtual comum**, do tipo
`Microsoft.Compute/virtualMachines`. A interface de rede e o disco dela são recursos separados, dela
mesma. O que funciona numa máquina virtual funciona nela: tags, uma atribuição de função só
naquela máquina, o Azure Backup, o Azure Site Recovery, os comandos `az vm` que a lição 1 leu. Uma
máquina virtual que já existe pode ser anexada a um conjunto Flexible. Quando uma instância é
apagada, você escolhe se os discos e a interface de rede vão junto.

**Num scale set Uniform as instâncias pertencem ao scale set**, como
`Microsoft.Compute/virtualMachineScaleSets/virtualMachines`, endereçadas por um número dentro dele e
geridas pela API do próprio scale set. A comparação da Microsoft diz que elas não são compatíveis com
os comandos comuns de máquina virtual, com as tags do Resource Manager, com atribuições de função, com
o Azure Backup nem com o Site Recovery. O conjunto é gerido como um todo. Foi isso que o tornou
simples, e é por isso que ele foi o primeiro tipo de scale set.

A mesma comparação lista duas coisas que só o Uniform suporta: o Service Fabric, e o AKS, que monta
seus node pools sobre scale sets e é onde a lição 11 começa. O Uniform também tem um segundo jeito de
informar a saúde, a sonda do load balancer. O Flexible aceita só a extensão Application Health, que a
seção 05 instala. E duas diferenças importam no primeiro dia. Um conjunto Flexible não tem
acesso de saída padrão à internet, então as instâncias só chegam à internet por algo que você
configura, como um NAT gateway ou as regras de saída do load balancer. E um conjunto Flexible aceita
só uma identidade gerenciada atribuída pelo usuário, o tipo que a lição 8 de `azure-foundations` cria
como recurso próprio.

## Misturar o que o Uniform não misturaria

Um scale set Flexible não precisa ser feito de um tamanho só. O **instance mix** lista até cinco
tamanhos num `skuProfile`, põe `sku.name` em `Mix` e deixa o Azure escolher entre eles a cada aumento,
com uma estratégia de alocação:

- `lowestPrice`, o padrão, que pega o tamanho mais barato que conseguir;
- `capacityOptimized`, para quando conseguir uma máquina importa mais do que o preço dela;
- `Prioritized`, em preview em 2026-10-30, que segue uma ordem que você escreve.

Ele só existe no modo Flexible, e os tamanhos da lista têm de concordar em arquitetura de processador,
interface de armazenamento, disco local e perfil de segurança. Para a loja, listar `Standard_D2s_v5`
e `Standard_D2as_v5`, um tamanho Intel e um AMD do mesmo formato, torna menos provável que um aumento
em São Paulo falhe por falta de um deles. O mesmo modo deixa instâncias Spot e normais dividirem um
conjunto, o que a lição 5 usa, e deixa Linux e Windows dividirem um.

## Domínios de falha e grupos de posicionamento

As outras duas das três linhas da loja tratam de onde, num datacenter, as instâncias ficam.

**`platformFaultDomainCount` é por quantos domínios de falha as instâncias se espalham**, sendo um
domínio de falha um grupo de hardware que divide energia, rede e manutenção. `1` não quer dizer "todas
num só". Quer dizer **espalhamento máximo**: o Azure espalha as instâncias por tantos domínios de
falha quanto conseguir, e a visão da instância mostra um único domínio porque o espalhamento é
implícito. Um número acima de 1 é espalhamento fixo, por exatamente essa quantidade. Para um conjunto
Flexible os valores documentados são `1`, `2` ou `3` quando o conjunto é regional, e só `1` quando ele
usa zonas, como o da loja. O Uniform aceita `1` ou `5` com zonas e de `1` a `5` numa região, onde `5`
é o padrão dele.

**`singlePlacementGroup` vem do Uniform.** Um grupo de posicionamento se comporta como um conjunto de
disponibilidade, com domínios de falha próprios, e um grupo guarda no máximo 100 instâncias; com
`false`, um conjunto Uniform pode abranger vários grupos e chegar a 1.000. O Flexible não o usa do
mesmo jeito. A página de orquestração lista o grupo de posicionamento único entre os parâmetros que o
Flexible não suporta e diz que ele pode ficar nulo para a plataforma escolher. O arquivo da loja
escreve `false`, como faz o próprio template Flexible da Microsoft.

## O que o compilador confere, e o que ele deixa passar

Aqui está o arquivo da loja com três erros digitados numa cópia: o modo encurtado para `Flex`,
espalhamento fixo por três domínios de falha num conjunto que abrange zonas, e uma letra a menos num
nome de propriedade:

```
ana@laptop:~/azure$ sed -e "s/'Flexible'/'Flex'/" -e 's/platformFaultDomainCount: 1/platformFaultDomainCount: 3/' -e 's/singlePlacementGroup/singlePlacmentGroup/' shop-vmss.bicep > flex-wrong.bicep
ana@laptop:~/azure$ diff shop-vmss.bicep flex-wrong.bicep
43,45c43,45
<     orchestrationMode: 'Flexible'
<     platformFaultDomainCount: 1
<     singlePlacementGroup: false
---
>     orchestrationMode: 'Flex'
>     platformFaultDomainCount: 3
>     singlePlacmentGroup: false
ana@laptop:~/azure$ bicep build flex-wrong.bicep
/home/ana/azure/flex-wrong.bicep(45,5) : Warning BCP089: The property "singlePlacmentGroup" is not allowed on objects of type "VirtualMachineScaleSetProperties". Did you mean "singlePlacementGroup"? [https://aka.ms/bicep/core-diagnostics#BCP089]
```

**Um aviso, para três erros.** A propriedade com erro de grafia foi pega, com a grafia certa
oferecida, porque o compilador conhece toda propriedade que um scale set tem. Os outros dois
compilaram sem aviso. O modo é tipado na definição publicada pela Microsoft como uma das duas palavras
*ou qualquer outra string*, então `Flex` é uma string e passa. O número de domínios de falha é tipado
como número, e `3` é um número. A regra de que um conjunto Flexible com zonas
aceita só `1` está na documentação do serviço de computação, não no tipo. Então ela só pode ser
conferida quando o Resource Manager recebe o pedido, e um laptop não tem como descobrir o que ele
responde.

É a regra da lição 1 vista do outro lado. **Nenhum aviso quer dizer que o formato está certo, não que
os valores estão.** Onde uma propriedade tem uma lista curta de significados, compare o valor com a
documentação você mesmo.
