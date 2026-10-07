---
title: O recurso que não é de ninguém
version: 2
---

Toda revisão deste curso olha para uma configuração: um diff, um plano, um preço. **Um recurso que não
está em configuração nenhuma não está em revisão nenhuma**, e custa exatamente o que custa um que tem
dono. Isso é um órfão: algo rodando na conta que nenhum arquivo de state registra e que nenhuma tag
atribui a alguém. Nunca é a linha grande da fatura. É a pequena que ninguém reconhece, todo mês.

Eles vêm de poucos lugares, e cada um já apareceu antes:

- **feitos à mão**, para um teste ou uma correção urgente, por alguém que pretendia apagá-los;
- **soltos pelo Terraform**: um bloco `removed` com `destroy = false` (aula 6), um `terraform state rm`,
  ou um arquivo de state que se perdeu (aula 7). O recurso continua rodando; nada o acompanha;
- **um ambiente que ninguém destruiu**, comum o bastante para ganhar a próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Uma caixa grande, a conta da AWS, contém duas caixas que se sobrepõem: o que um arquivo de state registra e o que tem a tag Owner. Na sobreposição estão os servidores web e o NAT gateway. Só num state estão os discos dos servidores web, criados antes das tags. Só com tag está o ambiente do pr-17 depois que o state dele se perde. Fora das duas, embaixo, estão o volume e o endereço do Bruno: os órfãos.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"285\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a conta da AWS</text><rect x=\"50\" y=\"60\" width=\"340\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"290\" y=\"80\" width=\"380\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"62.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">num arquivo de state</text><text x=\"658.0\" y=\"98.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">tem a tag Owner</text><text x=\"340.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">servidores web</text><text x=\"340.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">NAT gateway</text><text x=\"170.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os discos dos servidores</text><text x=\"170.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(as tags vieram depois)</text><text x=\"510.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pr-17, state perdido</text><rect x=\"40\" y=\"245\" width=\"240\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">órfãos</text><text x=\"160.0\" y=\"277.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">volume e endereço do Bruno</text><text x=\"460.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">em state nenhum, sem tag: em revisão nenhuma</text></svg>", "caption": "O que uma revisão enxerga é o que está numa configuração. O órfão é o canto fora das duas caixas.", "same": ["NAT gateway"]}
```

## Uma busca que não enxerga o que procura

Um colega, o Bruno, precisou de espaço para uma exportação avulsa na semana passada. Da própria máquina
ele criou um volume de 100 GB e reservou um endereço público, e aí a exportação terminou. Nenhum dos
dois passou pelo Terraform, então nenhum tem tag. Estes foram os dois comandos do Bruno; rode-os para
ter os mesmos dois no seu moto:

```sh
aws ec2 create-volume --size 100 --availability-zone sa-east-1a --volume-type gp3
aws ec2 allocate-address --domain vpc
```

A ferramenta óbvia é a que a AWS fez para achar recursos por tag, a Resource Groups Tagging API. Peça
volumes a ela:

```
ana@laptop:~/shop$ aws resourcegroupstaggingapi get-resources --resource-type-filters ec2:volume --query "ResourceTagMappingList[].ResourceARN"
[]
```

**Nada, e é assim que ela foi feita.** A tagging API responde a partir das tags: a AWS documenta que ela
devolve recursos que têm ou já tiveram tag, então um recurso que nunca teve tag não existe no mundo
dela. Uma busca por tag acha tudo, menos a coisa que você está caçando. A pergunta tem de ir a cada
serviço, pedindo o que não tem tags:

```
ana@laptop:~/shop$ aws ec2 describe-volumes --output json | jq -r '.Volumes[] | select((.Tags // []) | length == 0) | [.VolumeId, .State, .Size, .Size * 0.1520] | @tsv'
vol-ec23023a06e407706	in-use	20	3.04
vol-30a55504c45f96cfd	in-use	20	3.04
vol-f86f3ff8e4622769a	available	100	15.2
```

Três volumes, e só um é órfão. Os dois `in-use` de 20 GB são os discos dos servidores web da seção
anterior: sem tags porque as padrão chegaram depois deles, mas presos a instâncias que o Terraform
acompanha. O terceiro está `available`, o que quer dizer preso a nada. **Um volume available é um disco
que nenhuma máquina lê, cobrado por gigabyte**: a última coluna é o tamanho vezes os 0.1520 por
GB-mês da planilha, 15.2 USD por mês.

Endereços se acham do mesmo jeito, pedindo os que não estão presos a nada:

```
ana@laptop:~/shop$ aws ec2 describe-addresses --output json | jq -r '.Addresses[] | select((.AssociationId // "") == "") | [.AllocationId, .PublicIp, ((.Tags // []) | length)] | @tsv'
eipalloc-f0930f8c1f0ff56f9	127.28.101.243	0
```

É o do Bruno, sem tags, e custa os mesmos 3.65 por mês que o `aws_eip.nat` no plano com preço, por um
endereço que ninguém usa.

## O que fazer com um

Ache o dono antes de apagar qualquer coisa. O CloudTrail, que registra as chamadas à API da AWS, mostra
quem chamou `CreateVolume`, e a resposta costuma ser uma pessoa que sabe se os dados importam. Aí uma
de duas coisas acontece. **Ou ele é adotado**, escrito numa configuração e importado (aula 8), e daí em
diante tem tag, passa por revisão e tem preço como todo o resto. **Ou ele é apagado**, depois de um
snapshot se for um disco de que alguém possa sentir falta.

A busca acima são dois comandos. Rodada com agenda, com a saída enviada a quem é dono da conta, ela
transforma órfãos de algo achado numa fatura em uma lista curta toda semana.
