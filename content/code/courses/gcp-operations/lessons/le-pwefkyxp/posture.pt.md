---
title: Dos achados à postura
version: 1
---

**Corrigir achados um por um mantém um projeto limpo por uma semana; a postura é o que o mantém limpo.** Todo achado da
seção anterior veio de algo que alguém tinha permissão para fazer: tornar um bucket público, abrir um firewall, criar
uma chave. A correção duradoura tira a permissão de criar o problema, para que o mesmo achado não possa aparecer de novo
no mês seguinte. Nada nesta seção foi executado; ela vem da documentação do Google e das lições anteriores do curso.

## Impedir, depois detectar

| o achado | detectar (Security Command Center) | impedir |
|---|---|---|
| um bucket público | `PUBLIC_BUCKET_ACL` | a política da organização `storage.publicAccessPrevention`, e `public_access_prevention = "enforced"` como a lição 6 pôs no bucket de estado |
| uma chave de conta de serviço | `SERVICE_ACCOUNT_KEY_NOT_ROTATED` | a política da organização `iam.disableServiceAccountKeyCreation` |
| SSH aberto para a internet | `OPEN_FIREWALL` | nenhuma regra de firewall permitindo `0.0.0.0/0` na porta 22, revisada nos planos do Terraform |
| uma imagem sem assinatura | (nenhuma diretamente) | Binary Authorization, lição 4 |
| uma cópia de dados para fora do projeto | (nenhuma diretamente) | VPC Service Controls, lição 19 |

As políticas da organização (lição 4 de `gcp-foundations`) recusam a mudança no momento em que é feita, para todos,
inclusive um owner. **Um achado que uma política tornou impossível nunca precisa de triagem.** O recurso de **postura
de segurança** do Security Command Center empacota um conjunto dessas políticas e detectores como uma postura
declarada por organização ou pasta, e relata o desvio dela; a loja, com um projeto, escreve as políticas no Terraform,
onde a mesma revisão vale para elas e para todo o resto.

## Detectar ainda importa

Impedir cobre o que pode ser previsto. Achados de ameaça cobrem o que não pode: uma credencial válida usada num
horário estranho, uma permissão concedida por alguém que nunca concede permissões. Esses não podem ser impedidos por
configuração, porque as ações são permitidas; só podem ser percebidos. Dois hábitos garantem que sejam:

- **Uma notificação para achados de ameaça novos**, roteada ao canal de plantão da lição 14: o Security Command
  Center pode publicar achados novos num tópico do Pub/Sub, e um achado de ameaça é exatamente o tipo de sinal que
  precisa de uma pessoa agora.
- **Uma revisão semanal da lista aberta**, na ordem da seção anterior, com as regras de silenciamento relidas. Uma
  lista que ninguém lê cresce até alguém deixar de confiar nela, que é a fadiga da lição 14, para achados.
