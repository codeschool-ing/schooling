---
title: Fechando o caminho, na ordem certa
version: 1
---

**Feche a porta de entrada antes de arrumar as permissões.** Uma chave que ainda funciona consegue
desfazer qualquer mudança de política que você fizer, já que foi exatamente isso que esta foi vista
fazendo. Então a ordem é: parar a chave, depois tirar as políticas do usuário, depois o usuário, e
provar cada passo perguntando de novo.

## Pare a chave

O primeiro passo cuidadoso é desativar a chave em vez de apagá-la. Uma chave inativa pode ser ligada
de novo se descobrirem que um processo esquecido depende dela, que é o motivo habitual de as pessoas
hesitarem aqui:

```
ana@laptop:~/aws$ aws iam update-access-key --user-name dani --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId) --status Inactive
ana@laptop:~/aws$ aws iam list-access-keys --user-name dani --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKM7XXHV3H	Inactive
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text
admin	caio	bia	dani
```

**O moto ainda a aceitou.** A chave está marcada como `Inactive` e a requisição que ela assinou
passou. A AWS recusa toda requisição assinada com uma chave inativa, então numa conta real é aqui que
o caminho pararia. É por isso que uma transcrição nunca é a prova inteira neste curso: aqui o
laboratório está errado, e a documentação é a fonte. Para uma chave usada hoje por uma pessoa que
saiu, a leitura prudente é que nada pode depender dela com segurança, e apagá-la é o passo que vale
nos dois lugares:

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name dani --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId)
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
```

`InvalidClientTokenId`: a chave não existe mais, e nada que ela assine é obedecido. **Essa recusa é a
prova**, como o `403` de uma requisição anônima foi na aula 1.

## Depois o usuário

Um usuário com políticas não pode ser apagado; a AWS obriga a tirá-las antes, e o erro diz isso:

```
ana@laptop:~/aws$ aws iam detach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam delete-user --user-name dani

aws: [ERROR]: An error occurred (DeleteConflict) when calling the DeleteUser operation: Cannot delete entity, must delete policies first.
ana@laptop:~/aws$ aws iam delete-user-policy --user-name dani --policy-name manage-users
ana@laptop:~/aws$ aws iam delete-user --user-name dani
ana@laptop:~/aws$ bash iam-writers.sh
admin	AdministratorAccess	*
ana@laptop:~/aws$ aws iam list-users --query "Users[].UserName" --output text
admin	caio	bia
```

A segunda execução de `bash iam-writers.sh` é a prova desta metade. Ela imprime uma linha, `admin`,
que é a que deve imprimir; as linhas da dani foram embora com o usuário dela.

## Mantenha fechado

Remover um caminho não impede que a política do próximo prestador seja escrita do mesmo jeito. Três
proteções existem para isso, e cada uma é aplicada pela AWS acima da política que um administrador
com pressa escreve:

| proteção | o que faz | neste laboratório |
|---|---|---|
| uma condição na política que delega | `iam:PolicyARN` limita *quais* políticas podem ser anexadas, para que "anexar a política de relatórios" não vire "anexar qualquer coisa" | o moto ignora condições |
| um limite de permissões | um teto num usuário ou papel: diga o que disserem as políticas dele, ele não faz mais do que o limite permite | guardado, não aplicado |
| uma política de controle de serviço | um `Deny` para a organização inteira em escritas no IAM, para todos menos um papel de administrador | guardada, não aplicada |

**Nenhuma das três foi executada aqui**, pelos motivos da coluna da direita; o que cada uma faz é o
comportamento documentado da AWS. A primeira é a correção estreita para o trabalho da dani, a segunda
é o jeito padrão de deixar uma equipe criar papéis sem deixar que esses papéis passem da equipe, e a
terceira é o piso da conta inteira sobre o qual as outras duas se apoiam.

E um processo, que não é configuração nenhuma: **tirar uma pessoa do provedor de identidade e tirar o
usuário do IAM dela precisam ser o mesmo passo**, na mesma lista de verificação, até não sobrar mais
usuário do IAM de pessoa para remover. Essa é a mudança que a segunda seção desta aula defendeu, e é a
que teria parado esta história em março.
