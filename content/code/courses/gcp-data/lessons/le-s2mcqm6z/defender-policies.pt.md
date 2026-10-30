---
title: Políticas da organização do lado de quem defende
version: 1
---

**Uma política da organização é uma regra definida na organização, ou numa pasta, que todo projeto
abaixo herda e nenhum projeto consegue desligar.** A aula 4 de `gcp-foundations` ensinou o mecanismo.
Para quem defende o Cloud Storage, ela é a resposta à pergunta com que a seção anterior terminou: como
garantir que o bucket que alguém criar no ano que vem, num projeto de que ninguém ouviu falar ainda,
seja privado sem que ninguém precise lembrar de torná-lo. Uma configuração num bucket protege aquele
bucket. Uma restrição na organização protege todo bucket que vier a existir abaixo dela.

Cada política define uma restrição, e estas são as que guardam os dados da Quitanda, como a lista de
restrições do Google,
cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints, as descreve:

| restrição | o que impõe |
|---|---|
| `storage.publicAccessPrevention` | prevenção de acesso público em todo bucket abaixo, diga o bucket o que disser |
| `storage.uniformBucketLevelAccess` | acesso uniforme em todo bucket novo, para que as ACLs nunca voltem |
| `iam.allowedPolicyMemberDomains` | permissões do IAM só a principais dos domínios da própria organização, o que também exclui `allUsers` e `allAuthenticatedUsers` |
| `iam.disableServiceAccountKeyCreation` | nenhuma chave de conta de serviço pode ser baixada, então URLs assinadas são feitas por personificação |
| `gcp.resourceLocations` | recursos só nos locais listados, como `southamerica-east1` |

**As duas primeiras fecham as formas de um vazamento; a terceira as fecha de novo na camada do IAM**,
para o dia em que alguém achar um jeito de contornar as configurações do bucket. A quarta trata da URL
assinada da primeira seção desta aula. Com ela, o `signer-key.json` que aquela seção fez não poderia
existir para uma conta real, e toda URL seria assinada por `--impersonate-service-account`, por uma
conta de serviço que alguém tem permissão de personificar, por no máximo 12 horas. A quinta mantém os
dados no Brasil, o que uma lei de privacidade pode pedir e que nenhuma configuração de um bucket só
consegue prometer para o próximo.

A documentação do Google diz que organizações criadas desde 2024 começam com várias dessas impostas
por padrão, as duas restrições de armazenamento e a restrição de domínio entre elas. Uma organização
mais antiga, que é a maioria, precisa defini-las ela mesma.

## Escrevendo uma

Uma política é um documento curto. Esta impõe a prevenção de acesso público à organização inteira da
Quitanda, cujo número aqui é inventado:

`pap-policy.yaml`:

```yaml
name: organizations/123456789012/policies/storage.publicAccessPrevention
spec:
  rules:
  - enforce: true
```

E ela é aplicada com um comando:

```sh
gcloud org-policies set-policy pap-policy.yaml
```

**Nenhum dos dois foi executado aqui**: não há organização neste laboratório, nem emulador do Resource
Manager. Numa organização real o comando exige o papel Organization Policy Administrator, que a
Quitanda dá a duas pessoas e a nenhuma conta de serviço, porque quem pode mudar uma restrição também
pode tirá-la. Uma política pode ser testada antes de ser imposta: a documentação descreve um teste
(dry run) que informa o que uma restrição teria recusado sem recusar, que é o jeito de achar o
pipeline que escreve objetos públicos de propósito antes que a política o quebre.

## Mais duas camadas, citadas e não construídas

**As políticas de negação do IAM** recusam uma permissão a um principal diga o que disserem as
políticas de permissão, e a aula 7 de `gcp-foundations` é onde elas são ensinadas. Para armazenamento,
a útil nega `storage.objects.delete` e `storage.buckets.setIamPolicy` a todo mundo menos um grupo de
emergência.

**O VPC Service Controls** desenha um perímetro em volta de um conjunto de projetos e recusa
requisições ao armazenamento deles vindas de fora, mesmo com credenciais válidas. É a defesa contra uma
chave que vazou: uma chave roubada usada do laptop de outra pessoa está fora do perímetro. Ele exige
uma organização, um desenho de rede e uma política de acesso, e o lugar dele são os cursos de rede;
aqui basta saber que é a camada que não confia só em credenciais.

## A restrição que é sobrescrita

Cada uma dessas restrições pode ser sobrescrita mais abaixo na hierarquia, numa pasta ou num projeto,
por alguém com o papel de administrador, e isso é proposital: o bucket público de fotos da seção
anterior precisa disso. **Uma exceção é o lugar para olhar primeiro numa revisão**, porque é o único
lugar onde a regra da organização não vale, e o lugar onde um erro seria invisível a partir de
qualquer bucket. O comando da documentação para listar as políticas definidas num projeto, `gcloud
org-policies list --project=PROJECT`, responde por projeto, e o Cloud Asset Inventory, aula 25 de
`gcp-foundations`, responde pela organização numa busca.
