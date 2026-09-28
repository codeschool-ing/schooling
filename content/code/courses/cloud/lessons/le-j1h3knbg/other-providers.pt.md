---
title: As mesmas ideias no Google Cloud e no Azure
version: 1
---

Toda ideia desta aula existe nos outros grandes provedores: um principal, uma ação sobre um recurso,
negação por padrão, credenciais temporárias para máquinas. O que muda é o vocabulário, e uma palavra
muda de sentido de um jeito que pega quem transita entre eles.

**Na AWS uma role é uma identidade. No Google Cloud e no Azure um papel (role) é um pacote de
permissões.** Uma role da AWS é algo em que você se *transforma*; um papel do Google Cloud ou do Azure
é algo que você *recebe*, sobre um recurso específico. Ler "dê ao serviço o papel Storage Object
Viewer" com o sentido da AWS na cabeça manda você procurar uma política de confiança que não existe.

| a ideia | AWS | Google Cloud | Azure |
|---|---|---|---|
| uma pessoa | um usuário do IAM, ou um usuário no IAM Identity Center | uma conta Google, gerenciada no Cloud Identity ou no Workspace | um usuário no Microsoft Entra ID |
| um conjunto de pessoas | um grupo do IAM | um grupo do Google | um grupo do Entra ID |
| uma permissão | uma ação, `s3:GetObject` | uma permissão, `storage.objects.get` | uma ação, `Microsoft.Storage/storageAccounts/read` |
| um pacote de permissões | uma política | um papel, `roles/storage.objectViewer` | uma definição de função, *Storage Blob Data Reader* |
| dar isso a alguém | anexar a política a um usuário, grupo ou role | um vínculo (binding) na política de permissão do recurso | uma atribuição de função num escopo |
| uma identidade para um programa | uma role, assumida pela VM ou pela função | uma conta de serviço | uma identidade gerenciada |

## Google Cloud

O Google Cloud guarda os recursos numa hierarquia: uma **organização** no topo, pastas dentro dela,
projetos dentro delas, e recursos como buckets e máquinas virtuais dentro dos projetos. Cada nível
tem uma política de permissão, uma lista de vínculos, cada vínculo dizendo "estes principais têm este
papel aqui". Um vínculo é herdado para baixo: um papel concedido numa pasta vale para todo projeto e
recurso dentro dela. Com isso, a pergunta "quem pode ler este bucket" é uma resposta reunida a partir
do bucket, do projeto, das pastas e da organização, e uma concessão feita lá em cima por conveniência
é uma concessão sobre tudo o que está abaixo.

Os papéis vêm em três tipos. Os **papéis básicos**, Owner, Editor e Viewer, são amplos e anteriores ao
resto; Editor num projeto pode mudar quase tudo nele. Papéis predefinidos são estreitos, por serviço,
como `roles/storage.objectViewer`. Papéis personalizados são o seu próprio pacote.

Uma **conta de serviço** é a identidade de um programa. Uma máquina virtual roda como uma delas e
recebe as credenciais temporárias de um servidor de metadados dentro da máquina, a mesma ideia da AWS.

## Azure

O Azure guarda as identidades no **Microsoft Entra ID**, o diretório que também cuida do login nos
outros serviços da Microsoft: usuários, grupos e service principals para aplicações. Permissões sobre
recursos são o Azure RBAC, controle de acesso baseado em funções, e uma concessão é uma **atribuição
de função** de três partes: um principal, uma definição de função e um escopo. O escopo é um nível da
hierarquia do próprio Azure — grupo de gerenciamento, assinatura, grupo de recursos ou um recurso
só —, e, como no Google Cloud, uma atribuição é herdada por tudo abaixo do seu escopo. Owner,
Contributor e Reader são as funções internas amplas; há outras mais estreitas por serviço.

Uma **identidade gerenciada** é a identidade de um programa: o Azure a cria para uma máquina virtual ou
uma função, dá a ela credenciais que a plataforma troca sozinha, e a apaga junto com o recurso se ela
foi criada só para ele.

## O que continua igual

A negação por padrão vale nos três: sem concessão, a resposta é não. O Google Cloud e o Azure também
têm regras de negação, as deny policies e as deny assignments, mas o trabalho do dia a dia ali é
feito quase todo com concessões. A pergunta a fazer a qualquer concessão é a que esta aula faz a
uma política da AWS: qual principal, quais ações, sobre o quê, e até onde ela desce. Os cursos de cada
fornecedor, `aws-foundations`, `gcp-foundations` e `azure-foundations`, levam cada uma dessas ideias
para o próprio console e a própria linha de comando.
