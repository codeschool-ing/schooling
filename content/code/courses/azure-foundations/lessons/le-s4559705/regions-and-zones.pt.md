---
title: Regiões, zonas de disponibilidade e as nuvens a que pertencem
version: 1
---

**Uma região é um lugar no mapa onde a Microsoft roda um conjunto de datacenters próximos o bastante
uns dos outros para agir como um só.** Todo recurso que você cria no Azure é criado numa delas, e o
nome que você dá a ela é o nome programático da região: `brazilsouth`, no estado de São Paulo, é a
região em que este curso trabalha. A vizinha `brazilsoutheast` fica no Rio de Janeiro. Cada região
tem também um nome de exibição, *Brazil South*, que é o que o portal mostra e o que nenhum comando
aceita.

## Qual Azure

Antes das regiões há uma pergunta que as pessoas pulam, porque a resposta quase sempre é a mesma:
**qual Azure?** A Microsoft roda mais de uma cópia dele, cada uma com as suas regiões, o seu
diretório de identidades e os seus endereços, e uma conta numa não existe nas outras. A CLI conhece
todas, e responde isto sem login, a partir da própria instalação:

```
ana@laptop:~/azure$ az cloud list --output table
IsActive    Name               Profile
----------  -----------------  ---------
True        AzureCloud         latest
False       AzureChinaCloud    latest
False       AzureUSGovernment  latest
False       AzureBleuCloud     latest
ana@laptop:~/azure$ az cloud show --name AzureCloud --query "{resourceManager: endpoints.resourceManager, signIn: endpoints.activeDirectory, storage: suffixes.storageEndpoint}"
{
  "resourceManager": "https://management.azure.com/",
  "signIn": "https://login.microsoftonline.com",
  "storage": "core.windows.net"
}
```

`AzureCloud` é o Azure global, o que este curso e quase toda empresa usam. **As outras três são nuvens
soberanas**: `AzureChinaCloud` é operada na China por uma empresa local, como a lei chinesa exige;
`AzureUSGovernment` é reservada a órgãos públicos americanos e aos seus fornecedores;
`AzureBleuCloud` é a francesa, operada por uma empresa que a Orange e a Capgemini criaram para isso.
Cada uma tem o seu endereço de login e o seu Resource Manager, e os endpoints são o jeito de a CLI
distinguir uma da outra. Os três endereços que este curso vai reencontrar são os da global:

| endereço | o que responde ali | lição |
|---|---|---|
| `https://management.azure.com/` | o **Resource Manager**: todo pedido para criar, ler, mudar ou apagar um recurso | 25 |
| `https://login.microsoftonline.com` | o **Microsoft Entra ID**: onde uma identidade prova quem é e recebe um token | 6 |
| `core.windows.net` | o final do endereço de toda storage account, como em `shop.blob.core.windows.net` | 19 |

## Perguntando quais regiões existem

A lista de regiões que uma assinatura pode usar é uma pergunta para o Resource Manager, então neste
laboratório ela recebe a mesma resposta que qualquer outra pergunta para o Resource Manager:

```
ana@laptop:~/azure$ az account list-locations --output table
ERROR: Please run 'az login' to setup account.
rc=0
```

**Este comando não foi respondido aqui**, e com uma conta ele devolve uma entrada por região. O que
cada entrada traz está documentado, e quatro dos campos importam nesta lição: `name`, o nome
programático; `regionType`, que é `Physical` para uma região onde se pode implantar e `Logical` para
um agrupamento como `brazil` ou `southamerica`; `metadata.pairedRegion`, o assunto da próxima seção;
e **`availabilityZoneMappings`**, que diz onde as zonas desta assinatura realmente ficam.

## Zonas de disponibilidade

**Uma zona de disponibilidade é um ou mais datacenters dentro de uma região, com energia, refrigeração
e rede próprias**, perto o bastante das outras zonas para uma ida e volta de um par de milissegundos
e longe o bastante para que um incêndio, uma enchente ou uma subestação com defeito derrube uma zona e
não duas. A `brazilsouth` tem três. A `brazilsoutheast` não tem nenhuma, e é uma região que a
Microsoft só abre para clientes que precisam de uma segunda região dentro do Brasil, por recuperação
ou por lei.

Um recurso encontra as zonas de um de três jeitos, e a documentação de cada recurso diz qual:

- **zonal**: ele mora numa zona que você escolhe, como uma máquina virtual na zona 2. Perder a zona 2
  o perde, então um sistema que precisa sobreviver precisa de um em cada zona;
- **redundante entre zonas**: o próprio Azure o espalha pelas zonas, como uma storage account com
  replicação ZRS ou um balanceador de carga com front end redundante entre zonas. Perder uma zona
  custa capacidade, não o recurso;
- **regional**, ou não zonal: ele mora em algum lugar da região e o Azure decide onde. Ele não diz
  nada sobre zonas, então não promete nada sobre uma delas cair.

## A zona 1 não é o mesmo lugar para todo mundo

**O número de uma zona é um rótulo que a sua assinatura enxerga, não um prédio.** O Azure mapeia as
zonas lógicas 1, 2 e 3 de cada assinatura para as zonas físicas da região de forma independente, para
que todo mundo que escreve `zones: ['1']` não acabe no mesmo datacenter:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-zone-mapping\" aria-label=\"Um exemplo de como duas assinaturas enxergam as zonas de brazilsouth. A região tem três zonas físicas, brazilsouth-az1, az2 e az3. A assinatura shop-prod mapeia a zona lógica 1 para az2, a zona 2 para az3 e a zona 3 para az1; a assinatura shop-staging mapeia a zona 1 para az1, a zona 2 para az2 e a zona 3 para az3. Então a zona 1 de uma e a zona 1 da outra são prédios diferentes. O mapeamento desenhado é inventado; um real se lê em availabilityZoneMappings.\"><defs><marker id=\"l01-zone-mapping-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-zone-mapping-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40.0\" y=\"20.0\" width=\"290.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"54.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura</text><text x=\"316.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><rect x=\"58.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"92.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M92.0 114.0 L92.0 140.0 L344.0 190.0 L344.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-phosphor)\"></path><rect x=\"151.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"185.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M185.0 114.0 L185.0 140.0 L534.0 190.0 L534.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-phosphor)\"></path><rect x=\"244.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"278.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M278.0 114.0 L278.0 140.0 L154.0 190.0 L154.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-phosphor)\"></path><rect x=\"390.0\" y=\"20.0\" width=\"290.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura</text><text x=\"666.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><rect x=\"408.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"442.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"442.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M442.0 114.0 L442.0 140.0 L186.0 190.0 L186.0 213.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-amber)\"></path><rect x=\"501.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"535.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M535.0 114.0 L535.0 140.0 L376.0 190.0 L376.0 213.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-amber)\"></path><rect x=\"594.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona</text><text x=\"628.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M628.0 114.0 L628.0 140.0 L566.0 190.0 L566.0 213.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-amber)\"></path><rect x=\"40.0\" y=\"214.0\" width=\"640.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"56.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">região</text><text x=\"664.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsouth</text><rect x=\"98.0\" y=\"246.0\" width=\"144.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona física</text><text x=\"170.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">brazilsouth-az1</text><rect x=\"288.0\" y=\"246.0\" width=\"144.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona física</text><text x=\"360.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">brazilsouth-az2</text><rect x=\"478.0\" y=\"246.0\" width=\"144.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zona física</text><text x=\"550.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">brazilsouth-az3</text></svg>", "caption": "Um mapeamento inventado, pela forma: a zona 1 é um rótulo que cada assinatura mapeia por conta própria."}
```

Então duas assinaturas que puseram cada uma uma máquina virtual na "zona 1" podem tê-las posto em
prédios diferentes, ou no mesmo. **Dentro de uma assinatura a numeração é estável**, e um desenho que
espalha as máquinas por 1, 2 e 3 está mesmo espalhado. Entre assinaturas ela não quer dizer nada até
você olhar, e `availabilityZoneMappings` é onde se olha: ele liga cada zona lógica a uma física, com
nomes como `brazilsouth-az1`. A assinatura de produção e a de testes da lição 2 são exatamente o caso
em que isso importa, no dia em que alguém quer uma máquina de teste na mesma zona de uma de produção.
