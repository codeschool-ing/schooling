---
title: Credenciais temporárias: quanto duram, como se encadeiam, como se chamam
version: 1
---

**As credenciais de uma sessão trazem o próprio fim.** `Expiration` está na resposta do
`assume-role`, e depois dela a AWS recusa a chave, o segredo e o token juntos, sem nada para alguém
revogar. Quanto tempo isso dura depende de dois números: o `--duration-seconds` que quem chama pede,
e o `MaxSessionDuration` da role, que põe o teto.

## Quanto dura uma sessão

**O padrão é uma hora, o mínimo permitido é quinze minutos, e uma role pode permitir até doze
horas.** A própria linha de comando recusa qualquer coisa abaixo de 900 segundos antes de enviar a
requisição. Acima disso, a AWS recusa um pedido maior que o máximo da role, e o máximo se aumenta na
role, não por quem chama:

```
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 600

aws: [ERROR]: An error occurred (ParamValidation): Parameter validation failed:
Invalid value for parameter DurationSeconds, value: 600, valid min value: 900
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 900 --query Credentials.Expiration --output text
2026-10-16T17:08:26.777090+00:00
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --duration-seconds 7200 --query Credentials.Expiration --output text
2026-10-16T18:53:27.279140+00:00
ana@laptop:~/aws$ aws iam update-role --role-name deployer --max-session-duration 7200
ana@laptop:~/aws$ aws iam get-role --role-name deployer --query Role.MaxSessionDuration
7200
```

**O moto não aplica o máximo.** Duas horas foram concedidas numa role cujo máximo ainda era uma, e a
AWS teria recusado esse pedido; essa recusa não foi rodada aqui. Aumentar o máximo para 7200 com o
`update-role` é o que torna o mesmo pedido válido na AWS. Os horários de expiração acima estão em
UTC, três horas à frente de São Paulo, e são a resposta do moto nesta execução; os seus serão a hora
da sua.

Que duração escolher é uma troca que o dono da role faz uma vez. **Uma sessão curta limita o quanto
vale uma que vazar; uma longa poupa uma pessoa de entrar de novo no meio da tarde.** Um pipeline de
entrega precisa de minutos; uma pessoa no console, de um dia de trabalho no máximo.

## Encadeamento de roles

Uma sessão pode ela mesma assumir outra role, o que a AWS chama de **role chaining**: a bia vira
`deployer`, e a sessão da `deployer` vira `auditor`. A documentação da AWS impõe a isso uma regra que
surpreende: **uma sessão encadeada dura no máximo uma hora**, seja qual for o máximo da segunda role,
e pedir mais é recusado. O encadeamento também é como uma trilha de identidades fica longa o bastante
para ninguém saber quem a começou, que é o assunto da próxima parte desta seção.

No moto a corrente se rompe antes, pelo motivo que a seção anterior deu. Uma política de confiança
que nomeia `role/deployer` é comparada, como string, com o ARN da sessão,
`assumed-role/deployer/...`, e eles diferem:

```
ana@laptop:~/aws$ aws iam create-role --role-name auditor --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:role/deployer"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/auditor
ana@laptop:~/aws$ aws iam put-role-policy --role-name deployer --policy-name chain-to-auditor --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::123456789012:role/auditor*"}]}'
ana@laptop:~/aws$ s=$(with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy)
ana@laptop:~/aws$ with_session "$s" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/auditor --role-session-name chained

aws: [ERROR]: An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy is not authorized to perform: sts:AssumeRole
ana@laptop:~/aws$ aws iam create-role --role-name auditor-session --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/auditor-session
ana@laptop:~/aws$ with_session "$s" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/auditor-session --role-session-name chained --duration-seconds 7200 --query "[AssumedRoleUser.Arn,Credentials.Expiration]" --output text
arn:aws:sts::123456789012:assumed-role/auditor-session/chained	2026-10-16T18:53:31.618451+00:00
```

A AWS aceita o ARN de uma role numa política de confiança como querendo dizer as sessões dela, então
a primeira tentativa teria dado certo lá, e durado uma hora. **O moto só aceitou a política de
confiança que nomeia a sessão exata**, que ninguém escreve numa conta real, porque o nome da sessão
muda a cada quem chama. O limite de uma hora no encadeamento não foi medido aqui; o moto deu à sessão
encadeada as duas horas pedidas.

## Quem fez: nomes de sessão e source identity

**Tudo o que se faz por meio de uma role fica registrado sob a sessão, não sob a pessoa.** O
CloudTrail, o log de auditoria de chamadas de API da AWS, registra quem fez cada chamada como o ARN
da sessão, `arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy`, e a chamada `AssumeRole`
que criou a sessão como um evento separado que nomeia a bia. Juntar os dois é possível e trabalhoso,
e o nome da sessão é a parte barata da resposta: **um nome que diz quem, como `bia-deploy`, deixa
toda linha posterior legível**, enquanto `session1` faz de cada uma uma busca.

O nome da sessão é escolha de quem chama, porém, então não prova nada. A **source identity** é a
forma mais forte: `--source-identity bia` define um valor que fica registrado no CloudTrail em toda
chamada da sessão e **passa para toda role encadeada a partir dela**, e que quem chama não pode mudar
depois. Uma role pode exigi-la: a política de confiança dela permite `sts:SetSourceIdentity` ao lado
de `sts:AssumeRole`, com uma condição em `sts:SourceIdentity`. O moto aceita o parâmetro e não
devolve source identity nenhuma:

```
ana@laptop:~/aws$ with_key "$bia" aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --source-identity bia --query "{User:AssumedRoleUser.Arn,SourceIdentity:SourceIdentity}"
{
    "User": "arn:aws:sts::123456789012:assumed-role/deployer/bia-deploy",
    "SourceIdentity": null
}
```

A AWS devolve `SourceIdentity` na resposta e nas linhas de log da sessão. **O moto não guarda
registro de CloudTrail das chamadas que responde**, e responde ao `cloudtrail lookup-events` com
HTTP 500, então nada do registro nesta parte foi rodado. A lição 26 abre uma das requisições do
próprio moto no lugar, e a lição 20 do `aws-operations` trata do CloudTrail em si.
