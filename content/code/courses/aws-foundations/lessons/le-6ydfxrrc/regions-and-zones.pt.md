---
title: Regiões, zonas, e os dois nomes de uma zona
version: 1
---

**Uma região é um lugar no mapa; uma Availability Zone é uma falha separada dentro dela.** O curso
`cloud` desenhou essa imagem para todo provedor. Esta seção é a grafia da AWS para ela, e os dois
detalhes que a AWS acrescenta e que pegam as pessoas desprevenidas.

A imagem errada comum é que uma Availability Zone é um datacenter. **Uma AZ é um ou mais
datacenters com energia, refrigeração e rede próprias**, longe o bastante das outras zonas da região
para que uma enchente ou um incêndio leve uma delas e não a seguinte, e perto o bastante para que
uma ida e volta entre elas fique em torno de um ou dois milissegundos. Uma região é um grupo delas,
pelo menos três em toda região que a AWS constrói hoje. O ponto do arranjo é que **você escolhe as
zonas, a AWS escolhe os prédios**, e uma aplicação espalhada por duas ou três zonas sobrevive à perda
de uma.

## Perguntando ao moto, do jeito que se pergunta à AWS

Com o moto rodando no primeiro terminal e o `env.sh` lido no segundo, a linha de comando pergunta
por regiões e zonas exatamente como perguntaria à AWS:

```
ana@laptop:~/aws$ aws ec2 describe-regions --query "length(Regions)"
38
ana@laptop:~/aws$ aws ec2 describe-regions --query "Regions[?starts_with(RegionName, \`sa-\`) || starts_with(RegionName, \`us-east\`)].[RegionName,Endpoint]" --output text
sa-east-1	ec2.sa-east-1.amazonaws.com
us-east-1	ec2.us-east-1.amazonaws.com
us-east-2	ec2.us-east-2.amazonaws.com
ana@laptop:~/aws$ aws ec2 describe-availability-zones --query "AvailabilityZones[].[ZoneName,ZoneId,ZoneType,State]" --output text
sa-east-1a	sae1-az1	availability-zone	available
sa-east-1b	sae1-az2	availability-zone	available
sa-east-1c	sae1-az3	availability-zone	available
ana@laptop:~/aws$ aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[].[ZoneName,ZoneId]" --output text
us-east-1a	use1-az6
us-east-1b	use1-az1
us-east-1c	use1-az2
us-east-1d	use1-az4
us-east-1e	use1-az3
us-east-1f	use1-az5
```

A opção `--query` é um filtro que a linha de comando aplica à resposta antes de imprimi-la, escrito
numa linguagem pequena chamada JMESPath. `length(Regions)` conta; o segundo comando guarda só as
regiões cujo nome começa com `sa-` ou `us-east`; `--output text` imprime uma linha por item em vez
de JSON. A lição 25 fala mais das duas coisas. **A contagem é do moto**: a lista que ele carrega é
parecida com a da AWS e não tem garantia de ser a mesma num dia qualquer, então confie na
documentação da AWS, e não num número de um curso, quando a lista exata importar.

`sa-east-1` tem três zonas, e cada uma tem **dois nomes**.

## O nome da zona é seu; o id da zona é de todo mundo

`sa-east-1a` é um **nome de zona**, e a AWS pode apontá-lo para uma zona física diferente na sua
conta e na de outra pessoa. Ela fez isso de propósito nas regiões mais antigas, para que todo mundo
que escolhesse a primeira zona da lista não caísse no mesmo prédio. **`sae1-az1` é um id de zona**,
e ele nomeia a mesma zona física em toda conta.

Isso importa no momento em que duas contas precisam se encontrar. A lição 2 divide a plataforma em
várias contas, e a lição 19 liga serviços entre elas; se a conta da loja põe o banco de dados em
`sa-east-1a` e a conta de pagamentos põe o cliente em `sa-east-1a` também, os dois ainda podem estar
em prédios diferentes, pagando por cada byte entre eles como a próxima seção mostra. **Coordene pelo
id da zona**, e traduza para um nome de zona dentro de cada conta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l01-zone-names\" aria-label=\"Nomes de zona contra ids de zona em us-east-1. No meio, três zonas físicas, rotuladas com seus ids use1-az1, use1-az2 e use1-az6. À esquerda, a conta da transcrição: us-east-1a aponta para use1-az6, us-east-1b para use1-az1 e us-east-1c para use1-az2. À direita, outra conta, desenhada como ilustração: seu us-east-1a aponta para use1-az2, o b para use1-az6 e o c para use1-az1. O mesmo nome cai em zonas diferentes; o id não muda.\"><defs><marker id=\"l01-zone-names-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-zone-names-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">esta conta</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">as zonas físicas</text><text x=\"610.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">outra conta</text><text x=\"610.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">(uma ilustração)</text><rect x=\"290.0\" y=\"66.0\" width=\"140.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">use1-az1</text><rect x=\"290.0\" y=\"136.0\" width=\"140.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">use1-az2</text><rect x=\"290.0\" y=\"206.0\" width=\"140.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">use1-az6</text><rect x=\"40.0\" y=\"72.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1a</text><path d=\"M182.0 90.0 L286.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"72.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1a</text><path d=\"M538.0 90.0 L434.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-amber)\"></path><rect x=\"40.0\" y=\"142.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1b</text><path d=\"M182.0 160.0 L286.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"142.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1b</text><path d=\"M538.0 160.0 L434.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-amber)\"></path><rect x=\"40.0\" y=\"212.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1c</text><path d=\"M182.0 230.0 L286.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"212.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1c</text><path d=\"M538.0 230.0 L434.0 90.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-names-af-ah-amber)\"></path><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">coordene duas contas pelo id do meio</text></svg>", "caption": "Um nome de zona é o rótulo que a sua conta dá a uma zona. Um id de zona é a zona."}
```

A transcrição mostra os dois comportamentos. Em `sa-east-1` o moto liga os nomes aos ids em ordem;
em `us-east-1` ele faz o que a AWS faz numa região mais antiga, e **`us-east-1a` é `use1-az6`**.
Outra conta pode receber outro mapeamento, e `describe-availability-zones` é como descobrir: é o
único comando que imprime os dois nomes lado a lado.

## Local Zones, e as outras bordas de uma região

**Uma Local Zone estende uma região até uma cidade onde a AWS não tem região**: um conjunto pequeno
de serviços, em geral computação, armazenamento em bloco e uma fatia da rede, posto perto de pessoas
que precisam de alguns milissegundos a menos do que a região consegue dar. Edição de vídeo, jogos e
operações financeiras são os motivos de sempre. Uma Local Zone pertence a uma região-mãe, tem um nome
construído a partir dela (`us-west-2-lax-1a` é Los Angeles, ligada ao Oregon), e precisa de adesão
antes de aparecer.

O moto não carrega nenhuma, e é isto que ele responde quando perguntado por todas as zonas de
`us-west-2`, uma região que tem várias Local Zones na AWS, a de Los Angeles entre elas:

```
ana@laptop:~/aws$ aws ec2 describe-availability-zones --region us-west-2 --all-availability-zones --query "AvailabilityZones[].[ZoneName,ZoneType]" --output text
us-west-2a	availability-zone
us-west-2b	availability-zone
us-west-2c	availability-zone
us-west-2d	availability-zone
```

**Na AWS, o mesmo comando também lista as Local Zones, com `local-zone` na segunda coluna e
`opted-in` ou `not-opted-in` em `OptInStatus`. Essa parte não foi rodada aqui**, já que exige uma
conta; a forma da resposta é a que a AWS documenta.

Mais duas bordas, que este curso nomeia e não usa: as **Wavelength Zones** põem equipamento da AWS
dentro da rede de uma operadora de celular, e os **Outposts** são racks da AWS instalados no seu
próprio datacenter. Os dois respondem a uma região-mãe, como uma Local Zone.

## Qual região, para este curso e para você

Toda lição trabalha em **`sa-east-1`**, a região que o `env.sh` nomeia. Para uma empresa brasileira
ela costuma ser a óbvia: os dados ficam no país, o que a LGPD não exige mas clientes e contratos
muitas vezes exigem, e um aluno em São Paulo fica a poucos milissegundos dela em vez de cem da
Virgínia. Ela também é uma das regiões mais caras que a AWS tem, o que a próxima seção mede. O curso
`cloud`, lição 9, tem o argumento completo para escolher uma região; a linha que importa aqui é que
**a escolha decide o preço de tudo o que a atravessa**.
