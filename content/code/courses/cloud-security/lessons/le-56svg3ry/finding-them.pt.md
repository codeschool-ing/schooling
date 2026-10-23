---
title: Achando antes que outra pessoa ache
version: 1
---

**O caminho da seção anterior precisou de três coisas: um usuário que ninguém removeu, uma chave que
ninguém desativou e uma permissão que escreve no IAM. Cada uma tem o seu registro, e uma revisão lê
os três.** Nenhum deles pede ferramenta especial; a linha de comando da AWS e o `jq` bastam para uma
conta do tamanho da da clínica.

## Os usuários e as chaves deles

O **relatório de credenciais** é uma linha CSV por usuário do IAM: se ele tem senha, se tem MFA, e,
para cada uma das suas duas chaves de acesso possíveis, se está ativa, quando foi rotacionada pela
última vez e quando foi usada pela última vez. A AWS o monta sob pedido, então a primeira chamada o
pede e a segunda o lê. O `cut` guarda cinco das suas vinte e duas colunas:

```
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
STARTED
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,8,9,10,11
user,mfa_active,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date
admin,false,true,2026-10-23T03:46:27+00:00,2026-10-23T03:46:38+00:00
caio,false,false,N/A,N/A
bia,false,false,N/A,N/A
dani,false,true,2026-10-23T03:46:34+00:00,2026-10-23T03:46:36+00:00
```

Leia a linha da dani. **Sem MFA, uma chave ativa, usada hoje.** No laboratório a chave tem um minuto
de vida; na conta da clínica, `access_key_1_last_rotated` diria fevereiro. Sobre uma chave dessa
idade, de uma pessoa que saiu, a pergunta não é se ela é perigosa, mas por que ela ainda existe.
A AWS acrescenta uma primeira linha para o usuário raiz da conta, `<root_account>`, que o moto omite.

`get-access-key-last-used` responde à mesma pergunta para uma chave, com o serviço e a região da
última requisição dela:

```
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId)
{
    "UserName": "dani",
    "AccessKeyLastUsed": {
        "LastUsedDate": "2026-10-23T03:46:36.900016+00:00",
        "ServiceName": "iam",
        "Region": "sa-east-1"
    }
}
```

**Uma chave usada hoje por alguém que saiu é um incidente, não uma descoberta.** Os registros da
aula 15 diriam o que a chave fez; o trabalho desta aula é fechar o caminho, e a ordem da próxima
seção importa exatamente por isso.

## As permissões que escrevem no IAM

Quais ações entram na lista? Chutar é como uma lista esquece uma, então tire-a da AWS. Quando a AWS
descobre que uma chave de acesso foi exposta, ela anexa ao usuário uma política gerenciada, a
**política de quarentena de chave comprometida**, que nega as ações que uma chave roubada tentaria
primeiro. A terceira versão dela está na cópia das políticas gerenciadas que o moto carrega, e a
primeira instrução dela é uma lista longa:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" | jq -r ".[]" | grep -c .
98
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" | jq -r ".[] | select(startswith(\"iam:\"))"
iam:AddUserToGroup
iam:AttachGroupPolicy
iam:AttachRolePolicy
iam:AttachUserPolicy
iam:ChangePassword
iam:CreateAccessKey
iam:CreateInstanceProfile
iam:CreateLoginProfile
iam:CreatePolicyVersion
iam:CreateRole
iam:CreateUser
iam:DetachUserPolicy
iam:PassRole
iam:PutGroupPolicy
iam:PutRolePolicy
iam:PutUserPermissionsBoundary
iam:PutUserPolicy
iam:SetDefaultPolicyVersion
iam:UpdateAccessKey
iam:UpdateAccountPasswordPolicy
iam:UpdateAssumeRolePolicy
iam:UpdateLoginProfile
iam:UpdateUser
iam:DeleteRole
iam:DeleteAccessKey
iam:ListUsers
```

São noventa e oito ações em muitos serviços, e a parte do IAM é a lista que uma revisão deve
procurar. A maioria concede permissões, cria uma nova porta de entrada ou muda quem pode assumir um
papel; algumas, como `iam:ListUsers`, estão lá porque a primeira coisa que uma chave roubada faz é
olhar em volta. `iam:AttachUserPolicy`, a ação da dani, está nela.

Este script percorre todo usuário, lê toda política inline e anexada, e imprime cada `Allow` de uma
ação arriscada, ou de um curinga que inclua todas. A lista dele é um subconjunto da lista da
política de quarentena, curta o bastante para ser lida:

```sh
cat > iam-writers.sh <<'EOF'
#!/usr/bin/env bash
# Every IAM user, and every Allow on it that can change who may do what.
# Run it with a key that may read IAM. Prints: user, policy, action.
risky='["*", "iam:*", "iam:AttachUserPolicy", "iam:PutUserPolicy",
  "iam:AttachGroupPolicy", "iam:PutGroupPolicy", "iam:AddUserToGroup",
  "iam:AttachRolePolicy", "iam:PutRolePolicy", "iam:UpdateAssumeRolePolicy",
  "iam:CreatePolicyVersion", "iam:SetDefaultPolicyVersion", "iam:PassRole",
  "iam:CreateAccessKey", "iam:CreateLoginProfile", "iam:UpdateLoginProfile"]'

flag() { # USER POLICY, with the policy document on stdin
  jq -r --arg u "$1" --arg p "$2" --argjson risky "$risky" '
    [.Statement] | flatten | .[] | select(.Effect == "Allow")
    | [.Action] | flatten | .[] | select(. as $a | $risky | index($a))
    | "\($u)\t\($p)\t\(.)"'
}

for u in $(aws iam list-users --query "Users[].UserName" --output text); do
  for p in $(aws iam list-user-policies --user-name "$u" --query PolicyNames --output text); do
    aws iam get-user-policy --user-name "$u" --policy-name "$p" \
      --query PolicyDocument | flag "$u" "inline:$p"
  done
  for a in $(aws iam list-attached-user-policies --user-name "$u" \
      --query "AttachedPolicies[].PolicyArn" --output text); do
    v=$(aws iam get-policy --policy-arn "$a" --query Policy.DefaultVersionId --output text)
    aws iam get-policy-version --policy-arn "$a" --version-id "$v" \
      --query PolicyVersion.Document | flag "$u" "${a##*/}"
  done
done
EOF
```

```
ana@laptop:~/aws$ bash iam-writers.sh
admin	AdministratorAccess	*
dani	inline:manage-users	iam:AttachUserPolicy
dani	AdministratorAccess	*
```

Três linhas. O `admin` tem `AdministratorAccess` por desenho: é o administrador da conta, e uma
revisão espera encontrá-lo, uma vez, com MFA. As duas linhas da dani são o caminho: a política inline
que o abriu e a política gerenciada que foi usada para anexar.

**O script é honesto sobre o que enxerga, então leia os limites dele antes de confiar numa execução
limpa:**

- ele lê só usuários. Grupos passam as políticas deles a cada membro, e as políticas de um papel são o
  que uma função ou um pipeline tem; os dois pedem o mesmo laço;
- ele compara textos exatos. `iam:Put*` ou `iam:Attach*` concedem as mesmas ações e não imprimem
  nada;
- ele ignora `NotAction`, que permite tudo menos uma lista. A `PowerUserAccess` da AWS, a política do
  caio, é escrita assim, excluindo `iam:*`; um `NotAction` que excluísse outra coisa permitiria o IAM
  e passaria sem aviso;
- ele ignora o `Resource`. Um `iam:PassRole` limitado a um papel inofensivo sai impresso com o mesmo
  destaque que um em `*`.

Esse é o argumento honesto a favor de uma ferramenta de verdade, o assunto da aula 16: as regras
acima são chatas de acertar e fáceis de quase acertar. O argumento para escrever esta primeiro é que
agora você sabe o que uma ferramenta dessas verifica, e consegue ler as descobertas dela em vez de
confiar nelas.
