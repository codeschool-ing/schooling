---
title: Perguntando a todo bucket
version: 1
---

**Os quatro caminhos da segunda seção podem todos ser lidos pela API, e um deles só se prova
perguntando.** Um programa curto que lê a proteção, a política e as listas de acesso de todo bucket, e
depois pede todo objeto sem credenciais, acha toda exposição que esta aula mostrou. É a versão para
buckets do verificador de rede da aula 8, e tem o mesmo limite: diz onde algo está aberto, e só quem
conhece a clínica diz se deveria estar.

## O verificador

Salve isto como `public_buckets.py` em `~/aws`:

```schooling-example
{"language": "python", "file": "public_buckets.py", "parts": [{"code": "import json\nimport os\nimport urllib.error\nimport urllib.parse\nimport urllib.request\n\nimport boto3\n\ns3 = boto3.client(\"s3\")\nEVERYONE = {\"http://acs.amazonaws.com/groups/global/AllUsers\": \"everyone\",\n            \"http://acs.amazonaws.com/groups/global/AuthenticatedUsers\": \"every AWS account\"}\n", "note": "Só a biblioteca padrão e o boto3, que veio com o moto. Os dois URIs de grupo são os únicos destinatários de uma ACL que querem dizer alguém de fora da sua conta; os dois contam como público."}, {"code": "\n\ndef public_grants(acl):\n    return [f\"{EVERYONE[g['Grantee']['URI']]} may {g['Permission']}\"\n            for g in acl[\"Grants\"] if g[\"Grantee\"].get(\"URI\") in EVERYONE]\n", "note": "Transforma uma lista de acesso, de bucket ou de objeto, em frases. Uma concessão a uma pessoa ou a uma conta não tem URI e fica de fora."}, {"code": "\n\ndef anonymous_status(bucket, key):\n    endpoint = os.environ.get(\"AWS_ENDPOINT_URL\")\n    base = f\"{endpoint}/{bucket}\" if endpoint else f\"https://{bucket}.s3.amazonaws.com\"\n    try:\n        with urllib.request.urlopen(f\"{base}/{urllib.parse.quote(key)}\") as answer:\n            return answer.status\n    except urllib.error.HTTPError as refused:\n        return refused.code\n", "note": "A pergunta do estranho: um GET simples sem credenciais, contra o moto no laboratório e contra o endereço real do bucket fora dele. Faça-a só a buckets que são seus."}, {"code": "\n\nfor bucket in [b[\"Name\"] for b in s3.list_buckets()[\"Buckets\"]]:\n    findings = []\n    try:\n        block = s3.get_public_access_block(Bucket=bucket)[\"PublicAccessBlockConfiguration\"]\n        if not all(block.values()):\n            findings.append(\"Block Public Access is partly off\")\n    except s3.exceptions.ClientError:\n        findings.append(\"no Block Public Access\")\n", "note": "Primeiro a proteção. Um bucket sem configuração nenhuma responde com um erro, que aqui é um achado e não uma falha."}, {"code": "    try:\n        policy = json.loads(s3.get_bucket_policy(Bucket=bucket)[\"Policy\"])\n        for st in policy[\"Statement\"]:\n            if st[\"Effect\"] == \"Allow\" and st.get(\"Principal\") in (\"*\", {\"AWS\": \"*\"}):\n                findings.append(f\"policy allows {st['Action']} to everyone\")\n    except s3.exceptions.ClientError:\n        pass\n    findings += [\"bucket ACL: \" + g for g in public_grants(s3.get_bucket_acl(Bucket=bucket))]\n", "note": "Depois os dois documentos do bucket. Uma instrução de política com condição é apontada mesmo assim: a condição pode estreitá-la, e essa é uma leitura para uma pessoa. Não ter política também é um erro, e a resposta certa."}, {"code": "    for obj in s3.list_objects_v2(Bucket=bucket).get(\"Contents\", []):\n        key = obj[\"Key\"]\n        findings += [f\"{key} ACL: \" + g for g in public_grants(s3.get_object_acl(Bucket=bucket, Key=key))]\n        if anonymous_status(bucket, key) == 200:\n            findings.append(f\"{key} ANSWERS AN ANONYMOUS REQUEST\")\n    print(bucket)\n    for finding in findings or [\"nothing found\"]:\n        print(\"   \", finding)\n", "note": "Depois cada objeto, que é o caminho que uma revisão no nível do bucket perde. São duas requisições por objeto, e o `list_objects_v2` devolve no máximo mil chaves, que é tudo o que este laço lê; um bucket de milhões pede o S3 Inventory."}]}
```

**Leia a sonda anônima pelo que ela é.** Mandar uma requisição sem assinatura ao seu próprio bucket é
o mesmo teste que a aula 1 ensinou, feito para cada objeto. Não é ferramenta para o armazenamento de
outra pessoa, e não precisa de nada do armazenamento de ninguém: o programa só sonda os buckets que
as suas próprias credenciais listam.

## Rodando

Um terceiro bucket, com os prontuários que a clínica de fato precisa proteger, é montado do jeito que
todo bucket deveria ser, e está lá para o verificador ter algo que passe:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-records --key referrals/referral-0412.txt --body referral-0412.txt --query ETag --output text
"5b9687d0219a87fd262f5fe3c05e716f"
```

```
ana@laptop:~/aws$ python3 public_buckets.py
clinic-referrals
    referral-0412.txt ACL: everyone may READ
    referral-0412.txt ANSWERS AN ANONYMOUS REQUEST
clinic-reports
    no Block Public Access
    report-2026-09.csv ACL: every AWS account may READ
clinic-records
    nothing found
```

Três buckets, três histórias diferentes:

- **`clinic-records`** tem a proteção ligada e não concede nada a ninguém de fora da conta. *Nothing
  found* é a resposta que se quer, e vale vê-la uma vez, para confiar no verificador quando ele a
  dá;
- **`clinic-referrals`** tem as quatro chaves ligadas e ainda é apontado duas vezes: a ACL da carta
  diz `everyone may READ`, e a carta respondeu a uma requisição anônima. Na AWS, o
  `IgnorePublicAcls` teria feito essa requisição falhar, e só a linha da ACL sobraria, como uma
  concessão escrita e ignorada. O moto não aplica nenhum dos dois, então o laboratório mostra o pior
  caso;
- **`clinic-reports`** não tem proteção e tem uma concessão a toda conta AWS, e **não respondeu** à
  requisição anônima. Só a linha da ACL o pega. É por isso que o verificador lê as listas além de
  perguntar: uma sonda sem assinatura não enxerga a concessão que exige uma.
