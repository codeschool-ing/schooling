---
title: Tornando o acidente difícil de acontecer
version: 1
---

O acidente desta lição precisou de um comando comum de alguém com permissão para apagar um objeto num
bucket. **Prevenir é quase todo sobre essa permissão**, e em parte sobre tornar o erro recuperável
quando a permissão existe assim mesmo.

## Menos gente que consegue apagá-lo

A política do bucket de estado pode recusar a exclusão de objetos de estado a todos, exceto a um papel
nomeado, usado para manutenção de verdade:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StateIsNotDeletedByHand",
      "Effect": "Deny",
      "Principal": "*",
      "Action": ["s3:DeleteObject", "s3:DeleteObjectVersion"],
      "Resource": "arn:aws:s3:::shop-tfstate-123456789012/*.tfstate",
      "Condition": {
        "ArnNotEquals": {
          "aws:PrincipalArn": "arn:aws:iam::123456789012:role/state-maintenance"
        }
      }
    }
  ]
}
```

Uma negação explícita vence qualquer permissão (lição 8 de `aws-foundations`), então alguém com
permissões totais no S3 ainda não consegue apagar um objeto `.tfstate`, e os arquivos de trava, que o
Terraform apaga a cada execução, ficam de fora porque terminam em `.tflock`. **O moto não avalia
políticas de bucket**, então essa política não foi testada aqui; na AWS ela teria recusado o
`aws s3 rm` da primeira seção.

## Versões que não podem ser removidas antes da hora

O versionamento tornou a restauração possível, e uma regra de ciclo de vida que expira versões **não
atuais** depois de alguns dias impede que o histórico cresça para sempre. Escolha os dias pensando no
acidente: o histórico precisa durar mais do que o tempo que alguém leva para perceber. Noventa dias de
um estado gravado quarenta vezes por dia são alguns milhares de objetos pequenos, um custo desprezível
por essa proteção.

Para uma garantia mais forte, o **S3 Object Lock** em modo de governança recusa a exclusão de qualquer
versão por um tempo fixo, mesmo para administradores sem uma permissão especial. Ele precisa ser
escolhido na criação do bucket, e vale a pena para o estado da produção.

## Hábitos

- `terraform state pull` antes de qualquer coisa incomum: um `state mv`, uma atualização de provider,
  uma importação;
- **nunca editar o estado à mão** no bucket; os subcomandos `terraform state` existem para que cada
  mudança passe por uma trava e deixe um serial para trás;
- um estado por ambiente e por equipe, para um acidente custar um deles e não todos;
- um alerta quando um objeto de estado é apagado: o CloudTrail registra eventos de dados do S3 se
  pedirem (lição 20), e uma exclusão de `shop/terraform.tfstate` vale um chamado a qualquer hora.
