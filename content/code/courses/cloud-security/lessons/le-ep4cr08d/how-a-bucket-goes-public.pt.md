---
title: Quatro jeitos de um bucket responder a todo mundo
version: 1
---

**Um objeto do S3 fica legível por um estranho quando qualquer uma de quatro concessões diz isso:
uma política de bucket, uma ACL de bucket, uma ACL de objeto, ou uma concessão a "qualquer usuário
autenticado da AWS", que é quase a mesma coisa.** Uma revisão que lê só a política de bucket perde
três delas, e a ACL de objeto é a mais esquecida, porque é definida arquivo por arquivo e nunca
aparece no bucket.

A imagem errada é a de que um bucket é público ou privado, como uma chave só. Ele é um bucket com uma
política e uma lista de acesso, guardando objetos que têm, cada um, uma lista de acesso própria.
**Público é uma propriedade de uma requisição ser respondida**, e pode valer para um objeto e não para
o vizinho dele no mesmo bucket.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l09-paths\" aria-label=\"Quatro concessões tornam um objeto do S3 legível por alguém de fora da conta, e cada uma mora num lugar diferente. No bucket: uma política de bucket cujo principal é uma estrela, que responde a todos, e uma ACL de bucket concedendo READ a AllUsers, que deixa todos listarem as chaves. Em cada objeto: uma ACL de objeto concedendo READ a AllUsers, que responde a todos, e uma ACL de objeto concedendo READ a AuthenticatedUsers, que responde a qualquer um com conta na AWS. Acima das quatro fica o Block Public Access, que recusa concessões públicas novas e ignora as existentes.\"><defs><marker id=\"l09-paths-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30.0\" y=\"16.0\" width=\"660.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Block Public Access, acima de toda concessão</text><text x=\"360.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusa concessões públicas novas e ignora as já escritas</text><rect x=\"30.0\" y=\"84.0\" width=\"660.0\" height=\"262.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"46.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">o bucket</text><text x=\"470.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">a quem responde</text><rect x=\"46.0\" y=\"222.0\" width=\"400.0\" height=\"112.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">cada objeto, por conta própria</text><circle cx=\"70.0\" cy=\"130.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1</text><text x=\"90.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">política de bucket</text><text x=\"90.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Principal: &quot;*&quot;</text><path d=\"M400.0 130.0 L462.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todos</text><circle cx=\"70.0\" cy=\"178.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">2</text><text x=\"90.0\" y=\"171.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ACL do bucket</text><text x=\"90.0\" y=\"187.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllUsers READ</text><path d=\"M400.0 178.0 L462.0 178.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todos, como lista de chaves</text><circle cx=\"70.0\" cy=\"262.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"262.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">3</text><text x=\"90.0\" y=\"255.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ACL do objeto</text><text x=\"90.0\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllUsers READ</text><path d=\"M400.0 262.0 L462.0 262.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todos</text><circle cx=\"70.0\" cy=\"310.0\" r=\"10\" fill=\"var(--amber)\"></circle><text x=\"70.0\" y=\"310.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">4</text><text x=\"90.0\" y=\"303.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ACL do objeto</text><text x=\"90.0\" y=\"319.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AuthenticatedUsers READ</text><path d=\"M400.0 310.0 L462.0 310.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-paths-af-ah-amber)\"></path><text x=\"470.0\" y=\"310.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">qualquer um com conta na AWS</text></svg>", "caption": "Uma revisão que lê só a política de bucket vê o caminho 1. Os caminhos 3 e 4 são definidos arquivo por arquivo e nunca aparecem no bucket, e o caminho 4 recusa o teste anônimo que o pegaria."}
```

## A política, que a aula 1 mostrou

`"Principal": "*"` com `s3:GetObject` em `bucket/*` tornou todo objeto legível de uma vez. É o
caminho que a maioria dos relatos descreve e o mais fácil de ver, já que a política é um documento
por bucket. Não se repete aqui.

## Uma ACL de objeto

As ACLs são mais antigas que as políticas de bucket: uma lista curta de concessões presa ao bucket e
a cada objeto, dos primeiros anos do S3. Inicie o moto no primeiro terminal, vazio, e leia o `env.sh`
nos dois. A clínica manda cartas de encaminhamento a hospitais parceiros por um bucket, e o caio
escreveu o envio para que o hospital abrisse o link sem fazer login. Crie uma carta:

```sh
cat > referral-0412.txt <<'EOF'
Referral 0412 — 2026-10-21
Patient: Maria Souza, born 1984-03-02
To: Hospital Central, cardiology
Reason: abnormal ECG at routine visit
EOF
```

Envie-a do jeito que o código do caio envia, e peça-a como um estranho, com o `curl`:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-referrals --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-referrals
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-referrals --key referral-0412.txt --body referral-0412.txt --acl public-read --query ETag --output text
"5b9687d0219a87fd262f5fe3c05e716f"
ana@laptop:~/aws$ curl -s -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt
Referral 0412 — 2026-10-21
Patient: Maria Souza, born 1984-03-02
To: Hospital Central, cardiology
Reason: abnormal ECG at routine visit
200
```

**O bucket não tem política nenhuma, e a carta é pública.** O `--acl public-read` no envio deu ao
objeto uma concessão a um grupo que a AWS chama de `AllUsers`, que é todo mundo na internet,
autenticado ou não. Leia a lista de acesso do objeto:

```
ana@laptop:~/aws$ aws s3api get-object-acl --bucket clinic-referrals --key referral-0412.txt --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket clinic-referrals

aws: [ERROR]: An error occurred (NoSuchBucketPolicy) when calling the GetBucketPolicy operation: The bucket policy does not exist
```

A primeira concessão, sem URI, é o `FULL_CONTROL` do dono. A segunda é a exposição. Nada no
`get-bucket-policy` nem na ACL do próprio bucket a teria mostrado, já que ela mora neste arquivo só.

## Uma ACL de bucket

A mesma concessão no bucket dá a todos `READ` no próprio bucket, o que para um bucket quer dizer
**listar as chaves**: não o conteúdo, mas o nome de cada arquivo, o que para cartas de encaminhamento
é uma lista de casos de pacientes.

```
ana@laptop:~/aws$ aws s3api put-bucket-acl --bucket clinic-referrals --acl public-read
ana@laptop:~/aws$ aws s3api get-bucket-acl --bucket clinic-referrals --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
```

A listagem em si não aparece aqui, e o motivo é do moto: ele responde a uma listagem anônima de
qualquer bucket, mesmo privado, onde a AWS recusa. Uma transcrição dela não provaria nada sobre a
concessão. A concessão em si, `AllUsers` com `READ`, é o que uma revisão procura.

## Qualquer usuário autenticado da AWS

A quarta concessão parece uma restrição e não é. O `authenticated-read` dá `READ` ao grupo
`AuthenticatedUsers`, e a documentação da AWS é explícita sobre o que esse grupo é: **qualquer pessoa
com uma conta AWS, em qualquer organização do mundo**, e não os usuários da sua. O relatório mensal
da bia vai para um segundo bucket desse jeito:

```sh
cat > report-2026-09.csv <<'EOF'
month,appointments,no_shows,new_patients
2026-09,1184,97,212
EOF
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-reports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-reports
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-reports --key report-2026-09.csv --body report-2026-09.csv --acl authenticated-read --query ETag --output text
"866b00c18f749ee66eef30bd0b8dd3d6"
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-reports/report-2026-09.csv
403
ana@laptop:~/aws$ aws s3api get-object-acl --bucket clinic-reports --key report-2026-09.csv --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AuthenticatedUsers	READ
```

**Uma requisição anônima é recusada, e é exatamente isso que torna esta concessão perigosa.** O `403`
é o que vê quem a testa com `curl`, e conclui que está privada. Quem assina a mesma requisição com uma
chave da própria conta AWS é respondido. O moto, com a verificação desligada, aceita qualquer
requisição assinada, então o laboratório não consegue mostrar a diferença entre a sua chave e a de um
estranho, e a afirmação se apoia na documentação da AWS.

Limpe a ACL do bucket antes de seguir, para que as próximas seções comecem das concessões dos
objetos:

```
ana@laptop:~/aws$ aws s3api put-bucket-acl --bucket clinic-referrals --acl private
ana@laptop:~/aws$ aws s3api get-bucket-acl --bucket clinic-referrals --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
```
