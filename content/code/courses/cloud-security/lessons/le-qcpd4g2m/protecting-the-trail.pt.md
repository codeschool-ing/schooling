---
title: Uma trilha que os registrados não conseguem desligar
version: 1
---

**As pessoas que uma trilha registra são as que mais facilmente podem pará-la.** Quem tem
`AdministratorAccess` pode chamar `StopLogging` e `DeleteTrail`, ou apagar os registros do bucket, e
um intruso cuidadoso com uma chave dessas faz exatamente isso antes de qualquer outra coisa. Então a
trilha é protegida em três camadas: uma recusa antes da mudança, registros guardados onde a conta não
alcança, e prova de que o que está lá não foi editado.

## Uma recusa que vale mais que a AdministratorAccess

A aula 6 mostrou que um `Deny` explícito vence todo `Allow`. Escrito sobre as pessoas que administram
a conta, ele tira as quatro chamadas que cegariam a trilha e deixa intacto todo o resto que elas
fazem. Salve como `keep-the-trail.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "cloudtrail:PutEventSelectors"
      ],
      "Resource": "*"
    }
  ]
}
```

O caio administra a conta, então ele recebe a `AdministratorAccess` e a proteção ao lado dela. Para
mandar um comando com a chave dele e não com a do admin, digite de novo o `with_key` da aula 13 se
este terminal não o tiver:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam put-user-policy --user-name caio --policy-name keep-the-trail --policy-document file://keep-the-trail.json
ana@laptop:~/aws$ caio=$(aws iam create-access-key --user-name caio)
ana@laptop:~/aws$ with_key "$caio" aws cloudtrail stop-logging --name clinic-trail

aws: [ERROR]: An error occurred (403) when calling the StopLogging operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:iam::123456789012:user/caio is not authorized to perform: cloudtrail:StopLogging</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
ana@laptop:~/aws$ with_key "$caio" aws cloudtrail get-trail-status --name clinic-trail --query IsLogging
true
ana@laptop:~/aws$ with_key "$caio" aws cloudtrail describe-trails --query "trailList[].[Name,IsMultiRegionTrail,LogFileValidationEnabled]" --output text
clinic-trail	True	True
```

**A trilha continua registrando, e o caio continua lendo a configuração dela.** Ele foi recusado na
única coisa que a proteção nomeia, apesar de uma política que permite `*`.

Uma proteção em cada usuário é uma proteção que alguém esquece no próximo usuário. Na AWS o mesmo
`Deny` é escrito uma vez, como política de controle de serviço na organização, onde ele vale para
toda identidade de toda conta membro, administradores e o usuário raiz da conta membro incluídos. O
moto guarda políticas de controle de serviço e não aplica nenhuma, então essa versão **não foi
executada aqui**; a política de identidade acima é a parte que o moto julga.

## Registros que a conta não alcança

Uma trilha gravando num bucket da mesma conta pode ser esvaziada por qualquer pessoa autorizada a
apagar os objetos desse bucket. Duas coisas da documentação da AWS, **não executadas aqui**, põem os
registros fora de alcance:

- **uma conta separada para logs.** Uma trilha de organização, criada na conta de gerenciamento,
  registra todas as contas membro num bucket que pertence a uma conta de arquivo de logs, que ninguém
  usa para mais nada. Um administrador da conta de produção da clínica não tem então permissão
  nenhuma sobre o bucket;
- **o S3 Object Lock** nesse bucket, em modo de conformidade (*compliance*) com um período de
  retenção. Um objeto sob essa trava não pode ser apagado nem sobrescrito por usuário nenhum até o
  período acabar, o usuário raiz incluído, e o período não pode ser encurtado.

## Prova de que o que está lá não mudou

O `--enable-log-file-validation`, definido na seção anterior, faz o CloudTrail gravar um **arquivo de
digest** a cada hora: o hash SHA-256 de cada arquivo de log entregue naquela hora, assinado com uma
chave privada que o CloudTrail guarda, e encadeado ao digest anterior. `aws cloudtrail validate-logs`
confere a cadeia para um período e aponta um arquivo de log que foi alterado, apagado ou nunca
entregue. O moto não grava logs nem digests, então isso **não foi executado aqui**.

::: track security
A aula 3 do curso `soc-response` provou que um log não mudou com uma cadeia de hashes e o mandou para
fora da máquina que o escreveu. Arquivos de digest e uma conta de arquivo de logs são as mesmas duas
ideias, feitas para você pelo provedor, assim que você as liga.
:::

::: track *
A ideia é mais velha que a nuvem: fazer o hash de cada arquivo, assinar os hashes, encadear cada
assinatura à anterior e guardar o resultado onde as pessoas registradas não conseguem gravar. Um
arquivo que falta ou foi alterado quebra então a cadeia no ponto onde aconteceu. A aula 3 do curso
`soc-response` monta a mesma cadeia à mão para arquivos de log comuns.
:::

## Um alarme na tentativa

A última camada é perceber. O `StopLogging` recusado da dani na seção anterior não causou dano, e
mesmo assim é a linha mais importante da tarde: a chave de uma ex-prestadora tentando cegar a conta.
**Um alarme para `StopLogging`, `DeleteTrail` e `PutEventSelectors`, recusados ou não, pertence à
lista curta de alarmes que acordam alguém.** Na AWS a trilha também manda os registros para um grupo
do CloudWatch Logs, um filtro de métrica ali conta os registros com esses valores de `eventName`, e um
alarme sobre a métrica chega a uma pessoa. O CIS AWS Foundations Benchmark lista esse filtro e esse
alarme entre as suas verificações. Nada disso foi executado aqui, já que o moto não produz registros
para contar.
