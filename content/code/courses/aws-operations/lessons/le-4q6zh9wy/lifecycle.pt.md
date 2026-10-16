---
title: Uma política de ciclo de vida, antes que a fatura cresça
version: 1
---

Cada build envia uma imagem, e nada apaga uma sozinho. Uma esteira que roda trinta vezes por dia útil
durante um ano deixa umas 6.600 imagens no repositório, e **quase todas nunca vão rodar de novo**. O
ECR cobra cada uma por gigabyte, então o repositório cresce até virar uma linha da fatura que ninguém
escolheu. A resposta é uma **política de ciclo de vida**: regras que expiram imagens, escritas uma vez
e aplicadas pelo ECR todo dia.

## Duas regras

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "untagged images go after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "keep the 30 newest dev builds",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["dev-"],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": { "type": "expire" }
    }
  ]
}
```

Cada regra **seleciona** imagens e expira o que selecionou. A primeira seleciona imagens sem tag,
que é o que uma tag mutável deixa para trás quando muda de lugar, e expira as enviadas há mais de sete
dias. A segunda seleciona imagens com uma tag começando por `dev-` e mantém as 30 mais novas,
expirando o resto. Imagens que nenhuma das regras seleciona, como `1.4.0` e as imagens com tag de
commit, nunca são tocadas.

`rulePriority` decide a ordem, a menor primeiro, e **uma imagem é julgada pela primeira regra que a
seleciona** e por nenhuma depois. Isso importa quando as regras se sobrepõem: uma imagem com as tags
`dev-17` e `1.4.0` é selecionada pela segunda regra e pode ser expirada por ela, mesmo que `1.4.0` seja
um release. Mantenha releases e builds de desenvolvimento em repositórios separados, ou com prefixos
que nenhuma regra compartilhe.

```
ana@laptop:~/aws/ecr$ aws ecr put-lifecycle-policy --repository-name shop/web --lifecycle-policy-text file://lifecycle.json --query repositoryName
"shop/web"
ana@laptop:~/aws/ecr$ aws ecr start-lifecycle-policy-preview --repository-name shop/web 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the StartLifecyclePolicyPreview operation (reached max retries: 2): <!doctype html>
```

O moto guarda a política e falha, com um erro interno, quando alguém pede uma **prévia**. No ECR a
prévia é o passo a dar antes de uma política entrar em vigor: `start-lifecycle-policy-preview` avalia
as regras contra as imagens que existem e lista o que seria expirado, sem expirar nada. Uma regra
escrita um pouco errada pode expirar a imagem em que a produção roda, e uma tarefa em execução
continua funcionando até reiniciar e descobrir que a imagem sumiu. **Essa prévia não foi executada
para este curso**, e é o único comando desta lição que nunca se deve pular num repositório real.

## Quanto economiza

O ECR guarda cada camada uma vez por repositório, então um build só custa as camadas que os
anteriores não tinham. Se cada build da loja acrescenta 40 MB delas (o código e as dependências que
mudaram; a imagem-base é compartilhada), 6.600 builds acrescentam uns 264 GB, cerca de 26 USD por mês
a dez centavos o gigabyte, e crescendo todo mês; com as duas regras acima o repositório guarda poucas
dezenas de imagens. O número é pequeno perto dos serviços que as rodam. **O que importa é o formato**:
um custo que cresce sozinho todo dia, a partir de um padrão que ninguém olhou, é o que a lição 23 vai
chamar de recurso ocioso.
