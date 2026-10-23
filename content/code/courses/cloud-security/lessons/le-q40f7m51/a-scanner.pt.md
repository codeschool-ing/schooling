---
title: Um scanner que se lê de uma vez
version: 1
---

**Um scanner de postura é um laço sobre a API com uma regra dentro.** O programa abaixo é um, curto o
bastante para ler inteiro: quatro regras, três serviços, uma região. Salve-o como `~/aws/scan.py`.
Nada precisa ser instalado, já que o boto3, a biblioteca da AWS para Python, veio com o moto para
`~/aws/venv`.

```schooling-example
{"language": "python", "file": "scan.py", "parts": [{"code": "import datetime\nimport json\nimport sys\n\nimport boto3\nfrom botocore.exceptions import ClientError\n\ns3 = boto3.client(\"s3\")\nec2 = boto3.client(\"ec2\")\niam = boto3.client(\"iam\")\nfindings = []\n\n", "note": "Três clientes, um por serviço que ele lê. O boto3 é a biblioteca da AWS para Python, instalada com o moto em `~/aws/venv`, e pega o endpoint, a região e a chave das mesmas variáveis que o `env.sh` define, então o programa fala com o moto sem nenhum endereço escrito nele."}, {"code": "accepted = {}\ntry:\n    for line in open(\"accepted.txt\"):\n        rule, resource, until, reason = line.split(maxsplit=3)\n        accepted[(rule, resource)] = (datetime.date.fromisoformat(until), reason.strip())\nexcept FileNotFoundError:\n    pass\n\n", "note": "As exceções que alguém decidiu, uma por linha: a regra, o recurso, o último dia em que a decisão vale e o porquê. Sem arquivo, sem exceções. A próxima seção escreve um."}, {"code": "for bucket in s3.list_buckets()[\"Buckets\"]:\n    name = bucket[\"Name\"]\n    try:\n        policy = json.loads(s3.get_bucket_policy(Bucket=name)[\"Policy\"])\n    except ClientError:\n        policy = {\"Statement\": []}\n    for st in policy[\"Statement\"]:\n        if st[\"Effect\"] == \"Allow\" and st.get(\"Principal\") in (\"*\", {\"AWS\": \"*\"}):\n            findings.append((\"public-bucket\", name, f\"{st['Action']} allowed to everybody\"))\n    try:\n        s3.get_bucket_encryption(Bucket=name)\n    except ClientError:\n        findings.append((\"unencrypted-bucket\", name, \"no default encryption\"))\n\n", "note": "Duas regras por bucket. Uma instrução de política que permite qualquer coisa a `\"*\"` o torna público, a falha da aula 9. Um bucket que responde `get-bucket-encryption` com erro não tem criptografia padrão, a da aula 11. Uma ACL também pode tornar um objeto público, e esta regra não lê ACLs: uma ferramenta de verdade lê."}, {"code": "for group in ec2.describe_security_groups()[\"SecurityGroups\"]:\n    for rule in group[\"IpPermissions\"]:\n        if not any(r[\"CidrIp\"] == \"0.0.0.0/0\" for r in rule.get(\"IpRanges\", [])):\n            continue\n        for port in (22, 3389):\n            if rule.get(\"FromPort\", 0) <= port <= rule.get(\"ToPort\", 65535):\n                findings.append((\"admin-port-open\", group[\"GroupId\"], f\"port {port} open to 0.0.0.0/0\"))\n\n", "note": "Uma regra aberta para `0.0.0.0/0` cuja faixa de portas cobre o SSH ou a área de trabalho remota do Windows. Uma regra para todos os protocolos não carrega porta nenhuma, então `FromPort` e `ToPort` ausentes viram a faixa inteira, e ela também é pega."}, {"code": "for user in iam.list_users()[\"Users\"]:\n    if not iam.list_mfa_devices(UserName=user[\"UserName\"])[\"MFADevices\"]:\n        findings.append((\"user-without-mfa\", user[\"UserName\"], \"no MFA device\"))\n\n", "note": "Todo usuário sem dispositivo de MFA registrado, a regra da aula 6. Um usuário de programa não tem segundo fator por desenho; a conta da clínica não tem nenhum desses, e uma regra de verdade separaria os dois."}, {"code": "still_open = 0\nfor rule, resource, detail in findings:\n    until, reason = accepted.get((rule, resource), (None, None))\n    if until and until >= datetime.date.today():\n        print(f\"accepted  {rule:19} {resource:21} until {until}: {reason}\")\n    else:\n        still_open += 1\n        print(f\"OPEN      {rule:19} {resource:21} {detail}\")\nprint(f\"{still_open} open, {len(findings) - still_open} accepted\")\nsys.exit(1 if still_open else 0)\n", "note": "Cada achado fica aberto, a menos que uma exceção o cubra e não tenha vencido; uma vencida volta a abrir sem ninguém precisar lembrar de reabrir. O código de saída é 1 enquanto houver algo aberto, e é isso que deixa a aula 14 pôr este programa num pipeline como porta."}]}
```

Rode-o contra a conta que a seção anterior montou:

```
ana@laptop:~/aws$ python3 scan.py; echo "exit $?"
OPEN      public-bucket       clinic-web            s3:GetObject allowed to everybody
OPEN      unencrypted-bucket  clinic-exports        no default encryption
OPEN      admin-port-open     sg-d877b106d3b8c910b  port 22 open to 0.0.0.0/0
OPEN      user-without-mfa    bia                   no MFA device
4 open, 0 accepted
exit 1
```

**Quatro achados, as quatro falhas, e nada mais.** O caio tem segundo fator e não aparece. O
`clinic-records` está cifrado e privado e não aparece. O security group padrão não tem regra aberta
para o mundo, então só o `booking-admin` aparece. E o código de saída diz o que uma pessoa teria de
ler na tela para saber: há algo aberto.

## O que as cinquenta e seis linhas deixam de fora

É aqui que um produto de verdade justifica o preço, e onde um scanner caseiro dá falsa tranquilidade
se você esquecer os limites dele:

- **Uma região.** Os clientes pegam `sa-east-1` do `env.sh` e não leem mais nada. A aula 1 achou uma
  rede padrão em cada uma das 38 regiões do moto; um security group aberto em `us-east-1` é invisível
  para este programa. Uma ferramenta de verdade pergunta a toda região que a conta tem habilitada.
- **Quatro regras.** O CIS AWS Foundations Benchmark tem dezenas, e um produto carrega centenas, uma
  para cada configuração de cada serviço que pode ser feita errada.
- **Uma conta.** A clínica tem uma. Uma empresa com uma organização de cinquenta contas precisa que o
  scanner assuma um papel em cada uma, o que a federação da aula 6 torna possível.
- **Sem ACLs, sem histórico.** A regra de bucket lê políticas e não listas de controle de acesso, e o
  programa não lembra nada entre uma execução e outra, então não consegue dizer quando uma falha
  apareceu.

Nada disso o torna inútil. Torna-o uma lista de regras que você consegue ler inteira, o que nenhum
produto é, e **cada regra nele é uma decisão que você sabe explicar**. Vale guardá-lo mesmo depois
que um produto chegar: quando uma ferramenta comercial e este programa discordarem, um dos dois tem
uma regra que você consegue conferir.
