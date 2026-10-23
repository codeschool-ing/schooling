---
title: Identidade, onde os três discordam
version: 1
---

**A aula 7 do curso `cloud` deu o vocabulário: um papel da AWS é algo em que você se transforma, um
papel do Google Cloud ou do Azure é algo que você recebe. Esta seção trata de quatro lugares em que os
três se comportam de jeitos diferentes, de modos que decidem se uma concessão é segura**, cada um um
erro que as pessoas levam de um provedor para o seguinte.

## 1. Quem é "todo mundo"

Cada provedor tem um jeito de nomear todos os chamadores de uma vez, e cada um tem um segundo que
parece mais estreito do que é:

| | todo mundo, autenticado ou não | uma armadilha que parece mais estreita |
|---|---|---|
| AWS | `"Principal": "*"` numa política de recurso | o grupo de ACL do S3 *Authenticated Users*, que quer dizer qualquer conta AWS do mundo, não a sua |
| Google Cloud | `allUsers` | `allAuthenticatedUsers`, que quer dizer qualquer pessoa conectada a qualquer conta Google, não a sua organização |
| Azure | acesso anônimo a um contêiner de blobs | um link de assinatura de acesso compartilhado (SAS), que funciona para quem o tiver (aula 10) |

**"Autenticado" nunca quer dizer "nosso".** A AWS e o Google documentam isso com todas as letras, e
mesmo assim isso já expôs armazenamento mais de uma vez: alguém queria "só usuários logados" e
concedeu a toda conta do planeta. A aula 9 é o lado do armazenamento disso.

## 2. Se existe negação, e quem a escreve

**A AWS avalia negações explícitas em qualquer política que se aplique**, e uma negação explícita
vence toda permissão; a aula 6 usa isso para pôr uma proteção sobre uma pessoa. **O Azure RBAC é
aditivo**: as permissões de um principal são a união das atribuições de papel dele. O Azure tem
*atribuições de negação*, mas os clientes não as escrevem livremente; o próprio Azure as cria para
recursos como aplicativos gerenciados. O jeito do dia a dia de proibir algo no Azure é uma Azure
Policy com efeito `Deny` sobre a configuração, não uma negação sobre a pessoa. **O Google Cloud tem
políticas de negação do IAM**, anexadas à organização, a uma pasta ou a um projeto, e avaliadas antes
das políticas de permissão; a maioria das organizações ainda trabalha quase só com permissões.

Então "acrescentar uma negação para este usuário" é uma linha na AWS, um mecanismo diferente no
Google Cloud e, em geral, um redesenho no Azure.

## 3. Dois planos de administração no Azure

O Azure tem **dois sistemas de papéis separados**. Os papéis do Microsoft Entra, como *Global
Administrator*, governam o diretório: usuários, grupos, aplicativos. Os papéis do Azure RBAC, como
*Owner*, governam as assinaturas e os recursos dentro delas. Eles são atribuídos em lugares diferentes
e listados em lugares diferentes, e uma auditoria de um não enxerga o outro.

Eles se encontram numa chave documentada: um Global Administrator pode ligar o **elevate access**
(elevar o acesso), que lhe dá *User Access Administrator* na raiz de todas as assinaturas do tenant, e
de lá ele pode se conceder qualquer coisa. A Microsoft documenta isso como o jeito de recuperar o
controle das assinaturas de um tenant, e recomenda remover o acesso elevado assim que ele deixar de
ser necessário. **O papel mais alto do diretório é, portanto, um dono do Azure em espera**, e uma
revisão que contou só os donos do RBAC deixou esse passar.

## 4. Chaves para programas

Os três dão a um programa uma identidade sem segredo guardado: um papel da AWS assumido pela máquina
ou função, uma conta de serviço do Google Cloud anexada ao workload, uma identidade gerenciada do
Azure. Os três também ainda permitem o jeito antigo:

| | a identidade sem segredo | o segredo de longa duração que ela ainda pode ter |
|---|---|---|
| AWS | um papel | a chave de acesso de um usuário do IAM |
| Google Cloud | uma conta de serviço anexada ao workload | uma **chave de conta de serviço**, um arquivo JSON com uma chave privada |
| Azure | uma identidade gerenciada | um segredo de cliente ou certificado num registro de aplicativo |

A documentação do Google trata chaves de conta de serviço como um risco de segurança e oferece uma
restrição do Organization Policy, `iam.disableServiceAccountKeyCreation`, que recusa a criação delas
numa pasta ou na organização inteira. Esse é o formato da defesa em todo lugar: **fazer do caminho sem
segredo o padrão, e do segredo de longa duração algo que uma proteção recusa**. A aula 4 mostrou a
chave da AWS através de uma emenda; a aula 7 trata das chaves que sobram.
