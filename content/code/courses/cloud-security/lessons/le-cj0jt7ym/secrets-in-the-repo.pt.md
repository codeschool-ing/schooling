---
title: Uma chave no repositório fica no repositório
version: 1
---

**Um segredo commitado num repositório é publicado para todo mundo que um dia o clonar, e apagar a
linha num commit seguinte não o recolhe.** A correção para uma chave vazada é sempre torná-la inútil,
nunca só torná-la invisível. Esta seção encontra uma com um scanner e depois mostra por que
encontrá-la nos arquivos de hoje não basta.

## Uma configuração antiga

Em 2019, a bia montou o bucket de relatórios mensais com Terraform no notebook dela e, para fazer
funcionar, escreveu uma chave de acesso no bloco do provider. A chave abaixo foi inventada para esta
aula e nunca foi válida em lugar nenhum; o que importa é o formato. Crie um repositório para ela:

```sh
mkdir -p ~/aws/reports && cd ~/aws/reports
git init -q
git config user.name bia
git config user.email bia@clinic.example
```

Salve isto como `main.tf`:

```hcl
provider "aws" {
  region     = "sa-east-1"
  access_key = "AKIA2E0A8F3B244C9986"
  secret_key = "zhYmT8kq3NfR7cW2pLx9vB4aJd6sE1uGo5iHtM0y"
}

resource "aws_s3_bucket" "reports" {
  bucket = "clinic-reports"
}
```

Faça o commit, como a bia fez, e rode o scanner de segredos do Checkov sobre o diretório. Ele procura
os formatos de credenciais conhecidas e sequências longas com cara de aleatórias:

```
ana@laptop:~/aws/reports$ git add main.tf && git commit -q -m "Monthly reports bucket"
ana@laptop:~/aws/reports$ checkov -d . --framework secrets --compact --quiet --skip-download; echo "exit status $?"
secrets scan results:

Passed checks: 0, Failed checks: 2, Skipped checks: 0

Check: CKV_SECRET_2: "AWS Access Key"
	FAILED for resource: df3cdbabb93a89194b3b2526eafe279dd8ff98f2
	File: /main.tf:3-4
Check: CKV_SECRET_6: "Base64 High Entropy String"
	FAILED for resource: ec4af7bd32f6ea96ede723fdfe88cf3b30ab6ac5
	File: /main.tf:4-5

exit status 1
```

Dois achados para uma credencial. O `CKV_SECRET_2` reconhece o id da chave de acesso pelo formato:
vinte caracteres começando com `AKIA`, que é como começa a chave de longa duração de um usuário do
IAM, como a aula 7 explica. O `CKV_SECRET_6` não sabe nada de AWS. Ele marca a chave secreta porque
quarenta caracteres com essa aleatoriedade raramente querem dizer outra coisa. O scanner esconde a
maior parte do valor na saída, para que o próprio relatório não vaze o segredo uma segunda vez.

## Removê-la, e o que isso não remove

O provider não precisa de chave no arquivo: ele lê as credenciais do ambiente, como faz o `env.sh`, ou
de um perfil. Mude o bloco do provider para este, e faça o commit:

```hcl
provider "aws" {
  region = "sa-east-1"
}
```

```
ana@laptop:~/aws/reports$ git commit -q -am "Take the keys out of the provider"
ana@laptop:~/aws/reports$ checkov -d . --framework secrets --compact --quiet --skip-download; echo "exit status $?"

exit status 0
ana@laptop:~/aws/reports$ git log -p -S AKIA2E0A8F3B244C9986 --format='%an %s' | grep -E '^bia|AKIA'
bia Take the keys out of the provider
-  access_key = "AKIA2E0A8F3B244C9986"
bia Monthly reports bucket
+  access_key = "AKIA2E0A8F3B244C9986"
```

Os arquivos estão limpos e o scanner passa. **O histórico ainda guarda a chave**, e o `git log -S` a
encontra no próprio commit que a adicionou, e no que a tirou. Todo clone feito antes de hoje a tem, e
também todo fork, todo cache de CI e todo backup do repositório. Um scanner que lê só os arquivos
atuais responde a uma pergunta mais estreita do que a que importa.

::: track devsecops
A aula 6 do curso `secure-pipeline` roda um scanner sobre o histórico inteiro e bloqueia um push que
carregue um segredo, que é o lugar de pegá-lo antes de ele ser publicado.
:::

::: track *
Scanners feitos para isso, como o gitleaks e o TruffleHog, leem todo commit do histórico em vez dos
arquivos como estão, e costumam rodar a cada push para que um segredo seja barrado antes de ser
publicado. Eles não foram executados para este curso.
:::

## O que fazer com uma chave vazada

Nesta ordem, e a ordem é o ponto:

1. **Torne a chave inútil.** Desative-a, depois apague-a quando nada quebrar; a aula 7 faz exatamente
   isso com uma chave que vazou. Até este passo, todo o resto é cosmético.
2. **Descubra o que ela fez.** O último uso da chave, e toda chamada que ela fez, estão nos registros
   da conta; a aula 15 os lê.
3. **Troque-a por algo que não vaze do mesmo jeito**: credenciais do ambiente num notebook, um papel
   para qualquer coisa que rode na nuvem ou num pipeline (aula 14).
4. **Depois, se quiser, limpe o histórico.** Reescrever um repositório tira a linha das cópias que
   você controla, e de nenhuma das outras. É arrumação, nunca o remédio.

Uma chave real publicada num repositório público é encontrada depressa, por quem varre código público
atrás exatamente disso, e é por isso que o GitHub trabalha com a AWS para reconhecer chaves da AWS
enviadas a repositórios públicos e avisá-la. Nada desse arranjo foi executado aqui.
