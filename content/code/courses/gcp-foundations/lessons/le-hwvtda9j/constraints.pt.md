---
title: Uma restrição, e a política que a define
version: 1
---

**O IAM diz quem pode fazer algo. Uma política da organização diz o que pode ser feito, por quem quer
que seja.** Owner de um projeto é o papel mais amplo que existe, e mesmo assim um Owner não consegue
criar uma chave de conta de serviço num projeto onde uma política proíbe chaves, nem um disco em Iowa
onde uma política só permite São Paulo. É essa a ideia: uma barreira que um papel poderoso pudesse pular
não seria barreira.

O vocabulário tem duas palavras, e é fácil trocá-las:

- uma **restrição** (constraint) é uma regra que o Google define, com um nome, como
  `iam.disableServiceAccountKeyCreation` ou `gcp.resourceLocations`. Sozinha, não faz nada;
- uma **política da organização** é uma restrição com um valor, anexada a um nó da árvore: a
  organização, uma pasta ou um projeto.

## Três tipos de restrição

| tipo | o que guarda | exemplo |
|---|---|---|
| **booleana** | ligada ou desligada | `compute.requireOsLogin`: toda máquina usa o IAM para SSH, ou não |
| **lista** | valores permitidos ou negados | `gcp.resourceLocations`: os lugares onde recursos podem ser criados |
| **personalizada** | uma condição escrita em CEL sobre os campos de um recurso, nos serviços que aceitam | "uma regra de firewall não pode liberar `0.0.0.0/0` na porta 22" |

O Google vem trocando muitas das restrições booleanas e de lista mais antigas por **restrições
gerenciadas**, cujos nomes levam a palavra `managed`, como `iam.managed.disableServiceAccountKeyCreation`.
Elas fazem o mesmo trabalho com duas melhorias: podem ser testadas primeiro em **dry run**, e seguem as
mesmas regras das restrições personalizadas. Um ambiente novo deveria preferir o nome gerenciado onde
houver um; o antigo continua funcionando.

Uma restrição de lista pode nomear um **grupo de valores** em vez de listar valores um a um.
`in:southamerica-locations` quer dizer toda região e zona da América do Sul, as de hoje e as de amanhã,
que é o que uma regra de residência de dados costuma querer dizer.

## O que uma política da organização não faz

Duas coisas surpreendem na primeira vez, e as duas são de propósito:

- **Ela não é retroativa.** Uma política é conferida quando um recurso é criado ou mudado. Uma chave
  que existia antes de as chaves serem proibidas continua existindo, e um disco em Iowa criado antes da
  regra de local continua rodando lá. Ligar uma política é o momento de procurar o que ela teria
  recusado, e o inventário da lição 25 é o jeito.
- **Ela não concede nada.** Permitir `southamerica-east1` numa lista não dá papel a ninguém lá. Ela
  tira possibilidades, e o IAM decide quem usa as que sobram.

O papel para definir políticas é o **Organization Policy Administrator**, `roles/orgpolicy.policyAdmin`,
na organização. Ele é separado do Owner de propósito: quem opera projetos não deveria ser quem decide o
que qualquer projeto pode fazer.

## Seguro por padrão

Uma organização criada a partir de **3 de maio de 2024** começa com um punhado de políticas já
aplicadas, que o Google chama de *secure by default*. Entre elas: nenhuma chave de conta de serviço
pode ser criada nem enviada, contas de serviço padrão não ganham o papel Editor automaticamente,
concessões do IAM ficam limitadas a identidades do próprio domínio da organização, e buckets usam acesso
uniforme. Uma organização mais antiga não tem nenhuma delas até alguém defini-las, o que torna um hábito
valioso: **confira quais delas um ambiente tem antes de supor que tem**.

Nada nesta seção foi rodado: nenhum emulador responde à API de Organization Policy. A seção depois da
próxima escreve três dessas políticas e as planeja.
