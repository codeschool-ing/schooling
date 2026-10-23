---
title: Armazenamento, chaves e segredos, de três jeitos
version: 1
---

**Armazenamento de objetos, gerência de chaves e guarda de segredos existem nos três provedores, e os
três cifram os dados guardados por padrão. Onde eles diferem é em quantas chaves ficam entre um objeto
privado e a internet, e no que quer dizer "uma chave que nós gerenciamos".** As aulas 9 a 11
aprofundam a AWS; esta seção é o mapa dos outros dois, pela documentação deles e sem execução.

## Como um objeto fica público

| | onde fica a chave | a proteção acima dela |
|---|---|---|
| AWS S3 | uma política de bucket concedendo `"Principal": "*"`, ou uma ACL concedendo *All Users* | o **Block Public Access**, no bucket e na conta; ligado nos buckets novos desde 2023 |
| Azure Blob Storage | o nível de acesso de um contêiner, *Blob* ou *Container*, que só funciona se a conta de armazenamento permitir acesso anônimo | a propriedade `allowBlobPublicAccess` da conta, e o Azure Policy para mantê-la em false |
| Google Cloud Storage | um binding de IAM de `allUsers` ou `allAuthenticatedUsers` no bucket | a **prevenção de acesso público** no bucket, ou a restrição `storage.publicAccessPrevention` na organização |

**O caminho do Azure exige duas chaves ligadas, uma na conta e uma no contêiner**, o que já é uma
segurança: ligar o acesso anônimo na conta não expõe nada até um contêiner também aderir. O **acesso
uniforme no nível do bucket** do Google Cloud desliga as ACLs por objeto, para que a política de IAM
do bucket seja a única coisa que decide quem o lê; a AWS chega ao mesmo lugar definindo a
propriedade do objeto como *bucket owner enforced*, que desliga as ACLs. Em todos os casos a defesa
tem o mesmo formato: **uma configuração no alto que recusa a publicação, para que ninguém precise
acertar todos os buckets**.

## Links que carregam a própria permissão

Cada provedor consegue assinar uma URL que dá acesso a quem a tiver, por um tempo:

| | o link | assinado com |
|---|---|---|
| AWS | uma URL pré-assinada | as credenciais de quem a gerou |
| Azure | uma assinatura de acesso compartilhado (SAS) | uma chave da conta, ou uma chave de delegação de usuário do Entra ID |
| Google Cloud | uma URL assinada | a chave de uma conta de serviço, ou a API de assinatura |

**Qualquer um que tenha o link pode usá-lo até ele vencer**, e o link aparece no histórico do
navegador, em logs de chat e em e-mails. A aula 10 executa o da AWS. No Azure, uma SAS assinada com a
chave da própria conta de armazenamento não tem um botão de revogar só dela. A documentação da
Microsoft dá duas saídas: amarrar a SAS de antemão a uma política de acesso armazenada, para que
apagar a política a mate, ou rotacionar a chave da conta, o que mata de uma vez toda SAS assinada com
essa chave. Uma SAS de delegação de usuário, assinada pelo Entra ID, é a opção que a Microsoft
recomenda.

## Chaves e segredos

| | chaves para criptografia | segredos para programas |
|---|---|---|
| AWS | AWS KMS | AWS Secrets Manager |
| Azure | chaves do Azure Key Vault, ou Managed HSM | segredos do Azure Key Vault |
| Google Cloud | Cloud KMS, em key rings | Secret Manager |

**A criptografia em repouso vem ligada por padrão nos três, com chaves que o provedor gerencia.**
Escolher uma chave gerenciada por você, nos serviços acima, muda quem pode desligar os dados e quem
enxerga cada uso da chave, não se o disco é cifrado. A aula 11 torna essa diferença concreta na AWS.

Os modelos de acesso diferem num ponto que vale saber. Uma chave do AWS KMS tem uma **política de
chave** própria, e, a menos que essa política deixe o IAM da conta decidir, permissões do IAM sozinhas
não abrem a chave. O Azure Key Vault oferece dois modelos, as antigas políticas de acesso do cofre e o
Azure RBAC, e a Microsoft recomenda o RBAC; um cofre ainda em políticas de acesso tem uma segunda
lista de quem lê segredos, num lugar para onde uma revisão de RBAC nunca olha. O Cloud KMS do Google
usa papéis comuns do IAM no key ring ou na chave.
