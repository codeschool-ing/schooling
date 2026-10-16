---
title: A conta de gerenciamento, e contas que já existem
version: 1
---

**A conta de gerenciamento é a conta mais poderosa da organização, então ela deve fazer o mínimo.**
A imagem tentadora é o contrário: ela é a primeira conta, já existe, alguém tem a senha, então as
primeiras máquinas da loja vão para lá. Três fatos fazem dela o pior lugar da árvore para elas.

- **Ela alcança dentro de todo membro.** Cada conta que ela criou carrega uma role que ela pode
  assumir, que a próxima transcrição mostra. Quem controla a conta de gerenciamento controla todas.
- **Nenhuma regra da organização se aplica a ela.** As barreiras da lição 4 restringem toda
  conta-membro e nunca a conta de gerenciamento, por projeto. Uma carga de trabalho lá roda fora de
  todas elas.
- **Ela guarda a fatura e a árvore.** Dela alguém pode criar contas, movê-las entre galhos,
  removê-las e trocar o meio de pagamento.

Então a conta de gerenciamento da loja não roda nada, pouquíssimas pessoas podem entrar nela, e
entram para dois trabalhos: a organização e a fatura. **Trabalho que tem de ser feito para a árvore
inteira é passado a um membro.** O Organizations deixa a conta de gerenciamento nomear um membro como
**administrador delegado** de um serviço, como as ferramentas de segurança que a lição 5 põe na conta
`security`, para que até esses trabalhos deixem a conta de gerenciamento em paz.

## A role em toda conta que ela criou

```
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_arn arn:aws:iam::$(account shop-prod):role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-prod.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_session_name ana
ana@laptop:~/aws$ aws --profile shop-prod iam get-role --role-name OrganizationAccountAccessRole --query "Role.AssumeRolePolicyDocument"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
ana@laptop:~/aws$ aws --profile shop-prod iam list-attached-role-policies --role-name OrganizationAccountAccessRole
{
    "AttachedPolicies": []
}
```

São as três linhas da lição 2 de novo, com o número da conta procurado em vez de digitado, já que a
`shop-prod` deste moto é outra conta. A **política de confiança** da role diz quem pode assumi-la:
`arn:aws:iam::123456789012:root`, que quer dizer a conta de gerenciamento como um todo, qualquer
identidade dela que o IAM dela deixe passar, e não o usuário root dela. A lição 9 lê políticas de
confiança com calma.

**A segunda resposta é onde o moto e a AWS se separam.** Na AWS, a `OrganizationAccountAccessRole`
chega com a política gerenciada `AdministratorAccess` anexada, então assumi-la dá controle total da
conta-membro. No moto a role chega **sem política nenhuma**. Nada nesta lição percebe, porque o moto
não verifica permissão até a lição 7 ligar isso; dali em diante, a role de uma conta-membro no moto
não tem permissão para nada até uma política ser anexada a ela. O `create-account` também recebe um
`--role-name`, para uma empresa que quer a role com outro nome.

## Uma conta que já existe

**Uma conta existente entra por convite, e o convite tem de ser aceito de dentro dela.** A conta de
gerenciamento o envia com `invite-account-to-organization`; a AWS manda um e-mail ao dono da outra
conta; alguém com acesso a essa conta o aceita com `accept-handshake`, e só então ela é membro. A
troca se chama **handshake**, e existe porque entrar entrega a fatura e os limites de uma conta a
outra pessoa: ninguém pode fazer isso com uma conta a não ser a própria conta.

O moto não tem nada disso:

```
ana@laptop:~/aws$ aws organizations invite-account-to-organization --target Id=111122223333,Type=ACCOUNT

aws: [ERROR]: An error occurred (500) when calling the InviteAccountToOrganization operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

`500` é o moto dizendo que a operação não foi implementada, não a AWS recusando alguma coisa, e
`111122223333` é o número fictício que a própria documentação da AWS usa para "alguma outra conta".
**O convite, o e-mail e a aceitação não foram rodados aqui**; o que esta seção diz deles é
comportamento documentado da AWS.

Duas diferenças acompanham uma conta convidada pelo resto da vida. **Ela não tem
`OrganizationAccountAccessRole`**, porque a organização não a criou: se a conta de gerenciamento
precisa entrar, um administrador da conta convidada cria essa role à mão, com a mesma política de
confiança e a mesma `AdministratorAccess`. E o `describe-account` informa o `JoinedMethod` dela como
`INVITED` em vez de `CREATED`, que é como uma lista de contas diz quais vieram com história própria.

## Saindo

Um membro sai com `leave-organization`, rodado de dentro dele, ou é removido pela conta de
gerenciamento com `remove-account-from-organization`. De um jeito ou de outro ele volta a ser uma
conta avulsa, com fatura própria, então **a AWS não o deixa ir até ele ter o que uma conta avulsa
precisa**: um meio de pagamento, dados de contato e um plano de suporte. Uma conta criada dentro da
organização não tem nada disso, o que torna sair mais difícil que entrar, de propósito. A lição 4
escreve a barreira que proíbe sair de vez, já que uma conta que sai da árvore sai de toda regra
anexada a ela.
