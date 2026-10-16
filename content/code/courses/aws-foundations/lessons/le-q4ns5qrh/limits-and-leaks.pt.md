---
title: Estreitando o que uma chave pode fazer, e o dia em que uma vaza
version: 1
---

**Uma chave que precisa existir deve poder fazer o mínimo possível, e as ações mais perigosas devem
exigir mais que a chave.** O `erp-sync` já mostra a primeira metade. A política dele nomeia uma ação
num prefixo de um bucket, então uma cópia da chave dele consegue enviar arquivos e nada mais. A
segunda metade é uma condição que pede um segundo fator. A última parte desta seção é o que fazer
quando, apesar das duas, uma chave aparece onde não devia.

## Um segundo fator para as ações que doem

A `dani`, do financeiro, ainda tem um usuário do IAM de antes do Identity Center, com acesso ao S3
para os relatórios do mês. Apagar um backup deveria exigir o celular dela além da chave. **Uma chave
não traz MFA sozinha.** Uma sessão o ganha quando a usuária chama `sts get-session-token` com o
código do dispositivo dela. As requisições assinadas com essa sessão levam
`aws:MultiFactorAuthPresent` igual a `true`. Esta recusa vale sempre que não for o caso. Salve-a
como `~/aws/mfa-to-delete.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:DeleteObject", "s3:DeleteBucket"],
      "Resource": ["arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*"],
      "Condition": {"BoolIfExists": {"aws:MultiFactorAuthPresent": "false"}}
    }
  ]
}
```

**`BoolIfExists` é a palavra importante.** Uma requisição assinada só com a chave não leva
`aws:MultiFactorAuthPresent` nenhum. Um `Bool` simples não bateria com uma chave ausente, então o
deny erraria justamente a requisição para a qual existe. O `IfExists` faz a chave ausente contar
como coincidência.

```
ana@laptop:~/aws$ aws iam create-user --user-name dani --query User.Arn --output text
arn:aws:iam::123456789012:user/dani
ana@laptop:~/aws$ aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name mfa-to-delete --policy-document file://mfa-to-delete.json
ana@laptop:~/aws$ read -r DANI_ID DANI_SECRET < <(aws iam create-access-key --user-name dani --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3api list-objects-v2 --bucket shop-backups --query "Contents[].Key" --output text
erp/sales.csv
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3 rm s3://shop-backups/erp/sales.csv
delete failed: s3://shop-backups/erp/sales.csv An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
```

Listar funcionou e apagar foi recusado, que é o que a AWS faria com uma chave e sem MFA. **Mas o
moto chegou à resposta certa pelo motivo errado**, e mais um teste mostra isso. Esta versão inverte
a condição, para recusar só requisições que têm MFA. Uma chave sozinha deveria passar. Salve-a como
`~/aws/mfa-flipped.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:DeleteObject", "s3:DeleteBucket"],
      "Resource": ["arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*"],
      "Condition": {"Bool": {"aws:MultiFactorAuthPresent": "true"}}
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name mfa-to-delete --policy-document file://mfa-flipped.json
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$DANI_ID AWS_SECRET_ACCESS_KEY=$DANI_SECRET aws s3 rm s3://shop-backups/erp/sales.csv
delete failed: s3://shop-backups/erp/sales.csv An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
```

**O moto recusou de novo, então ele ignora a condição por inteiro**: um `Deny` com um bloco
`Condition` nega sempre, diga a condição o que disser. A outra metade do teste, uma sessão com MFA
dando certo, também não pode ser executada. A própria verificação do moto recusa as credenciais que
o `get-session-token` dele devolve. Então o laboratório mostra a política e a recusa. Se a condição
bate é a avaliação documentada pela AWS, não algo medido aqui.

## O dia em que uma chave vaza

A ordem importa mais que a velocidade de qualquer passo, e é a mesma ordem que todo roteiro publicado
usa:

1. **desative a chave**, na hora. `update-access-key --status Inactive` a faz parar de funcionar e
   pode ser revertido; apagá-la primeiro joga fora o que o IAM sabe dela, como o último uso, e não
   tem volta se a chave for uma de que um programa ainda precisa;
2. **descubra o que ela fez.** O CloudTrail registra toda chamada com o id da chave de acesso que a
   assinou, então a pergunta é uma busca por esse id: quais ações, de quais endereços, desde quando.
   Procure em especial usuários novos, chaves novas e roles novas, porque um invasor cuidadoso abre
   outra entrada antes de a primeira ser fechada;
3. **desfaça o que ela criou**, e trate qualquer sessão que ela tenha aberto com `GetSessionToken`;
4. **troque**: uma chave nova para o programa, como na seção anterior, e a antiga apagada;
5. **ache o vazamento**, ou a próxima chave vaza do mesmo jeito.

**O CloudTrail não é executado neste laboratório.** Ele pertence ao curso `aws-operations`, e o moto
5.2.3 responde o `lookup-events` com um erro interno.

A AWS também age por conta própria. Quando ela acha uma das suas chaves em público, pela própria
varredura ou por aviso de um parceiro, ela pode anexar ao usuário uma política gerenciada chamada
**`AWSCompromisedKeyQuarantineV3`**. Ela também escreve para o endereço de contato da conta. O moto
traz uma cópia da política, e a forma dela diz o que a AWS considera a parte perigosa de uma chave
roubada:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[].[Effect,length(Action)]" --output text
Deny	98
Deny	1
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" --output text | tr "\t" "\n" | cut -d: -f1 | sort | uniq -c | sort -rn | head -5
     26 iam
     16 s3
     10 lambda
      6 lightsail
      6 ec2
```

Ligar máquinas, criar usuários e chaves, mudar políticas, ler o CloudTrail: ela nega as ações que um
invasor usa para gastar dinheiro e para ficar. **É um freio, não uma cura**: ela deixa a chave ativa
e não desfaz nada. A própria orientação da AWS ainda manda trocar a chave e investigar. A cópia do
moto é a versão `v3` da política. A AWS revisa as políticas gerenciadas dela, então a contagem pode
ser outra numa conta. Aplicá-la você mesmo é o mesmo `attach-user-policy` de qualquer outra, e ela
vai ao lado da desativação, não no lugar dela:

```
ana@laptop:~/aws$ aws iam update-access-key --user-name dani --access-key-id $DANI_ID --status Inactive
ana@laptop:~/aws$ aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3
ana@laptop:~/aws$ aws iam list-attached-user-policies --user-name dani --query "AttachedPolicies[].PolicyName" --output text
AWSCompromisedKeyQuarantineV3	AmazonS3FullAccess
```

## Pegando uma chave antes de ela sair

O vazamento mais barato de tratar é o que nunca chega a um remoto. Duas ferramentas trabalham nesse
ponto, e nenhuma foi executada aqui:

- o **secret scanning do GitHub** reconhece chaves da AWS entre muitos outros formatos. Num
  repositório público, o GitHub informa à AWS a chave encontrada, o que pode disparar a quarentena
  acima. Com o **push protection** ligado, um push que contém uma chave é recusado antes de ser
  aceito;
- o **`git-secrets`**, do AWS Labs, instala hooks num repositório local e recusa um commit cujas
  mudanças batem com os padrões de chave da AWS. Ele pega a chave no laptop, antes de qualquer
  servidor vê-la.

As duas procuram a forma de uma chave, e é por isso que a ordem desta lição se mantém. **A única
chave que não pode vazar é a que nunca foi criada**, e um varredor é a rede embaixo dessa regra, não
um substituto dela.
