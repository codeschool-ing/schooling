---
title: Trocando uma chave sem parar o programa que a usa
version: 1
---

**A rotação é uma passagem entre duas chaves: criar a segunda, mudar o programa para ela, conferir
que a primeira ficou quieta, desligar a primeira, esperar, e só então apagá-la.** Todo passo pode
ser desfeito menos o último, e a ordem existe para que um erro apareça enquanto ainda pode ser
desfeito. Esta seção a executa de ponta a ponta no moto com o único dono legítimo de chave da loja,
`erp-sync`, o sistema de contabilidade do escritório que envia as vendas do dia para `shop-backups`.

## Um moto que julga

Datas de último uso e chaves recusadas só são registradas quando o moto verifica permissões, então
inicie-o como a lição 7 faz. No primeiro terminal, Ctrl+C, depois
`INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567`: o moto deixa três requisições passarem sem
verificação e julga toda requisição depois delas. Gaste as três num administrador. O `read` põe a
chave dele direto no ambiente, então o segredo nunca chega à tela:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ read -r AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY < <(aws iam create-access-key --user-name admin --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

A quarta requisição foi julgada, e passou. A lição 7 explica esse início por inteiro; daqui em
diante, todo comando neste terminal assina como `admin`.

## O dono da chave

O `erp-sync` pode pôr arquivos sob `erp/` num bucket e nada mais. Salve a política dele como
`~/aws/upload-erp.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::shop-backups/erp/*"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-backups
ana@laptop:~/aws$ aws iam create-user --user-name erp-sync --query User.Arn --output text
arn:aws:iam::123456789012:user/erp-sync
ana@laptop:~/aws$ aws iam put-user-policy --user-name erp-sync --policy-name upload-erp --policy-document file://upload-erp.json
ana@laptop:~/aws$ read -r OLD_ID OLD_SECRET < <(aws iam create-access-key --user-name erp-sync --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ echo $OLD_ID
AKIARZPUZDIKCZVHDNNE
```

**O id da chave é impresso e o segredo não.** No escritório, o segredo seria digitado uma vez nas
configurações do sistema de contabilidade e em nenhum outro lugar. Aqui as duas variáveis fazem o
papel desse sistema, que envia o arquivo com elas:

```
ana@laptop:~/aws$ printf 'order,total_cents\n1001,4990\n' > sales.csv
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload: ./sales.csv to s3://shop-backups/erp/sales.csv
```

## A rotação, passo a passo

**Crie a segunda chave**, enquanto a primeira continua funcionando:

```
ana@laptop:~/aws$ read -r NEW_ID NEW_SECRET < <(aws iam create-access-key --user-name erp-sync --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
ana@laptop:~/aws$ aws iam list-access-keys --user-name erp-sync --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKCZVHDNNE	Active
AKIARZPUZDIKCFJSZ6AR	Active
ana@laptop:~/aws$ aws iam create-access-key --user-name erp-sync --query AccessKey.AccessKeyId --output text

aws: [ERROR]: An error occurred (LimitExceeded) when calling the CreateAccessKey operation: Cannot exceed quota for AccessKeysPerUser: 2
```

**A terceira chave foi recusada**: duas por usuário, aplicado pelo moto como a AWS documenta. Esse
limite também é o motivo de a rotação precisar terminar. Um usuário que fica com duas chaves ativas
não tem vaga livre para a próxima rotação, e costuma ter uma cópia esquecida de uma delas em algum
lugar.

**Mude o programa, e depois confira que a chave antiga ficou quieta.** O sistema de contabilidade
recebe o par novo nas configurações, e o próximo envio o usa. O `get-access-key-last-used` diz
quando cada chave assinou uma requisição pela última vez, e para qual serviço:

```
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$NEW_ID AWS_SECRET_ACCESS_KEY=$NEW_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload: ./sales.csv to s3://shop-backups/erp/sales.csv
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id $OLD_ID --query "AccessKeyLastUsed.[LastUsedDate,ServiceName]" --output text
2026-10-16T16:37:39.082205+00:00	s3
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id $NEW_ID --query "AccessKeyLastUsed.[LastUsedDate,ServiceName]" --output text
2026-10-16T16:37:41.198810+00:00	s3
```

As duas chaves têm uma data e o serviço `s3`, porque as duas enviaram arquivos. A data é o campo a
observar: **quando a data da chave antiga para de mudar, nada mais a está usando.** Uma chave cuja
data continua mudando depois da troca tem um segundo usuário que ninguém conhecia, e achar esse
usuário é o motivo de a chave antiga ainda não ser apagada.

**Desligue a chave antiga.** `Inactive` recusa toda requisição assinada com ela, e é reversível: se
algo quebrar, `--status Active` traz a chave de volta num comando.

```
ana@laptop:~/aws$ aws iam update-access-key --user-name erp-sync --access-key-id $OLD_ID --status Inactive
ana@laptop:~/aws$ aws iam list-access-keys --user-name erp-sync --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKCZVHDNNE	Inactive
AKIARZPUZDIKCFJSZ6AR	Active
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload: ./sales.csv to s3://shop-backups/erp/sales.csv
```

**A chave antiga ainda enviou o arquivo, e isso é o moto, não a AWS.** O moto 5.2.3 registra o
status e continua aceitando a chave; a AWS recusa toda requisição assinada com uma chave inativa.
Então o laboratório não consegue mostrar a única coisa para a qual este passo serve, que é a falha
de quem ainda usava a chave, e uma rotação de verdade espera aqui. Uma semana cobre um programa que
roda todo dia; um mês cobre um que roda no fim do mês.

**Apague-a**, depois que a espera passou sem nada quebrar:

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name erp-sync --access-key-id $OLD_ID
ana@laptop:~/aws$ AWS_ACCESS_KEY_ID=$OLD_ID AWS_SECRET_ACCESS_KEY=$OLD_SECRET aws s3 cp --no-progress sales.csv s3://shop-backups/erp/sales.csv
upload failed: ./sales.csv to s3://shop-backups/erp/sales.csv An error occurred (InvalidAccessKeyId) when calling the PutObject operation: The AWS Access Key Id you provided does not exist in our records.
```

Agora o par antigo não nomeia nada, e o moto o recusa como a AWS recusaria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-rotation\" aria-label=\"A rotação da chave do erp-sync como uma linha do tempo de cinco passos: criar a segunda chave, mudar o programa para ela, conferir que a chave antiga ficou quieta, deixar a antiga inativa e, depois de uma espera, apagá-la. A chave antiga fica ativa até o quarto passo, inativa até o quinto, e some depois dele. A chave nova fica ativa do primeiro passo em diante. O programa assina com a chave antiga até o segundo passo e com a nova depois. Todo passo pode ser desfeito, menos a exclusão.\"><text x=\"190.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 criar</text><text x=\"190.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a segunda</text><path d=\"M190.0 56.0 L190.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"290.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2 mudar o</text><text x=\"290.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programa</text><path d=\"M290.0 56.0 L290.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"390.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">3 conferir</text><text x=\"390.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">último uso</text><path d=\"M390.0 56.0 L390.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"490.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4 antiga</text><text x=\"490.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inativa</text><path d=\"M490.0 56.0 L490.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"630.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5 apagar</text><text x=\"630.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a antiga</text><path d=\"M630.0 56.0 L630.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"560.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">espera</text><text x=\"20.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chave antiga</text><rect x=\"110.0\" y=\"76.0\" width=\"380.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Active</text><rect x=\"490.0\" y=\"76.0\" width=\"140.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Inactive</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">chave nova</text><rect x=\"190.0\" y=\"126.0\" width=\"510.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Active</text><text x=\"20.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o programa</text><rect x=\"110.0\" y=\"178.0\" width=\"180.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assina com a antiga</text><rect x=\"290.0\" y=\"178.0\" width=\"410.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assina com a nova</text><path d=\"M110.0 245.0 L626.0 245.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"368.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">todo passo até aqui pode ser desfeito</text><path d=\"M634.0 245.0 L700.0 245.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"667.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não pode</text><text x=\"360.0\" y=\"288.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">duas chaves ao mesmo tempo é o limite, por isso a antiga precisa sair</text></svg>", "caption": "A chave antiga é desligada antes de ser apagada, para que o que ainda a usava falhe enquanto a falha pode ser desfeita."}
```

## O relatório de credenciais

**O relatório de credenciais é um CSV com uma linha por usuário do IAM**, dizendo se cada um tem
senha, MFA e chaves, qual a idade das chaves e quando foram usadas pela última vez. Ele é gerado sob
pedido, e pedido de novo se tiver mais de quatro horas. O `get-credential-report` o devolve em
base64, então ele passa pelo `base64 -d`; o `cut` guarda cinco das suas vinte e duas colunas:

```
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
STARTED
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
COMPLETE
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,9,10,11,14
user,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_2_active
admin,true,2026-10-16T16:37:34+00:00,2026-10-16T16:37:48+00:00,false
erp-sync,true,2026-10-16T16:37:39+00:00,2026-10-16T16:37:41+00:00,false
```

A primeira vaga de chave do `erp-sync` agora guarda a chave nova, e a segunda está vazia, que é a
cara de uma rotação terminada. Na AWS o relatório tem também uma primeira linha para o usuário raiz
da conta, chamada `<root_account>`, e o do moto não tem nenhuma.

Ler idades a olho funciona para três usuários e não para trezentos. Este programa lê o relatório e
imprime cada chave ativa com a idade em dias. Salve-o como `~/aws/key-ages.py`:

```schooling-example
{"language": "python", "file": "key-ages.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Prints the age of every active access key in a credential report.\n\n    aws iam get-credential-report --query Content --output text | base64 -d | python3 key-ages.py\n\"\"\"\nimport csv\nimport sys\nfrom datetime import datetime, timezone\n\nLIMIT = 90\n\n", "note": "Só a biblioteca do próprio Python. `LIMIT` é a idade a partir da qual uma chave é sinalizada: 90 dias é a linha que o benchmark do CIS traça, e o controle `IAM.3` do AWS Security Hub confere o mesmo número."}, {"code": "now = datetime.now(timezone.utc)\nfor row in csv.DictReader(sys.stdin):\n    for n in ('1', '2'):\n        if row[f'access_key_{n}_active'] != 'true':\n            continue\n", "note": "A primeira linha do relatório nomeia as colunas, então cada linha é lida como um dicionário. Cada usuário tem duas vagas de chave, e uma vaga vazia ou inativa é pulada."}, {"code": "        rotated = datetime.fromisoformat(row[f'access_key_{n}_last_rotated'])\n        days = (now - rotated).days\n        used = row[f'access_key_{n}_last_used_date']\n        flag = 'ROTATE' if days > LIMIT else 'ok'\n        print(f\"{row['user']:<10} key {n} {days:>4} days  last used {used}  {flag}\")\n", "note": "`last_rotated` é quando a chave foi criada, então a distância até agora é a idade dela. A data de último uso sai ao lado: uma chave velha que nunca é usada é uma chave para apagar, não para trocar."}]}
```

```
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | python3 key-ages.py
admin      key 1    0 days  last used 2026-10-16T16:37:49+00:00  ok
erp-sync   key 1    0 days  last used 2026-10-16T16:37:41+00:00  ok
```

**Toda chave tem 0 dias**, porque o moto foi iniciado minutos atrás, e então nada é sinalizado; numa
conta que existe há anos, o mesmo programa imprime as chaves que ninguém toca desde que foram
criadas.
