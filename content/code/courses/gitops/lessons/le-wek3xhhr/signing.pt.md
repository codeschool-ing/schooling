---
title: Assinando uma imagem
version: 1
---

**Por padrão, o `cosign` assina para o mundo público.** Ele registra cada assinatura no Rekor, o log
público de transparência do Sigstore, e acrescenta um carimbo de tempo de uma autoridade pública, para
que qualquer pessoa confira depois quando a assinatura foi feita. Os dois são serviços na internet. A
assinatura de uma imagem no registry do seu laptop não tem lugar num log público, e o registry deste
laptop nem está na internet, então o `cosign` recebe a lista de serviços a usar numa **signing
config**: um arquivo que os enumera. Uma sem serviço nenhum é uma assinatura com a chave e mais nada:

```
ana@laptop:~/signing$ cosign signing-config create --out offline.json
ana@laptop:~/signing$ jq . offline.json
{
  "mediaType": "application/vnd.dev.sigstore.signingconfig.v0.2+json",
  "rekorTlogConfig": {},
  "tsaConfig": {}
}
```

Uma signing config com `rekorTlogConfig` e `tsaConfig` vazios: nenhum log onde registrar, nenhuma
autoridade para carimbar o tempo. O que sobra é a chave.

**Uma assinatura cobre um digest, nunca uma tag.** A aula 7 mostrou que uma tag se move; uma
assinatura sobre uma tag a seguiria para onde quer que ela apontasse depois. Então o digest de
`bulletin:1.2` é consultado primeiro, do mesmo jeito que na aula 7, e a imagem é assinada por ele:

```
ana@laptop:~/signing$ DIGEST=$(curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5001/v2/bulletin/manifests/1.2 | tr -d "\r" | awk "tolower(\$1) == \"docker-content-digest:\" { print \$2 }"); echo $DIGEST
sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18
ana@laptop:~/signing$ cosign sign --key cosign.key --signing-config offline.json -y localhost:5001/bulletin@$DIGEST
WARNING: Could not fetch trusted_root.json from the TUF repository. Continuing with individual targets. Error from TUF: error getting live trusted root: failed to create TUF client failed to load metadata: tuf refresh failed: Get "https://tuf-repo-cdn.sigstore.dev/15.root.json": Forbidden
Signing artifact...
Pushing signature to: localhost:5001/bulletin
ana@laptop:~/signing$ curl -s localhost:5001/v2/bulletin/tags/list | jq -c .tags
["1.0","1.1","1.2","sha256-55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18","stable"]
```

O `WARNING` é a máquina de gravação sem conseguir alcançar a raiz de confiança do Sigstore, que o
`cosign` tenta buscar em toda execução; com acesso à internet ele não aparece, e uma assinatura feita
com uma chave não precisa dela. O `-y` responde sim à pergunta que o `cosign` faz antes de assinar,
que é sobre o log público e não
se aplica aqui. A assinatura agora está no registry, como mais uma tag de `bulletin`, com o nome do
digest que ela assina: **quem consegue ler a imagem consegue achar a assinatura dela**, e o registry
não precisou de nada novo para guardá-la.

Num pipeline, isto é um passo depois do push, executado pelo CI com a chave tirada do cofre dele.
Ele assina o que acabou de ser construído, pelo digest que o push informou, e nunca por uma tag que
alguém poderia mover entre os dois passos.
