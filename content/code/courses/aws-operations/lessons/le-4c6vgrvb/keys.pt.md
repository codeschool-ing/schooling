---
title: Três tipos de chave, e a política dona de cada uma
version: 1
---

A `SecureString` da lição 17 foi cifrada com uma chave que ninguém criou: `aws/ssm`. A maior parte da
criptografia na AWS funciona assim, uma caixa marcada num bucket ou num banco que nomeia uma chave no
**KMS**, o Key Management Service. O KMS guarda as chaves em módulos de segurança de hardware, e **uma
chave KMS nunca sai do KMS**: ninguém, nem a própria equipe da AWS, consegue tirar o material dela. O que um
programa recebe é o resultado de pedir ao KMS que use a chave, cifre isto, decifre aquilo, e cada um desses
pedidos é conferido contra uma política e registrado no CloudTrail, assunto da lição 20.

Há três tipos de chave, conforme quem as gerencia:

| tipo | exemplo | quem decide a política | quanto custa |
|---|---|---|---|
| da AWS | a chave por trás da criptografia padrão do DynamoDB | a AWS; ela nem está na conta | nada |
| gerenciada pela AWS | `aws/ssm`, `aws/s3`, `aws/rds` | a AWS; a conta pode ler a política, não mudá-la | sem mensalidade, requisições são cobradas |
| gerenciada pelo cliente | `alias/shop-orders`, criada nesta lição | a equipe | uma mensalidade por chave, e requisições |

O motivo de pagar pelo terceiro tipo é **controle**. Uma chave gerenciada pela AWS pode ser usada por
qualquer principal da conta que possa usar o serviço a que ela pertence, e nada estreita isso. Uma chave
gerenciada pelo cliente tem uma **política de chave** que a equipe escreve, então pode dizer que só o
serviço de pedidos decifra, pode ser desativada numa emergência, compartilhada com outra conta e agendada
para exclusão, o que torna ilegível para sempre tudo o que foi cifrado com ela.

## A política da chave vem primeiro

Toda chave KMS tem exatamente uma política de chave, e **ela é a raiz do acesso à chave**. Uma política
IAM que permite `kms:Decrypt` só funciona se a política da chave deixar o IAM decidir, o que a política
padrão faz com uma única instrução dando `kms:*` ao principal root da conta. Essa instrução não dá nada de
especial ao usuário root na prática; ela entrega a decisão às políticas IAM da conta. Tire-a, e as
políticas IAM deixam de importar, para o bem e para o mal: uma política de chave que nomeia só uma role é
uma chave que só essa role usa e que ninguém mais, administradores inclusive, consegue gerenciar até essa
role mudar a política.

A próxima seção cria uma chave e lê de volta a política padrão dela, para essa instrução ficar visível.
