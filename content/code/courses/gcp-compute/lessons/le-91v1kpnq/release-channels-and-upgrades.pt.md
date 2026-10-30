---
title: Canais de lançamento e como os nós são atualizados
version: 1
---

A crença comum sobre um cluster gerenciado é que atualizações são problema do Google. Metade disso
é verdade. **O Google atualiza o plano de controle no calendário dele; os nós são atualizados no
mesmo calendário, mas dentro do seu cluster, com os seus pods em cima, e como isso acontece é
definido por você.** Uma equipe que nunca olha a segunda metade descobre isso na manhã em que um nó
é drenado debaixo de um serviço com uma réplica só.

## Canais de lançamento

Um cluster num canal de lançamento é atualizado sozinho, plano de controle e nós, para versões que
o Google promoveu naquele canal. O provider nomeia os canais na recusa que você recebe ao escrever
um que não existe:

```
ana@laptop:~/gcp/gke$ sed -i 's/"REGULAR"/"WEEKLY"/' main.tf
ana@laptop:~/gcp/gke$ terraform validate -no-color

Error: expected release_channel.0.channel to be one of ["UNSPECIFIED" "RAPID" "REGULAR" "STABLE" "EXTENDED"], got WEEKLY

  with google_container_cluster.shop,
  on main.tf line 22, in resource "google_container_cluster" "shop":
  22:     channel = "WEEKLY"
```

- **`RAPID`** recebe versões novas do Kubernetes primeiro, semanas depois do lançamento no projeto
  original. É para experimentar o que vem por aí, não para produção.
- **`REGULAR`** é o padrão e a escolha comum: as versões chegam depois de passar um tempo no Rapid.
- **`STABLE`** espera mais um pouco, para equipes que preferem versões comprovadas a recursos novos.
- **`EXTENDED`** deixa um cluster numa versão menor além do suporte padrão. A página de preços do
  Google diz que uma taxa extra de gerenciamento vale enquanto a versão está nesse período
  estendido, então ele compra tempo por um preço.

`UNSPECIFIED` quer dizer sem canal, com versões controladas à mão. Ainda é aceito e é o caminho que
o Google desaconselha: um cluster que ninguém atualiza acaba chegando ao fim do suporte, e aí o GKE
o atualiza de qualquer jeito, num momento que ninguém escolheu.

A ordem é sempre a mesma: **primeiro o plano de controle, depois os node pools**, porque o API
server aceita nós algumas versões menores atrás dele e nunca à frente.

## O que acontece com um nó

Atualizar um nó quer dizer substituí-lo. O GKE cria um nó na versão nova e então **isola e drena**
um antigo: nenhum pod novo é agendado ali, e os pods que rodam ali são despejados e reagendados em
outro lugar, respeitando o PodDisruptionBudget de cada carga. Quantos nós são substituídos de uma
vez é o `upgrade_settings` do pool, e a estratégia é um dos valores que o provider conhece:

```
ana@laptop:~/gcp/gke$ sed -i 's/"SURGE"/"ROLLING"/' pool.tf
ana@laptop:~/gcp/gke$ terraform validate -no-color

Error: expected upgrade_settings.0.strategy to be one of ["SURGE" "BLUE_GREEN" "SHORT_LIVED"], got ROLLING

  with google_container_node_pool.general,
  on pool.tf line 19, in resource "google_container_node_pool" "general":
  19:     strategy        = "ROLLING"
```

**`SURGE`**, o padrão, anda em passos pequenos:

- `max_surge` é quantos nós extras o GKE pode acrescentar durante a atualização. Com `1`, o pool
  tem por um momento um nó a mais que o normal, e você paga por ele enquanto existe;
- `max_unavailable` é quantos nós podem faltar ao mesmo tempo. Com `0`, a capacidade nunca cai
  abaixo do normal, ao custo de uma atualização mais lenta.

O `1` e `0` da loja é a configuração cautelosa: um nó por vez, capacidade nunca abaixo do normal.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Uma atualização por surge de um pool de três nós com max_surge 1 e max_unavailable 0, em cinco linhas. No início, três nós antigos. Depois um quarto nó, na versão nova, é acrescentado. Depois um nó antigo é isolado e drenado enquanto os outros três continuam atendendo. Os mesmos dois passos se repetem, e no fim o pool tem três nós novos. O pool nunca tem menos de três nós prontos nem mais de quatro.\"><defs><marker id=\"l13s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">início</text><rect x=\"200\" y=\"20\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"324\" y=\"20\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"448\" y=\"20\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><text x=\"24\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">acrescenta um nó novo</text><rect x=\"200\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"324\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"448\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"572\" y=\"76\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text><text x=\"24\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">drena um nó antigo</text><rect x=\"200\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"254\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">drenando</text><rect x=\"324\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"448\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"572\" y=\"132\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text><text x=\"24\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo, mais duas vezes</text><rect x=\"200\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text><rect x=\"324\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"448\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão antiga</text><rect x=\"572\" y=\"188\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text><text x=\"24\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fim</text><rect x=\"200\" y=\"244\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text><rect x=\"324\" y=\"244\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"378\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text><rect x=\"448\" y=\"244\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"502\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">versão nova</text></svg>", "caption": "Com max_surge 1 e max_unavailable 0 o pool troca velocidade por capacidade: um nó a mais por vez, pago enquanto existe, e nunca menos nós prontos que o normal."}
```

O provider também conhece um terceiro, `SHORT_LIVED`, que é mais novo que esta lição e fica fora
dela.

**`BLUE_GREEN`** cria um segundo conjunto completo de nós na versão nova, move os pods em lotes e
mantém o conjunto antigo por um período de observação em que você pode voltar atrás. É mais seguro
e dobra as máquinas do pool durante a atualização, então combina com um pool pequeno rodando algo
que não pode se comportar mal, e não com um grande e de orçamento apertado.

## O que faz uma atualização dar errado

A drenagem é o momento que dói, e quase nunca por culpa do GKE. Um Deployment com uma réplica fica
fora do ar enquanto o pod é reagendado. Um pod sem PodDisruptionBudget pode ser despejado junto com
os irmãos. Um pod que ignora o SIGTERM é morto quando acaba o tempo de cortesia, no meio de uma
requisição. Nada disso aparece nos meses entre uma atualização e outra, e por isso a configuração
que mais importa é a da próxima seção: quando elas podem acontecer.

Nada disso foi executado aqui. O que o laboratório verificou é que o canal e a estratégia que você
escreveu são aceitos pelo provider; a atualização em si é descrita a partir da documentação do
Google.
