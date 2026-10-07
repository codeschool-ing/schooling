---
title: Versões, cache e plataformas
version: 2
---

**Uma versão é uma tag Git, e o pipeline a transforma nas tags da aula 16.** A Ana marca o commit e roda
o pipeline como a CI faria para aquela tag. Antes, ela esvazia o cache de build, para o build ter só o
que um runner de CI novo teria. Na sua máquina, a linha do pipeline é a mais curta que a seção
anterior deu, com `REF_NAME=v1.8.0` na frente:

```
ana@vm:~/shelf$ git tag v1.8.0
ana@vm:~/shelf$ docker builder prune -af | tail -1
Total:	2.277GB
ana@vm:~/shelf$ REF_NAME=v1.8.0 REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"
--- unit tests
--- integration tests
--- scan

Report Summary

┌─────────────────────────────┬──────────┬─────────────────┐
│           Target            │   Type   │ Vulnerabilities │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf-ci.tar (debian 12.15) │  debian  │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ probe                       │ gobinary │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf                       │ gobinary │        0        │
└─────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

--- build and push
pushed localhost:5000/shelf@sha256:5ff1336be28eeba819643a434850b2f86cd580d6f24c5b3981476d00d2cb2168
exit 0
ana@vm:~/shelf$ grep -cE "^#[0-9]+ CACHED" build.log
7
ana@vm:~/shelf$ curl -s localhost:5000/v2/shelf/tags/list | jq -c .tags
["1","1.8","1.8.0","buildcache","main","sha-cb7eee2"]
```

**`1.8.0`, `1.8` e `1` agora existem**, a partir do `case` do script, ao lado da tag do commit. O digest
não é o que o build da `main` enviou, embora o commit seja o mesmo: a versão é um argumento de build,
ela é compilada no binário, e bytes diferentes têm digest diferente.

## O cache mora no registry

**Sete passos voltaram `CACHED`, com o cache local esvaziado um instante antes.** Eles vieram do
`buildcache`, a imagem que a execução anterior escreveu com `--cache-to type=registry,…,mode=max`, lida
de volta com `--cache-from`. Um runner de CI costuma ser uma máquina nova sem cache próprio; sem isso,
toda execução baixa os módulos e compila tudo, como a aula 12 mediu. O `mode=max` guarda também as
camadas do estágio de build, e não só as da imagem final, que é onde estão os passos caros.

## Duas plataformas, uma tag

```
ana@vm:~/shelf$ docker buildx imagetools inspect localhost:5000/shelf:1.8.0 | grep -E "Platform"
  Platform:    linux/amd64
  Platform:    linux/arm64
  Platform:    unknown/unknown
  Platform:    unknown/unknown
ana@vm:~/shelf$ docker buildx imagetools inspect localhost:5000/shelf:1.8.0 --format "{{json .Provenance}}" | jq -c keys
["linux/amd64","linux/arm64"]
```

**Uma tag, duas imagens, `linux/amd64` e `linux/arm64`**, cada uma com as próprias atestações, as duas
entradas `unknown/unknown` da aula 20. Um servidor com processador ARM baixa o `shelf:1.8.0` e recebe a
imagem `arm64` sem pedir; nada num arquivo de deploy nomeia a arquitetura.

## O que o deploy recebe

A saída do workflow é o digest que o script imprimiu. Um job de deploy que o lê roda exatamente a
imagem que passou nos testes e na varredura, aconteça o que acontecer com a `1.8` ou a `main` depois.
É daí que a aula 27 parte: o que recebe esse digest e o mantém rodando.
