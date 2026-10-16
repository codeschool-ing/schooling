---
title: Rotação, desativação, e a exclusão que não se desfaz
version: 1
---

## Rotação

Rotacionar uma chave KMS dá a ela **material novo** e guarda o antigo, então tudo o que foi cifrado antes
continua decifrando e tudo o que for cifrado depois usa o novo. O id, o ARN, o alias e a política da chave
não mudam, e nenhum programa percebe. Ligada, a rotação acontece num agendamento:

```
ana@laptop:~/aws/kms$ aws kms enable-key-rotation --key-id $KEY --rotation-period-in-days 365
ana@laptop:~/aws/kms$ aws kms get-key-rotation-status --key-id $KEY
{
    "KeyRotationEnabled": true
}
```

Na AWS o período pode ir de 90 a 2.560 dias, 365 por padrão, e `get-key-rotation-status` responde com o
período e a próxima data; o moto guarda só o sim. `rotate-key-on-demand` rotaciona na hora, que é a
resposta quando o material de uma chave pode ter sido exposto. **Nada é cifrado de novo**: com criptografia
de envelope só chaves de dados foram cifradas com a chave KMS, e chaves de dados antigas continuam sendo
decifradas com o material antigo, que o KMS guarda pela vida da chave.

## Desativar

`disable-key` para todo uso da chave na hora, cifrar e decifrar, até `enable-key`. É a alavanca a puxar
quando o uso de uma chave parece errado, porque se desfaz num segundo. O que ela quebra é tudo o que
depende da chave, o que, para a chave de um banco, é o banco.

## Exclusão

Excluir uma chave KMS exclui o material, e **todo texto cifrado feito com ela fica ilegível para
sempre**: os backups, os snapshots, os arquivos selados da seção anterior. Por isso o KMS nunca exclui na
hora. Ele agenda a exclusão de **7 a 30 dias** à frente, e a chave espera em `PendingDeletion`:

```
ana@laptop:~/aws/kms$ aws kms schedule-key-deletion --key-id $KEY --pending-window-in-days 7 --query DeletionDate --output text
2026-10-23T16:35:08.482077-03:00
ana@laptop:~/aws/kms$ aws kms describe-key --key-id $KEY --query 'KeyMetadata.KeyState' --output text
PendingDeletion
ana@laptop:~/aws/kms$ aws kms decrypt --ciphertext-blob fileb://note.enc --encryption-context order=1001 --query Plaintext --output text | base64 -d; echo
card ending 4242
ana@laptop:~/aws/kms$ aws kms cancel-key-deletion --key-id $KEY --query KeyId --output text
e646e99c-ee02-4891-b5c7-9ac684b09fad
ana@laptop:~/aws/kms$ aws kms describe-key --key-id $KEY --query 'KeyMetadata.KeyState' --output text
Disabled
ana@laptop:~/aws/kms$ aws kms enable-key --key-id $KEY
ana@laptop:~/aws/kms$ aws kms describe-key --key-id $KEY --query 'KeyMetadata.KeyState' --output text
Enabled
```

O terceiro comando é o erro do moto. **Na AWS uma chave pendente de exclusão não pode ser usada de jeito
nenhum**: o decrypt falha com `KMSInvalidStateException`, e essa falha é o propósito do período de espera,
porque o que ainda precisa da chave quebra de forma visível enquanto a exclusão pode ser cancelada. O moto
decifrou como se nada tivesse acontecido.

Cancelar deixa a chave **`Disabled`**, e não ativa, na AWS como no moto, então cancelar uma exclusão não
põe a chave de volta em uso em silêncio: alguém precisa ativá-la de propósito. Uma equipe que agenda uma
exclusão também deve disparar alarme no uso da chave durante a espera, o que o CloudTrail permite e a
lição 20 constrói.
