---
title: O que você abre mão, e quando o Standard é o certo
version: 1
---

É fácil ler o Automatic como o Standard com as partes chatas feitas, uma melhoria pura que não
custa nada além de outro nome de SKU. **Toda funcionalidade preconfigured desta aula é uma decisão
que você não pode mais tomar de outro jeito**, e quase tudo o que o Automatic entrega é a ausência de
uma escolha. Para muitos clusters esse é todo o valor. Para alguns é uma parede, e a parede é mais
fácil de achar antes de o cluster existir do que depois. Esta seção foi lida na documentação da
Microsoft, em 30 de outubro de 2026, e nada nela rodou.

## Os nodes não são seus para entrar

No Standard, os nodes são máquinas virtuais no seu node resource group, e você chega até elas: por
SSH com uma chave, por SSH pelo Entra ID, ou com `kubectl debug node`. No Automatic, três coisas
fecham essa porta:

- os nodes de sistema estão nas assinaturas da Microsoft, não na sua. A documentação lista o que o
  AKS impede ali: mudar qualquer coisa nos namespaces que o AKS administra, `exec`, `attach` ou
  `port-forward` nos pods de sistema dele, rotular um node seu como node de sistema, e rodar um pod
  seu num node de sistema, mesmo com uma toleration ampla;
- o node resource group é trancado. A documentação o chama de totalmente gerenciado: uma deny
  assignment bloqueia mudanças no que o AKS pôs ali, então uma atribuição de papel nele, um disco
  redimensionado à mão ou um link de rede virtual para a zona DNS privada dele são recusados. O SSH
  pelo Entra ID nos nodes não é suportado no Automatic por esse motivo;
- os requisitos para levar um cluster Standard ao Automatic incluem **acesso SSH desligado no pool
  de sistema.**

Então, quando um node se comporta mal, as ferramentas são as do Kubernetes: `kubectl describe node`,
os eventos, os logs que o Container insights coleta. Se o seu jeito de descobrir por que um processo
está lento tem sido entrar na máquina e olhar, esse hábito precisa mudar antes do cluster.

## Menos botões

A aula 11 terminou com um cluster cheio de decisões: o tier, os canais, os pools, o surge. Aqui está
o que um cluster Automatic deixa você mexer e o que não deixa, como a documentação descreve:

| você pode | você não pode |
|---|---|
| definir uma janela de manutenção planejada | escolher um tier que não seja o Standard, então nada de tier Free nem de Premium com suporte de longo prazo |
| excluir namespaces das salvaguardas | passar as salvaguardas para `Warn`, ou desligar o Pod Security Standard baseline |
| escrever NodePools e AKSNodeClasses seus | criar, atualizar ou apagar os managed system node pools, que o `az aks nodepool list` nem mostra |
| usar uma rede virtual sua em vez da gerenciada | parar o cluster à noite, o que o node auto-provisioning não permite |
| escolher Azure Linux ou Ubuntu para os seus nodes | rodar nodes Windows, ou as extensões do Dapr e do Azure Machine Learning |

Duas delas custam dinheiro de um jeito fácil de não perceber. **Um cluster Standard no tier Free não
custa nada pelo control plane**, e um cluster de desenvolvimento parado toda noite só paga pelos nodes
durante o dia. Um cluster Automatic não faz nenhuma das duas coisas: ele está no tier Standard,
cobrado por cluster e por hora, e não pode ser parado. O preço do tier está na página de preços do
AKS e não neste curso, como a aula 11 disse.

O ponto do Dapr importa a este curso em particular. A aula 9 rodou o shop com Dapr nos Container
Apps; a extensão do Dapr para o AKS, que levaria os mesmos sidecars a um cluster, está na lista da
documentação de extensões que um cluster Automatic não suporta.

## Onde ele roda, e o caminho de volta

O Automatic está disponível em uma lista de regiões, e a documentação a dá: 46 nomes, `brazilsouth`
entre eles, então a região do shop está coberta. Uma região fora da lista é um motivo para o
Standard que nenhuma configuração resolve.

Ir de um SKU para o outro não é simétrico. **Do Automatic para o Standard é suportado**: você
acrescenta um pool de sistema seu, porque um cluster Standard precisa rodar os pods de sistema nas
suas máquinas, e muda o SKU para `base`. Nada disso rodou aqui:

```sh
az aks nodepool add --resource-group shop --cluster-name shop-auto --name systempool --mode System --node-count 3
az aks update --resource-group shop --name shop-auto --sku base
```

O outro sentido é mais difícil. O guia de migração descreve levar um cluster Standard ao Automatic
como um preview, atrás de uma feature flag. Ele lista mais de vinte configurações que o cluster
precisa ter antes, entre elas Azure CNI Overlay com Cilium, um NAT gateway gerenciado, Azure Linux e
um disco de SO efêmero no pool de sistema, os dois canais de upgrade como o Automatic os define, o
KEDA e o node resource group lockdown. A lista de limitações da mesma documentação ainda diz que essa
migração não é suportada. Leia as duas juntas como **"planeje criar clusters Automatic do zero, e
saber sair deles se precisar"**, e confira o guia atual no dia em que precisar.

## O modelo de custo

O que você paga no Automatic, pela conta da documentação:

- o tier Standard, por cluster e por hora;
- os nodes que o NAP cria, cobrados como as máquinas virtuais das aulas 1 a 5, na sua assinatura;
- não os managed system nodes, que não são cobrados na sua assinatura;
- os extras de sempre: discos, load balancers, o NAT gateway, os dados de monitoramento que você
  guarda.

A segunda linha é onde o Automatic muda a decisão de lugar em vez de eliminá-la. No Standard, você
escolheu `Standard_D4s_v5` e três deles, e a conta seguia dessa escolha. No Automatic, **a conta
segue os requests dos seus manifestos**, porque é deles que o NAP tira o tamanho das máquinas, e a
consolidação arruma os pods pelos requests, não pelo que eles usam. Um time que deixa o mutador
escrever 2 GiB em todo contêiner, ou que copia um request de um tutorial, paga esse número em cada
réplica. O tamanho do node continua sendo escolhido, só que por quem escreve o Deployment, muitas
vezes sem saber.

## Quando o Standard é o certo

O Automatic é o padrão recomendado pela Microsoft para produção, e a documentação diz isso em quase
toda página que esta aula leu. O Standard continua sendo a resposta certa quando um destes é verdade:

- você precisa de algo que o Automatic não roda: nodes Windows, a extensão do Dapr, uma região fora
  da lista;
- você precisa de um cluster que custe pouco parado: um cluster de estudo ou de desenvolvimento no
  tier Free, ou um parado fora do horário de trabalho;
- você precisa de uma versão por mais tempo: o suporte de longo prazo exige o tier Premium, que o
  Automatic não oferece, e o Automatic segue o canal `stable` queira você ou não;
- as suas cargas ainda não cumprem as salvaguardas: o chart de um fornecedor que puxa `latest`, um
  agente de monitoramento que precisa da rede do host. Excluir o namespace deles é possível, e é
  também o primeiro passo para não ter salvaguarda nenhuma que mereça o nome;
- você ajusta os nodes: um tamanho fixo porque uma licença é contada por núcleo, uma configuração de
  kernel aplicada à mão, o hábito de entrar na máquina.

**E o Automatic é o certo quando nenhum desses é verdade e o time é pequeno.** O shop tem três
desenvolvedores, e nenhum deles quer cuidar de node pools, configurações de surge e canais de
upgrade. As decisões da aula 11 valeram o estudo porque são as que o Automatic toma por você; na
maioria dos dias, o shop fica mais bem servido sem tomá-las.
