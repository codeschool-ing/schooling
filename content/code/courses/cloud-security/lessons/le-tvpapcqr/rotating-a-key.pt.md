---
title: Rotacionando uma chave sem parar a aplicação
version: 1
---

**Um usuário pode ter duas chaves de acesso ao mesmo tempo, e esse é todo o mecanismo da rotação:
criar a segunda, passar a aplicação para ela, provar que a primeira não é mais usada e então apagar a
primeira.** Os mesmos cinco passos servem para uma chave que vazou hoje de manhã e para uma que só
chegou à idade que a sua política permite, em geral noventa dias.

A imagem errada é a de que rotacionar é apagar a chave antiga e criar uma nova. Nessa ordem a
aplicação fica fora do ar desde o primeiro passo até alguém publicar a chave nova, que é exatamente a
interrupção que faz as pessoas adiarem a rotação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l07-rotation\" aria-label=\"Rotação de uma chave de acesso sem interrupção, como uma linha do tempo de duas chaves. Passo 1: a chave antiga está ativa e a aplicação a usa. Passo 2: uma segunda chave é criada; as duas estão ativas. Passo 3: a aplicação passa para a chave nova. Passo 4: a chave antiga é desativada e o último uso dela é observado por um tempo. Passo 5: a chave antiga é apagada. A todo momento a aplicação tem uma chave que funciona.\"><text x=\"70.0\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave antiga</text><text x=\"70.0\" y=\"136.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chave nova</text><rect x=\"80.0\" y=\"60.0\" width=\"400.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ativa</text><rect x=\"480.0\" y=\"60.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"535.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inativa</text><rect x=\"260.0\" y=\"120.0\" width=\"420.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ativa</text><text x=\"70.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aplicação</text><path d=\"M80.0 186.0 L370.0 186.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><path d=\"M370.0 186.0 L680.0 186.0\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><text x=\"225.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">usa a chave antiga</text><text x=\"525.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">usa a chave nova</text><path d=\"M260.0 40.0 L260.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M260.0 96.0 L260.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M260.0 156.0 L260.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"260.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2. criar</text><path d=\"M370.0 40.0 L370.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M370.0 96.0 L370.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M370.0 156.0 L370.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"370.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3. trocar</text><path d=\"M480.0 40.0 L480.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M480.0 96.0 L480.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M480.0 156.0 L480.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"480.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4. desativar</text><path d=\"M590.0 40.0 L590.0 56.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M590.0 96.0 L590.0 116.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M590.0 156.0 L590.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"590.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5. apagar</text><text x=\"80.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1. só a antiga</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a todo momento a aplicação tem uma chave que funciona</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas chaves por usuário é o limite: o passo 5 abre espaço para a próxima rotação</text></svg>", "caption": "Os cinco passos no tempo. Apagar primeiro e criar depois deixaria um intervalo em que a aplicação não tem nada que funcione."}
```

## Segunda chave

```
ana@laptop:~/aws$ caio2=$(aws iam create-access-key --user-name caio)
ana@laptop:~/aws$ aws iam list-access-keys --user-name caio --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKKKVVGHFV	Active
AKIARZPUZDIKFRWREH5L	Active
ana@laptop:~/aws$ aws iam create-access-key --user-name caio

aws: [ERROR]: An error occurred (LimitExceeded) when calling the CreateAccessKey operation: Cannot exceed quota for AccessKeysPerUser: 2
```

**Dois é o limite, e a terceira requisição diz isso.** Uma chave que ninguém apagou depois da última
rotação bloqueia a próxima, o que é um alarme útil: quer dizer que a rotação anterior nunca terminou.

## Trocar

Reescreva o `booking.env` com a chave nova, que é o que publicar a configuração nova significa:

```sh
printf 'AWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n' \
  "$(echo "$caio2" | jq -r .AccessKey.AccessKeyId)" \
  "$(echo "$caio2" | jq -r .AccessKey.SecretAccessKey)" > booking/booking.env
```

Antes de apagar qualquer coisa, **prove que nada ainda usa a chave antiga**. Na AWS isso é uma espera
e uma leitura: desative-a, deixe um dia ou uma semana, e leia `get-access-key-last-used` para ela.
Uma data que para de andar, e nenhuma reclamação de ninguém, quer dizer que nenhum processo esquecido
depende dela. Desativar é a metade segura, porque pode ser desfeita. Confira que o arquivo agora tem o
id da chave nova, e então desative a antiga e teste-a:

```
ana@laptop:~/aws$ grep -c "$(echo "$caio2" | jq -r .AccessKey.AccessKeyId)" booking/booking.env
1
ana@laptop:~/aws$ aws iam update-access-key --user-name caio --access-key-id $(echo "$caio" | jq -r .AccessKey.AccessKeyId) --status Inactive
ana@laptop:~/aws$ with_key "$caio" aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/caio
```

**O moto ignorou a desativação**, como fez na aula 6: a chave inativa ainda assinou uma requisição que
deu certo. A AWS recusa requisições assinadas com chave inativa. Então, neste laboratório, a prova
tem de vir da exclusão.

## Apagar, e depois provar

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name caio --access-key-id $(echo "$caio" | jq -r .AccessKey.AccessKeyId)
ana@laptop:~/aws$ with_key "$caio" aws sts get-caller-identity --query Arn --output text

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
ana@laptop:~/aws$ aws iam detach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3
ana@laptop:~/aws$ with_key "$caio2" aws s3 ls
ana@laptop:~/aws$ aws iam list-access-keys --user-name caio --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKFRWREH5L	Active
```

A chave antiga é recusada com `InvalidClientTokenId`. A quarentena saiu assim que a chave exposta
deixou de existir, e a chave nova pode listar buckets de novo; a conta não tem nenhum, então a
resposta vem vazia em vez de recusada. Sobra uma chave, e é a que está no `booking.env`.

A quarentena foi retirada logo em seguida aqui para a transcrição ficar curta. Num incidente real, o
passo entre a exclusão e a retirada é a investigação: o que a chave exposta fez enquanto estava
solta, lido na trilha que a aula 15 monta. **Uma chave rotacionada depois de um vazamento é uma porta
fechada, não uma resposta sobre o que entrou por ela.**

## A rotação é um sintoma

Uma chave que precisa ser rotacionada a cada noventa dias é uma chave que existe. A tabela da seção
sobre os dois tipos tinha uma linha onde uma chave de acesso cabe; tudo acima dela ganha uma sessão de
papel que expira sozinha e nunca é rotacionada por ninguém. Quando uma revisão encontra a mesma chave
rotacionada quatro vezes por ano durante três anos, a descoberta não é que a rotação funciona, mas que
ninguém perguntou por que o programa não podia assumir um papel.
