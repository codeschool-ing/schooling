---
title: EKS, AKS e GKE, pelo que cobram e pelo que diferem
version: 1
---

::: track cloud-engineering
O curso `cloud`, que vem antes deste na sua trilha, comparou os três provedores como um todo na lição
3 e a cobrança deles na lição 10. O que segue é só a parte do catálogo deles que roda Kubernetes.
:::

::: track devops devsecops
O curso `cloud` vem depois deste na sua trilha, e a lição 3 dele compara os três provedores como um
todo. O que segue é só a parte do catálogo deles que roda Kubernetes.
:::

::: track *
O curso `cloud` compara os três provedores como um todo, na lição 3. O que segue é só a parte do
catálogo deles que roda Kubernetes.
:::

**No Kubernetes em si os três concordam, e precisam concordar.** Cada um é certificado pelo programa
de conformidade da CNCF, que roda o mesmo conjunto de testes contra toda distribuição certificada,
então um Deployment, um Service ou um ConfigMap se comportam igual nos três e no cluster do laptop.
Onde eles diferem é na taxa, em quanto tempo uma versão tem suporte e em como o cluster se liga ao
resto do provedor.

## A taxa do plano de controle, lida das listas de preços

A Amazon publica a lista de preços inteira em arquivos que qualquer pessoa pode baixar. Isto lê uma
versão do arquivo do EKS, fixada para que os números continuem sendo os que ela diz:

```
ana@laptop:~/shop$ python3 eks-prices.py | sort
price list published 2026-09-28T19:42:55Z
sa-east-1  cluster, standard support  USD 0.10 per hour
sa-east-1  extended support, added    USD 0.50 per hour
us-east-1  cluster, standard support  USD 0.10 per hour
us-east-1  extended support, added    USD 0.50 per hour
```

**Um cluster EKS custa 0,10 dólar por hora enquanto a versão dele está no suporte padrão, nas duas
regiões**, e 0,50 a mais quando essa versão passa para o suporte estendido. O Google não publica um
arquivo assim, então a leitura seguinte é a página de preços dele como estava no dia em que esta
lição foi gravada:

```
ana@laptop:~/shop$ python3 gke-prices.py
- that's financially backed providing the following availability: 99.95% for the control plane of Autopilot clusters and regional Standard clusters.
- 99.5% for the control plane of zonal Standard clusters.
- Free tier The GKE free tier provides $74.40 in monthly credits per billing account, which is equivalent to one free Autopilot or zonal Standard cluster per month.
- Cluster management fee A flat cluster management fee of $0.10 per cluster per hour (charged in 1 second increments)
- The GKE extended period cluster management fee is in addition to the GKE cluster management fee at $0.10 per cluster per hour, for a total of $0.60 per cluster per hour.
```

**O GKE cobra os mesmos 0,10 dólar por hora por cluster**, e o nível gratuito dele, 74,40 dólares por
mês, é exatamente essa taxa num mês de 744 horas: um cluster zonal ou Autopilot não custa nada como
plano de controle. O suporte estendido também acrescenta 0,50, chegando a 0,60 por hora. A página
diz ainda o nível de serviço: 99,95% para o plano de controle de um cluster regional, 99,5% para um
zonal.

*A lista de preços da Microsoft para o AKS não pôde ser lida da máquina em que isto foi gravado*,
cuja rede recusou o endereço, então nenhum valor do AKS aparece aqui. O arranjo dele é publicado em
níveis: um gratuito, sem taxa por cluster e sem compromisso de disponibilidade com respaldo
financeiro, um padrão, com taxa por hora de cluster e esse compromisso, e um premium, que acrescenta
suporte longo para versões antigas. Leia os números atuais na página da própria Azure antes de
comparar.

## A taxa é a parte pequena

Um plano de controle a 0,10 dólar por hora dá 74,40 dólares num mês de 31 dias. **As máquinas que
rodam os seus pods costumam custar várias vezes isso**, e são cobradas pelo preço normal de máquina
virtual do provedor, seja qual for o orquestrador que rode nelas. Então a taxa raramente decide entre
os três. O que decide:

| | EKS | AKS | GKE |
|---|---|---|---|
| o endereço de um pod vem | da própria VPC, por padrão | de uma rede sobreposta, ou da rede virtual | da VPC, por faixas de alias |
| um pod recebe permissões na nuvem por | EKS Pod Identity ou IAM roles for service accounts | Microsoft Entra Workload ID | Workload Identity Federation |
| as versões avançam | numa versão que você escolhe, atualizada quando você pede | numa versão que você escolhe, ou em canais automáticos | por canais: Rapid, Regular, Stable, Extended |
| nós rodados pelo provedor | EKS Auto Mode, ou Fargate | node auto-provisioning | Autopilot |

**A maioria das equipes escolhe o provedor que já usa**, porque as contas, as redes, a identidade e a
cobrança já estão lá, e um cluster em outra nuvem teria de alcançar tudo isso pela internet. A
tabela acima é o que você encontra no segundo dia, não um motivo para mudar.
