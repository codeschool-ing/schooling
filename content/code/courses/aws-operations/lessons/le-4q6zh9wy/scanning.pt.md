---
title: A varredura, e a barreira que a lê
version: 1
---

Uma imagem carrega os pacotes de um sistema operacional e as bibliotecas de uma linguagem, e alguns
deles têm vulnerabilidades publicadas. **O ECR pode olhar**, e faz isso de dois jeitos. A **varredura
básica** confere os pacotes do sistema operacional contra bases públicas de vulnerabilidades, quando
a imagem é enviada ou quando alguém pede, e não custa nada. A **varredura avançada** entrega o
repositório ao Amazon Inspector, que também lê os pacotes de linguagem (as wheels do Python, os
módulos do npm) e, mais importante, **varre de novo sempre que uma vulnerabilidade nova é
publicada**, então uma imagem limpa na segunda pode ter um achado na quinta sem ninguém enviar nada.

## Varrer, e ler o resultado

```
ana@laptop:~/aws/ecr$ aws ecr put-image-scanning-configuration --repository-name shop/api --image-scanning-configuration scanOnPush=true --query imageScanningConfiguration
{
    "scanOnPush": true
}
ana@laptop:~/aws/ecr$ aws ecr start-image-scan --repository-name shop/api --image-id imageTag=1.4.1 --query imageScanStatus
{
    "status": "IN_PROGRESS"
}
ana@laptop:~/aws/ecr$ aws ecr describe-image-scan-findings --repository-name shop/api --image-id imageTag=1.4.1 --query 'imageScanFindings.findings[].[name,severity,attributes[?key==`package_name`].value|[0]]' --output text
CVE-9999-9999	HIGH	moto_fake
```

`scanOnPush` faz cada push seguinte iniciar uma varredura sozinho; `start-image-scan` pede uma agora.
O achado merece um segundo olhar antes de qualquer coisa: `CVE-9999-9999`, num pacote chamado
`moto_fake`, na versão 9.9.9. **O moto devolve esse único achado inventado para toda imagem sobre a
qual perguntam.** Ele não lê a imagem, e não tem imagem nenhuma para ler. O que ele dá ao laboratório
é um achado com o formato de um real, que é tudo de que a próxima parte precisa.

## Uma barreira que recusa

Uma varredura que ninguém lê não protege nada. A versão útil é um passo na esteira, depois do push e
antes do deploy, que **falha a execução quando a imagem tem um achado acima de uma linha que a equipe
escolheu**. Esta recusa qualquer coisa crítica ou alta:

```sh
# scan-gate.sh REPOSITORY TAG: refuse an image with a critical or high finding
set -eu
repo=$1 tag=$2
aws ecr wait image-scan-complete --repository-name "$repo" --image-id imageTag="$tag"
counts=$(aws ecr describe-image-scan-findings --repository-name "$repo" \
  --image-id imageTag="$tag" --query imageScanFindings.findingSeverityCounts)
echo "findings: $counts"
blocking=$(echo "$counts" | jq '(.CRITICAL // 0) + (.HIGH // 0)')
if [ "$blocking" -gt 0 ]; then
  echo "refusing $repo:$tag: $blocking critical or high finding(s)"
  exit 1
fi
echo "$repo:$tag may be deployed"
```

`wait image-scan-complete` consulta até a varredura terminar, porque uma varredura leva tempo no ECR.
`findingSeverityCounts` é um pequeno objeto com contagens por severidade, então o script soma duas
delas, tratando uma severidade ausente como zero, e sai com status 1 quando a soma passa de zero. No
buildspec da lição 1 isso seria uma linha no `post_build`, depois do push: um `post_build` que falha
faz o build falhar, e o estágio de deploy nunca começa.

Contra o achado de mentira do moto:

```
ana@laptop:~/aws/ecr$ bash scan-gate.sh shop/api 1.4.1; echo "exit status $?"
findings: {
    "HIGH": 1
}
refusing shop/api:1.4.1: 1 critical or high finding(s)
exit status 1
```

**A barreira disparou com um achado que não existe**, que é o máximo que um laboratório consegue
mostrar: a lógica funciona, e a entrada é falsa. Numa imagem real o mesmo script lê contagens reais.

## Onde traçar a linha

Uma barreira que recusa todo achado de toda severidade bloqueia todo deploy em uma semana, porque uma
imagem-base sempre tem alguma coisa; aí a equipe desliga a barreira, e a proteção cai para zero. Três
hábitos mantêm a barreira ligada:

- **recusar crítico e alto**, e relatar médio e baixo em algum lugar que uma pessoa leia;
- **reconstruir regularmente sobre uma imagem-base nova**, porque a maioria dos achados é corrigida
  na origem, e uma imagem reconstruída a partir de `python:3.12-slim` nesta semana herda as correções;
- **permitir uma exceção nomeada, com data de fim**, quando um achado está num pacote que o serviço
  nunca chama, em vez de baixar a linha para todo mundo.

As novas varreduras contínuas da varredura avançada também significam que um achado pode chegar
numa imagem que já está rodando em produção. Esse achado vai para o Security Hub, que é a lição 19,
onde decidir o que corrigir primeiro é o assunto inteiro.

## Quanto custa

```
ana@laptop:~/aws/ecr$ python3 price.py AmazonECR data storage
AmazonECR, sa-east-1, published 2026-09-11
  SAE1-TimedStorage-ByteHrs                0.100000 USD per GB-Mo      $0.10 per GB-month of data storage
ana@laptop:~/aws/ecr$ python3 price.py AmazonInspectorV2 SAE1-container-image
AmazonInspectorV2, sa-east-1, published 2026-10-15
  SAE1-container-image-initial-scan        0.110000 USD per Resource-assessment $0.11 per Resource-assessment for container-image-initial-scan in South America (Sao Paulo)
  SAE1-container-image-initial-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-initial-scan-free-trial in South America (Sao Paulo)
  SAE1-container-image-re-scan             0.010000 USD per Resource-assessment $0.01 per Resource-assessment for container-image-re-scan in South America (Sao Paulo)
  SAE1-container-image-re-scan-free-trial     0.000000 USD per Resource-assessment $0.0 per Resource-assessment for container-image-re-scan-free-trial in South America (Sao Paulo)
```

O armazenamento custa dez centavos por gigabyte ao mês. A varredura avançada é cobrada pelo
Inspector: onze centavos pela primeira varredura de uma imagem e um centavo por nova varredura, então
um repositório que recebe 400 imagens por mês paga 44 USD em primeiras varreduras antes de qualquer
nova varredura. A lista também traz uma linha de período de teste gratuito, que vale para os
primeiros dias de uma conta com o Inspector e não é um preço.
