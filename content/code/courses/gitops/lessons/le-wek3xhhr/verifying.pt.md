---
title: Verificando, e o que sai
version: 1
---

Verificar pede três coisas: a imagem, a chave pública e a decisão sobre o log de transparência.
**`--insecure-ignore-tlog=true` diz que não se espera entrada no log público**, o que vale para toda
assinatura deste curso e é a razão de a flag ter esse nome: numa assinatura que deveria estar no log,
pular essa checagem remove a prova de quando ela foi feita.

```
ana@laptop:~/signing$ cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin@$DIGEST | jq .
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5001/bulletin@sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
[
  {
    "critical": {
      "identity": {
        "docker-reference": "localhost:5001/bulletin@sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18"
      },
      "image": {
        "docker-manifest-digest": "sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18"
      },
      "type": "https://sigstore.dev/cosign/sign/v1"
    },
    "optional": {}
  }
]
```

Três coisas para ler. O `WARNING` é o `cosign` dizendo, com razão, que uma assinatura conferida sem
log não tem registro público de quando foi feita; nas assinaturas deste curso esse é o desenho, e na
de um projeto público seria motivo para parar. A lista de checagens é a que o `cosign` sempre
imprime. E o JSON é **o que foi de fato assinado**: um pequeno documento que nomeia o digest da
imagem, e é por isso que a assinatura não pode ser levada para outros bytes.

Verificar pela tag também funciona, e não é a checagem mais fraca que parece:

```
ana@laptop:~/signing$ cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin:1.2 > /dev/null
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5001/bulletin:1.2 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
```

O `cosign` resolve a tag para um digest primeiro e verifica esse digest. **O que ele prova é que o
digest para o qual a tag aponta agora foi assinado**, que é a pergunta que um deploy faz. Se a tag
for movida para uma imagem não assinada, a próxima verificação falha.
