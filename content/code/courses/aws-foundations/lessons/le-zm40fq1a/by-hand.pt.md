---
title: A mesma forma à mão, e o que ela deixa de fora
version: 1
---

**O Control Tower não roda neste laboratório, mas a forma que ele constrói roda.** O moto não tem
Control Tower: o serviço responde toda chamada com uma falha, como o primeiro comando abaixo mostra.
A maior parte do que o Control Tower monta, porém, é Organizations por baixo, e as lições 3 e 4 já
conduziram o Organizations à mão. Esta seção põe esses passos num script, roda-o contra um moto
vazio, e depois diz com clareza que partes de uma landing zone o script não constrói e não
consegue construir.

## O que o moto diz

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para esta lição começar
de uma AWS vazia, e peça a ele uma landing zone:

```
ana@laptop:~/aws$ aws controltower list-landing-zones

aws: [ERROR]: An error occurred (500) when calling the ListLandingZones operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**Um `500` é o moto falhando, não a AWS respondendo.** O comando existe na CLI da AWS e, contra uma
conta, lista a landing zone, se houver uma. O moto não implementa nada do serviço. Então nada nesta
lição sobre o Control Tower em si foi rodado.

## `landing-zone.sh`

O script constrói a árvore com que uma landing zone do Control Tower começaria a loja. Ele cria a OU
`Security` com as duas contas que vigiam as outras, e as OUs `Workloads` e `Sandbox` da própria
loja. Põe uma barreira sobre o registro, e nomeia a conta `security` administradora do GuardDuty
para a organização. Cole o bloco inteiro no segundo terminal; ele escreve o arquivo:

```sh
cat > ~/aws/landing-zone.sh <<'EOF'
#!/usr/bin/env bash
# The shop's landing zone by hand: the shape Control Tower would build, in Organizations.
set -euo pipefail

aws organizations create-organization --query Organization.Id --output text
root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
# AWS enables SCPs with the organisation; moto has to be asked (lessons 3 and 4)
scps=$(aws organizations list-roots \
  --query "Roots[0].PolicyTypes[?Type=='SERVICE_CONTROL_POLICY'].Status" --output text)
if [ "$scps" != ENABLED ]; then
  aws organizations enable-policy-type --root-id "$root" --policy-type SERVICE_CONTROL_POLICY > /dev/null
fi

ou() {  # PARENT NAME: create an OU, print its id
  aws organizations create-organizational-unit --parent-id "$1" --name "$2" \
    --query OrganizationalUnit.Id --output text
}
security=$(ou "$root" Security)
workloads=$(ou "$root" Workloads)
ou "$workloads" Prod > /dev/null
ou "$workloads" Staging > /dev/null
ou "$root" Sandbox > /dev/null

account() {  # NAME PARENT: create an account, wait for it, move it into PARENT
  local req state id
  req=$(aws organizations create-account --email "aws+$1@example.com" --account-name "$1" \
    --query CreateAccountStatus.Id --output text)
  while :; do
    state=$(aws organizations describe-create-account-status --create-account-request-id "$req" \
      --query CreateAccountStatus.State --output text)
    case $state in
      SUCCEEDED) break ;;
      FAILED) echo "creating $1 failed" >&2; exit 1 ;;
    esac
    sleep 10
  done
  id=$(aws organizations describe-create-account-status --create-account-request-id "$req" \
    --query CreateAccountStatus.AccountId --output text)
  aws organizations move-account --account-id "$id" --source-parent-id "$root" --destination-parent-id "$2"
  echo "$1 $id"
}
account log-archive "$security"
security_id=$(account security "$security" | cut -d' ' -f2)
echo "security $security_id"

# one guardrail on the record: nobody but the platform deletes the logs or stops a trail
policy=$(aws organizations create-policy --name protect-the-record --type SERVICE_CONTROL_POLICY \
  --description "Nobody deletes the shop's logs or stops a trail" --query Policy.PolicySummary.Id --output text \
  --content '{"Version": "2012-10-17", "Statement": [{"Effect": "Deny",
    "Action": ["s3:DeleteBucket", "s3:DeleteObject", "s3:PutLifecycleConfiguration", "s3:PutBucketPolicy",
               "cloudtrail:StopLogging", "cloudtrail:DeleteTrail"],
    "Resource": "*",
    "Condition": {"ArnNotLike": {"aws:PrincipalArn": "arn:aws:iam::*:role/OrganizationAccountAccessRole"}}}]}')
aws organizations attach-policy --policy-id "$policy" --target-id "$security"
echo "guardrail $policy on Security"

# the security account runs GuardDuty for the whole organisation
aws organizations enable-aws-service-access --service-principal guardduty.amazonaws.com
aws organizations register-delegated-administrator --account-id "$security_id" \
  --service-principal guardduty.amazonaws.com
echo "delegated administrator for GuardDuty: $security_id"
EOF
```

Quatro coisas nele pedem explicação, e as duas primeiras estão lá porque a AWS não é o moto. **O teste antes do `enable-policy-type`** está
lá porque na AWS o tipo já está ligado, e pedir de novo é um erro, `PolicyTypeAlreadyEnabledException`,
que pararia o script. **O laço de espera** existe porque a AWS cria uma conta em segundo plano, como a
lição 2 disse. No moto a primeira resposta já é `SUCCEEDED`, então o laço nunca dorme.
**`set -euo pipefail`** para o script no primeiro comando que falhar, para uma landing zone pela
metade dizer isso em vez de seguir em frente. E a barreira é o padrão da lição 4 de novo: um deny com
`Resource` `*`, anexado à `Security` e não à raiz, porque dentro da `Security` não há nada que alguém
deva apagar. A role por onde a conta de gerenciamento entra fica de fora pelo `aws:PrincipalArn`,
já que alguém tem de conseguir escrever a política do bucket de logs em primeiro lugar.

## Rodando

```
ana@laptop:~/aws$ bash landing-zone.sh
o-vpkre95at2
log-archive 178477898891
security 028214792238
guardrail p-s645pgwp on Security
delegated administrator for GuardDuty: 028214792238
```

Depois pergunte à organização o que ela guarda agora:

```
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ aws organizations list-organizational-units-for-parent --parent-id $root --query "OrganizationalUnits[].[Id,Name]" --output text
ou-ucqy-2ezpckv1	Security
ou-ucqy-pubvas6q	Workloads
ou-ucqy-0tp6pz8a	Sandbox
ana@laptop:~/aws$ security=$(aws organizations list-organizational-units-for-parent --parent-id $root --query "OrganizationalUnits[?Name=='Security'].Id" --output text)
ana@laptop:~/aws$ aws organizations list-accounts-for-parent --parent-id $security --query "Accounts[].[Id,Name]" --output text
178477898891	log-archive
028214792238	security
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id $security --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text
FullAWSAccess	protect-the-record
ana@laptop:~/aws$ aws organizations list-delegated-administrators --query "DelegatedAdministrators[].[Id,Name]" --output text
028214792238	security
```

**Esta é a forma, e só a forma.** As OUs, as duas contas em `Security`, a barreira e o administrador
delegado estão todos lá. Na AWS cada um desses comandos teria feito o mesmo. O que uma landing zone
de verdade também tem é tudo o que mora **dentro** das contas, e é aí que o script para.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" data-fig=\"l05-compare\" aria-label=\"A landing zone da loja, com o que o landing-zone.sh construiu no moto desenhado em traço contínuo e o que o Control Tower acrescentaria desenhado tracejado. Contínuo: a organização e as suas SCPs na conta de gerenciamento; as OUs Security, Workloads e Sandbox; as contas log-archive e security em Security; a barreira protect-the-record em Security; a security registrada como administradora delegada do GuardDuty. Tracejado, não rodado: o Control Tower e o Account Factory, o IAM Identity Center, a trilha da organização e o bucket de logs na log-archive, o agregador do Config na security, um gravador do Config e a trilha em cada conta de carga de trabalho, os controles dos três tipos e a detecção de drift.\"><rect x=\"20.0\" y=\"20.0\" width=\"330.0\" height=\"150.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">conta de gerenciamento</text><rect x=\"36.0\" y=\"54.0\" width=\"298.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a organização, OUs e SCPs</text><rect x=\"36.0\" y=\"92.0\" width=\"298.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"185.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Control Tower e Account Factory</text><rect x=\"36.0\" y=\"130.0\" width=\"298.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"185.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">IAM Identity Center (lição 11)</text><rect x=\"380.0\" y=\"20.0\" width=\"320.0\" height=\"150.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"67.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">os controles, em toda OU:</text><text x=\"540.0\" y=\"81.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">preventivos (SCPs)</text><text x=\"540.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">detectivos (regras do Config)</text><text x=\"540.0\" y=\"108.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">proativos (hooks do CloudFormation)</text><text x=\"540.0\" y=\"122.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">e a detecção de drift</text><rect x=\"20.0\" y=\"200.0\" width=\"440.0\" height=\"220.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"36.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Security</text><text x=\"444.0\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">protect-the-record</text><rect x=\"36.0\" y=\"234.0\" width=\"196.0\" height=\"172.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">log-archive</text><rect x=\"248.0\" y=\"234.0\" width=\"196.0\" height=\"172.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"346.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">security</text><rect x=\"48.0\" y=\"266.0\" width=\"172.0\" height=\"48.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"134.0\" y=\"283.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">trilha da organização</text><text x=\"134.0\" y=\"296.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">entrega aqui</text><rect x=\"48.0\" y=\"324.0\" width=\"172.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"134.0\" y=\"346.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o bucket de logs</text><text x=\"134.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">para os registros</text><text x=\"134.0\" y=\"372.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">de toda conta</text><rect x=\"260.0\" y=\"266.0\" width=\"172.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"283.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">GuardDuty: administradora</text><text x=\"346.0\" y=\"296.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">delegada</text><rect x=\"260.0\" y=\"324.0\" width=\"172.0\" height=\"70.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"346.0\" y=\"346.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">agregador do Config</text><text x=\"346.0\" y=\"359.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">e as notificações</text><text x=\"346.0\" y=\"372.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">da segurança</text><rect x=\"480.0\" y=\"200.0\" width=\"220.0\" height=\"120.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"496.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Workloads</text><text x=\"684.0\" y=\"218.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Prod, Staging</text><rect x=\"494.0\" y=\"234.0\" width=\"192.0\" height=\"72.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">em cada conta:</text><text x=\"590.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">um gravador do Config</text><text x=\"590.0\" y=\"283.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">e a trilha</text><rect x=\"480.0\" y=\"340.0\" width=\"220.0\" height=\"80.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"496.0\" y=\"358.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sandbox</text><rect x=\"494.0\" y=\"370.0\" width=\"192.0\" height=\"38.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"389.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o mesmo, quando chegarem contas</text><rect x=\"140.0\" y=\"438.0\" width=\"26.0\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"174.0\" y=\"446.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">construído pelo landing-zone.sh, no moto</text><rect x=\"420.0\" y=\"438.0\" width=\"26.0\" height=\"16.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"454.0\" y=\"446.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o Control Tower acrescenta; não rodado</text></svg>", "caption": "O script construiu a árvore. Tudo o que mora dentro das contas continua tracejado."}
```

## O que o script deixa de fora

**Nem trilha nem bucket.** A conta `log-archive` não guarda nada: uma landing zone põe uma trilha da
organização no CloudTrail, cujos registros de toda conta caem num bucket lá. O script teria de
assumir uma role na `log-archive`, criar o bucket com uma política que deixe o CloudTrail escrever
nele, e criar a trilha a partir da conta de gerenciamento. A lição 9 tem a parte entre contas. **Nada
de Config**, e portanto nada de controles detectivos: nada registra o que as contas contêm. **Nenhum
jeito de as pessoas entrarem**: o IAM Identity Center é a lição 11. **Nenhuma detecção de drift**: o
script roda uma vez, e o que for mudado depois fica mudado. E ele não toma decisão nenhuma sobre as
**credenciais do root** nas contas-membro, que a lição 2 disse que a conta de gerenciamento pode
remover. Uma landing zone deveria resolver isso também.

**Não rodado aqui, nada disto**: a montagem do Control Tower, o Account Factory, os controles que ele
liga e a detecção de drift dele. Esses estão descritos pela documentação da AWS nas duas seções
anteriores desta lição.

## Os outros jeitos de construí-la

O Control Tower é o serviço que a AWS vende para isso, e não é o único jeito.

- O **Account Factory for Terraform**, AFT, mantém o Control Tower e troca o formulário de contas dele
  por um pipeline de Terraform: uma conta nova é um arquivo num repositório, revisado e mesclado como
  código. O curso `iac` ensina o Terraform em si.
- O **Landing Zone Accelerator on AWS** é uma solução que a AWS publica e suporta, implantada na conta
  de gerenciamento, que constrói uma base maior a partir de arquivos de configuração e funciona ao
  lado do Control Tower. É voltado a organizações com exigências de conformidade rígidas.
- **Organizations e infraestrutura como código, sem Control Tower nenhum**, que é o `landing-zone.sh`
  crescido: as mesmas chamadas, em Terraform ou CloudFormation, com a trilha, o bucket e o Config
  acrescentados. Dá mais trabalho e menos surpresas, e a empresa é dona de cada parte.

Seja qual for o escolhido, **o teste de uma landing zone é a próxima conta**. Se a `shop-analytics`
fosse criada amanhã, ela chegaria na sua OU, sob as suas barreiras, mandando logs para a
`log-archive` e vigiada pela `security`, sem ninguém ter de lembrar de nada? Um script que só rodou
uma vez não responde isso; uma fábrica responde.
