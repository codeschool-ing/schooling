---
title: Voltar ao release anterior
version: 1
---

Nem todo ambiente tem dois lados e um roteador. A produção da aula 7 é um diretório com um link
`current` e um link `previous`, e o `ops/rollback.sh` troca os dois:

```sh
[ -L "$root/previous" ] || { echo "rollback: $env has no previous release" >&2; exit 1; }
before=$(readlink "$root/previous")
ln -sfn "$(readlink "$root/current")" "$root/previous"
ln -sfn "$before" "$root/current"
"$(dirname "$0")/restart.sh" "$env"
set -a; . "$root/config.env"; set +a
"$(dirname "$0")/smoke.sh" "http://127.0.0.1:$SHIPQUOTE_PORT" "${before#releases/shipquote-}"
```

Aqui a produção acabou de receber o 1.6.0, com o 1.5.0 antes dele:

```
ana@laptop:~/shipquote$ readlink ~/envs/production/current ~/envs/production/previous
releases/shipquote-1.6.0
releases/shipquote-1.5.0
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990"; echo
{"error": "internal error"}
ana@laptop:~/shipquote$ time ops/rollback.sh production
smoke: http://127.0.0.1:8300 is up and running 1.5.0

real	0m1.941s
user	0m0.091s
sys	0m0.047s
ana@laptop:~/shipquote$ readlink ~/envs/production/current ~/envs/production/previous
releases/shipquote-1.5.0
releases/shipquote-1.6.0
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990"; echo
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
```

A cotação para Alagoas falha, o `rollback.sh` roda, e a mesma cotação dá certo. `current` e
`previous` trocaram de lugar, e o smoke test confirma a versão que agora responde.

## O que deixou rápido

1,94 segundo, e quase tudo foi o reinício, a lacuna do recreate da aula 10. Nada foi construído,
baixado ou desempacotado:

- **O release antigo ainda estava no disco**, em `releases/`, exatamente como foi implantado. Voltar
  foi apontar para ele, não reconstruí-lo.
- **Era o mesmo artefato** que já tinha rodado, com o mesmo checksum. Reconstruir o 1.5.0 a partir da
  tag daria um artefato novo que nunca rodou em lugar nenhum, e a aula 7 explicou por que isso é
  outra coisa.
- **A configuração não se mexeu.** O `config.env` é do ambiente, não do release, então voltar mudou
  o código e mais nada.

Uma equipe que volta revertendo um commit e esperando o pipeline construir e implantar o resultado
está indo para a frente, para um release novo que por acaso se parece com um antigo. Pode ser a
jogada certa, como a seção 07 explica, mas não é rápido, e durante um incidente rapidez é para o que
o rollback serve.
