---
title: Uma proteção que mantém as cópias novas no Brasil
version: 1
---

**Um inventário acha a cópia depois que ela existe. Uma proteção recusa a requisição que a criaria.
Na AWS, a proteção para residência é uma política de controle de serviço, uma SCP, que nega toda ação
pedida fora de `sa-east-1`, anexada pela organização às contas que guardam dados de pacientes.** Uma
SCP é uma camada que só tira permissões e nunca concede nenhuma, usada aqui para geografia.

## A política

É um `Deny` com uma condição sobre `aws:RequestedRegion`, a região para a qual uma requisição é
endereçada. Salve como `only-sao-paulo.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideSaoPaulo",
      "Effect": "Deny",
      "NotAction": ["iam:*", "organizations:*", "sts:*", "support:*", "cloudfront:*", "route53:*", "budgets:*"],
      "Resource": "*",
      "Condition": {"StringNotEquals": {"aws:RequestedRegion": ["sa-east-1"]}}
    }
  ]
}
```

**O `NotAction` é a parte que as pessoas erram.** Alguns serviços da AWS são globais: IAM,
Organizations, CloudFront, Route 53 e mais alguns respondem de um lugar só, qualquer que seja a região
em que você trabalha, e as requisições deles não carregam `sa-east-1`. Um `"Action": "*"` simples os
negaria também, e a conta não conseguiria mais gerenciar os próprios usuários. Então a instrução nega
tudo *exceto* os serviços globais, e só quando a região pedida não é São Paulo. A documentação da AWS
traz uma lista mais longa de exceções no próprio exemplo dessa política, e a lista deve ser conferida
contra ela antes do uso.

## Anexando

Uma SCP pertence a uma organização, então a clínica precisa de uma, mesmo com uma conta só. No
laboratório, crie a organização, ligue as SCPs e anexe a política na raiz, que cobre toda conta
abaixo dela:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-7yfo4aeh7t
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ aws organizations enable-policy-type --root-id "$root" --policy-type SERVICE_CONTROL_POLICY --query "Root.PolicyTypes[].Status" --output text
ENABLED
ana@laptop:~/aws$ policy=$(aws organizations create-policy --name only-sao-paulo --type SERVICE_CONTROL_POLICY --description "Keep new resources in Brazil" --content file://only-sao-paulo.json --query Policy.PolicySummary.Id --output text)
ana@laptop:~/aws$ aws organizations attach-policy --policy-id "$policy" --target-id "$root"
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id "$root" --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text
FullAWSAccess	only-sao-paulo
```

Duas políticas ficam na raiz. A `FullAWSAccess` é a que a AWS anexa quando as SCPs são ligadas, e ela
permite tudo; como uma SCP só limita, o par se lê como *tudo é permitido, exceto fora de São Paulo*.
Tirar a `FullAWSAccess` sem pôr uma permissão no lugar deixaria cada conta membro sem nada permitido,
que é o erro oposto.

Agora peça um bucket na Irlanda:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-test-eu --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1 --query Location --output text
/clinic-test-eu
```

**O moto o criou.** Esta é a linha da tabela da aula 1 que diz que SCPs são guardadas e nunca
aplicadas, e aqui está o que isso custa: o laboratório não consegue mostrar esta proteção funcionando.
Duas coisas valem na AWS no lugar disso, e as duas vêm da documentação dela, **não executadas**:

- numa **conta membro** da organização, a mesma requisição é recusada com `AccessDenied`, e a mensagem
  aponta uma política de controle de serviço como motivo;
- na **conta de gerenciamento**, a que criou a organização, ela dá certo, porque **uma SCP nunca se
  aplica à conta de gerenciamento**. É o desenho da AWS, não uma falha do laboratório, e é por isso que
  dados de pacientes ficam numa conta membro, com a conta de gerenciamento reservada para administrar
  a organização e mais nada.

O moto também não ajudaria com uma política de identidade com a mesma condição: ele ignora condições,
então um `Deny` com `aws:RequestedRegion` recusaria toda região, São Paulo inclusive. **O laboratório
consegue conferir que a proteção está escrita e anexada. Só a AWS consegue conferir que ela morde**, e
uma política como esta é testada numa conta membro de uma organização real antes de alguém confiar
nela.

## Onde a proteção para

Ela controla para onde vão as **requisições novas**. Não move o bucket `clinic-backups-us` que já
existe; o inventário o achou, e alguém precisa decidir movê-lo ou registrar por que ele fica. E não
impede o dado de sair pela aplicação: um sistema de agendamento que manda por e-mail os resultados de
um paciente para um serviço de e-mail estrangeiro transferiu dado para fora sem fazer uma única
requisição à AWS fora de São Paulo. Residência é uma propriedade de cada caminho que o dado percorre,
e uma política sobre a API cobre um deles.
