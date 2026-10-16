---
title: Dois arquivos, perfis, e a ordem em que as configurações são lidas
version: 1
---

**A linha de comando da AWS lê as configurações de três lugares, e o mais próximo vence: uma opção
no comando, depois uma variável de ambiente, depois um perfil nos arquivos em `~/.aws`.** Um perfil
é um pacote de configurações com nome, então um laptop conversa com seis contas sem editar nada
entre um comando e outro. Toda lição até aqui viveu na camada do meio, as variáveis do `env.sh`;
esta lição abre a de baixo e mede como as três se empilham.

A imagem errada é que o `~/.aws/credentials` é onde a linha de comando é configurada. **Ele é um de
dois arquivos**, e o menor. Chaves vão em `credentials`; todo o resto, da região à role a assumir,
vai em `config`. Separá-los deixa a configuração ser compartilhada, copiada para um repositório ou
colada num chamado, enquanto os segredos ficam num arquivo que ninguém copia.

## Escrevendo um perfil com `aws configure set`

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. O `aws configure set` escreve uma configuração no arquivo certo, o que
evita um erro de digitação no formato. Crie um perfil chamado `lab` com as chaves de marcador do
moto, uma região e um formato de saída. Se o `~/.aws/config` da lição 11 ainda estiver lá, as linhas
novas são acrescentadas a ele:

```
ana@laptop:~/aws$ aws configure set aws_access_key_id test --profile lab
ana@laptop:~/aws$ aws configure set aws_secret_access_key test --profile lab
ana@laptop:~/aws$ aws configure set region us-east-1 --profile lab
ana@laptop:~/aws$ aws configure set output json --profile lab
ana@laptop:~/aws$ cat ~/.aws/credentials
[lab]
aws_access_key_id = test
aws_secret_access_key = test
ana@laptop:~/aws$ cat ~/.aws/config
[profile lab]
region = us-east-1
output = json
```

**O mesmo perfil tem um cabeçalho diferente em cada arquivo.** O `credentials` o chama de `[lab]`; o
`config` o chama de `[profile lab]`. A única exceção é o perfil padrão, que é `[default]` nos dois,
e que é usado quando nada nomeia outro. O arquivo da lição 11 mostrou um terceiro tipo de seção,
`[sso-session …]`, que não pertence a nenhum perfil e é compartilhado pelos que o nomeiam.

Nunca ponha uma chave real em nenhum dos dois arquivos à mão, e nunca cole uma vinda de uma
mensagem; as chaves aqui são marcadores do moto. O `aws configure get` lê uma configuração de volta,
e o `list-profiles` nomeia todo perfil que os dois arquivos definem:

```
ana@laptop:~/aws$ aws configure get region --profile lab
us-east-1
ana@laptop:~/aws$ aws configure list-profiles
lab
```

## A ordem, medida com a região

O perfil diz `us-east-1`. Peça a ele a primeira zona da sua região:

```
ana@laptop:~/aws$ aws ec2 describe-availability-zones --profile lab --query "AvailabilityZones[0].ZoneName" --output text
sa-east-1a
ana@laptop:~/aws$ env -u AWS_DEFAULT_REGION aws ec2 describe-availability-zones --profile lab --query "AvailabilityZones[0].ZoneName" --output text
us-east-1a
ana@laptop:~/aws$ aws ec2 describe-availability-zones --profile lab --region us-west-2 --query "AvailabilityZones[0].ZoneName" --output text
us-west-2a
```

**A primeira resposta é São Paulo, embora o perfil diga Virgínia**, porque o `env.sh` exporta
`AWS_DEFAULT_REGION=sa-east-1` e uma variável de ambiente vence um arquivo. Tirar a variável por um
comando com `env -u` deixa a região do perfil passar. E uma opção na linha de comando,
`--region us-west-2`, vence as duas. Três comandos, três camadas:

| camada | de onde veio a região | resposta |
|---|---|---|
| linha de comando | `--region us-west-2` | `us-west-2a` |
| ambiente | `AWS_DEFAULT_REGION` no `env.sh` | `sa-east-1a` |
| perfil | `region = us-east-1` no `~/.aws/config` | `us-east-1a` |

A região tem duas variáveis, e `AWS_REGION` vence `AWS_DEFAULT_REGION` quando as duas existem; o
`aws configure list` nomeia as duas na coluna `LOCATION`. As mesmas três camadas valem para o
formato de saída (`--output`, `AWS_DEFAULT_OUTPUT`, `output =`), para o endpoint (`--endpoint-url`,
`AWS_ENDPOINT_URL`, `endpoint_url =`) e para o próprio perfil (`--profile`, `AWS_PROFILE`).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l25-layers\" aria-label=\"Os três lugares de onde a linha de comando da AWS lê uma configuração, o mais próximo primeiro. Primeiro o próprio comando: opções como --region, --profile e --output. Depois o ambiente: AWS_REGION, AWS_DEFAULT_REGION, AWS_PROFILE e as variáveis de chave. Por último os dois arquivos, ~/.aws/config e ~/.aws/credentials. A região medida na lição veio de cada camada por vez: us-west-2a com a opção, sa-east-1a do env.sh, us-east-1a do perfil. Para credenciais, o --profile tira do caminho as chaves do ambiente, e o AWS_PROFILE não.\"><defs><marker id=\"l25-layers-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"610.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a região, medida</text><rect x=\"80.0\" y=\"40.0\" width=\"440.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1  o comando</text><text x=\"100.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--region  --profile  --output</text><rect x=\"560.0\" y=\"52.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-west-2a</text><path d=\"M522.0 70.0 L558.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"120.0\" width=\"440.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2  o ambiente</text><text x=\"100.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AWS_DEFAULT_REGION  AWS_PROFILE  AWS_ACCESS_KEY_ID</text><rect x=\"560.0\" y=\"132.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1a</text><path d=\"M522.0 150.0 L558.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"200.0\" width=\"440.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"218.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3  os arquivos</text><text x=\"100.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">~/.aws/config  ~/.aws/credentials</text><rect x=\"560.0\" y=\"212.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">us-east-1a</text><path d=\"M522.0 230.0 L558.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 44.0 L40.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l25-layers-af-ah-phosphor)\"></path><text x=\"40.0\" y=\"281.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o primeiro</text><text x=\"40.0\" y=\"294.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">achado vence</text><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">credenciais: --profile pula as chaves do ambiente; AWS_PROFILE não</text></svg>", "caption": "O mais próximo vence: o comando, depois o ambiente, depois os arquivos, com uma exceção para chaves."}
```

**As credenciais seguem a mesma regra com uma exceção**, e a exceção é o motivo de este laboratório
funcionar. A próxima seção a mede.
