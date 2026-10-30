---
title: Um registry só seu, e os três tiers
version: 1
---

As lições 7, 8 e 9 escreveram `shopregistry.azurecr.io/shop:1.0` em todo arquivo e chamaram o
registry de marcador de lugar. O nome sugere um hub compartilhado com o logotipo do Azure, onde a
imagem da loja fica ao lado da de todo mundo. **Um container registry do Azure é um recurso que você
cria na sua própria assinatura, e o nome dele não pertence a mais ninguém.** `shopregistry` é único
em todo o Azure, então `shopregistry.azurecr.io`, o *login server* do registry, chega a um registry
só. Dentro dele, um repositório guarda as versões de uma imagem e uma tag nomeia uma versão. Ninguém
de fora lê nada disso até que alguém receba um papel nele.

## O endereço

| parte | nesta lição | o que diz |
| --- | --- | --- |
| `shopregistry` | o registry | de 5 a 50 letras minúsculas e dígitos, único no Azure |
| `azurecr.io` | o domínio | o do Azure, o mesmo para todo registry na nuvem pública |
| `shop` | o repositório | letras minúsculas, dígitos, pontos, hífens, sublinhados e barras |
| `1.0` | a tag | uma versão, com o nome que quem fez o push deu |

A região não está no endereço. Um registry é criado numa **região de origem**, `brazilsouth` aqui,
que a documentação da Microsoft diz ser fixada na criação; mudá-la significa criar um registry novo.
Para esta loja a região de origem tem mais uma consequência. Na maior parte das regiões o Azure
também pode guardar os dados de um registry na região par da mesma geografia, mas **em Brazil South
os dados de um registry nunca saem da região**, uma regra que a Microsoft mantém por residência de
dados ali e no Sudeste Asiático. A seção 05 mostra o único jeito de pôr uma cópia em outro lugar de
propósito.

## Três tiers, e uma API

Um registry é criado num de três tiers, que a CLI chama de SKUs. A ajuda da CLI diz quais, e qual é
o padrão das duas configurações em volta:

```
ana@laptop:~/azure$ az acr create --help | awk '/^    --/{p=0} /^    --(sku|admin-enabled|zone-redundancy) /{p=1} p'
    --sku                  [Required] : The SKU of the container registry.  Allowed values: Basic,
                                        Premium, Standard.
    --admin-enabled                   : Indicates whether the admin user is enabled.  Allowed
                                        values: false, true.
    --zone-redundancy       [Preview] : Indicates whether or not zone redundancy should be enabled
                                        for this registry or replication. For more information, such
                                        as supported locations, please visit https://aka.ms/acr/az.
                                        Zone-redundancy cannot be updated. Defaults to 'Disabled'.
                                        Allowed values: Disabled, Enabled.
        WARNING: Argument '--zone-redundancy' is in preview and under development. Reference and
        support levels: https://aka.ms/CLI_refstatus

Customer managed key Arguments
```

**Basic, Standard e Premium falam a mesma API**, a que a seção 03 usa: o mesmo push, o mesmo pull,
os mesmos manifests. A documentação da Microsoft diz isso com todas as letras, e é por isso que um
pipeline escrito contra um registry Basic funciona sem mudança contra um Premium. O que o tier muda
é quanto tráfego o registry aguenta e quais recursos ele tem. Os limites são publicados por minuto,
e duas linhas dessa tabela, lidas em 30 de outubro de 2026, mostram o formato:

| pedidos por minuto, por registry | Basic e Standard | Premium |
| --- | --- | --- |
| leituras: pulls de manifests e camadas | 10.000 | 20.000 |
| escritas: pushes de manifests e camadas | 2.000 | 4.000 |

Um registry acima de um limite responde `429 Too Many Requests` com um cabeçalho `Retry-After`, e a
documentação diz que os números são aproximados e não têm SLA. Cinquenta nós de um cluster baixando
uma imagem de dez camadas no mesmo instante fazem bem mais de quinhentos pedidos, então o teto está
mais perto do que parece, e todo tier tem a mesma resposta para ele: baixar menos vezes, e repetir.

Os recursos são a diferença maior. Estes são os que a documentação liga a um tier:

| recurso | tiers | nesta lição |
| --- | --- | --- |
| geo-replicação, um registry em várias regiões | Premium | seção 05 |
| private endpoints, até 200 por registry | Premium | |
| criptografia com uma chave sua no Key Vault | Premium | |
| política de retenção para manifests sem tag (preview) | Premium | seção 04 |
| pools de agentes dedicados para tasks (preview) | Premium | seção 04 |
| um connected registry, sincronizado com um local seu | Premium | |
| pull anônimo, para um registry que qualquer um lê | Standard e Premium | |
| artifact cache, uma cópia local de uma imagem do Docker Hub ou de outro registry | os três | seção 05 |
| redundância de zona entre as zonas de disponibilidade da região | os três, ligada por padrão | seção 05 |

O Docker Content Trust, o jeito mais antigo de assinar imagens, estava nessa lista como recurso do
Premium. **Desde 31 de maio de 2026 ele não pode ser ligado num registry que ainda não o usava**, e
a Microsoft vai removê-lo em 31 de março de 2028, em favor das assinaturas do Notary Project. Trocar
de tier é um comando, `az acr update --name shopregistry --sku Premium`, sem indisponibilidade;
descer do Premium exige apagar antes os recursos que só ele tem, como as réplicas.

**Leia a linha de redundância de zona da ajuda contra a última linha daquela tabela.** A CLI diz
que a configuração tem padrão `Disabled` e não pode ser mudada depois. A documentação, numa página
de março de 2026, diz que a redundância de zona agora vale para todo registry numa região com zonas
de disponibilidade, em todo tier, diga a propriedade o que disser. E acrescenta que o portal, a CLI
e a API podem continuar mostrando `Disabled` para um registry que na verdade é redundante entre
zonas. O
texto de ajuda é gerado das mesmas definições que os pedidos, então descreve a API com fidelidade, e
a propriedade da API é a parte que ficou desatualizada. A lição 6 explicou o que as zonas compram;
aqui elas vêm de graça.

Quanto armazenamento cada tier inclui, e quanto custa cada gigabyte a mais, está na página de preços
do Azure, que este curso não cita. A lição 1 mostra como lê-la.

## Quem pode fazer push e pull

**Uma pessoa entra num registry com a própria identidade do Microsoft Entra**, pela CLI. Estes dois
comandos não foram executados neste curso: o primeiro precisa de uma conta, e sem ela o segundo
segue adiante e chama o login server que nomeia, que é de outra pessoa.

```sh
az login
az acr login --name shopregistry
```

O `az acr login` troca o token que o `az login` obteve por um token do registry e o entrega ao
Docker, então `docker push` e `docker pull` funcionam depois sem senha digitada. **O token do
registry dura três horas**, e é por isso que um pipeline entra de novo a cada execução em vez de
guardar um segredo. Onde não roda nenhum daemon do Docker, `--expose-token` imprime o token, e o
`docker login` o recebe como senha com o nome de usuário `00000000-0000-0000-0000-000000000000`.

Todo registry também tem um **usuário admin**: uma conta com duas senhas, push e pull em tudo, e
nenhum jeito de saber quem a usou. Ele vem desligado quando o registry é criado, e o conselho da
documentação é deixá-lo assim. O Bicep da seção 05 diz `adminUserEnabled: false` mesmo assim, para
a decisão ficar escrita.

Os serviços deste curso fazem pull com uma **identidade gerenciada**, a identidade que um recurso do
Azure carrega, da lição 8 do `azure-foundations`, com o papel **AcrPull** no registry, da lição 9 do
mesmo curso. Para o AKS, assunto da lição 11, uma flag no cluster dá esse papel aos nós. Para o
Container Apps, assunto da lição 8, o app recebe a ordem de usar a própria identidade atribuída pelo
sistema neste servidor. Nenhum dos dois foi executado aqui:

```sh
az aks update --resource-group shop --name shop-aks --attach-acr shopregistry
az containerapp registry set --resource-group shop --name shop --server shopregistry.azurecr.io --identity system
```

O primeiro atribui AcrPull à identidade que os nós do cluster usam, e faz isso com as permissões de
quem o executa, então essa pessoa precisa do direito de atribuir papéis. O segundo liga a identidade
do app e a aponta para o registry, e a CLI atribui o papel. **Não existe senha em lugar nenhum desses
arranjos**, e esse é todo o motivo deles.

Um arranjo mais novo muda o nome do papel. Um registry pode ser passado para um modo que a Microsoft
chama de *RBAC Registry + ABAC Repository Permissions*, em que uma atribuição de papel pode ficar
limitada a certos repositórios. Nesse modo o papel de pull é o **Container Registry Repository
Reader** em vez de AcrPull, e o `--attach-acr` não é suportado, então a atribuição é feita à mão. Um
registry criado do jeito comum continua com AcrPull.
