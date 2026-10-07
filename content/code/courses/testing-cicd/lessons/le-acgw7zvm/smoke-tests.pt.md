---
title: O smoke test depois de cada deploy
version: 2
---

Um deploy que terminou não é um deploy que funcionou. Os arquivos podem estar no lugar e o processo
iniciado enquanto o programa não responde nada, responde na porta errada, ou responde como a versão
antiga porque o restart não aconteceu. Um **smoke test** é a verificação curta, rodada logo depois de
um deploy, contra o programa implantado, que faz as duas perguntas que importam primeiro: **está no
ar, e é a versão que pretendíamos?**

O smoke test do `shipquote` tem doze linhas de shell. Salve como `ops/smoke.sh`:

```sh
#!/usr/bin/env bash
# The smoke test: is the deployed program up, and is it the version we meant?
#   ops/smoke.sh http://127.0.0.1:8200 1.4.0
set -uo pipefail
url=$1 want=$2
health=$(curl -s --max-time 2 "$url/health") || { echo "smoke: $url does not answer"; exit 1; }
[ "$health" = '{"status": "ok"}' ] || { echo "smoke: /health said $health"; exit 1; }
version=$(curl -s --max-time 2 "$url/version")
case $version in
  *"\"version\": \"$want\""*) echo "smoke: $url is up and running $want" ;;
  *) echo "smoke: $url runs $version, expected $want"; exit 1 ;;
esac
```

Ele pergunta `/health` e espera `{"status": "ok"}`, depois pergunta `/version` e espera a versão que o
nome do artefato prometeu. Qualquer resposta errada, ou nenhuma resposta em dois segundos, e ele sai
com 1, então o deploy que o chamou falha.

O nome vem da eletrônica: ligue a placa nova e veja se sai fumaça. Não é uma suíte de testes, e não
deveria tentar ser. **Ele roda contra o ambiente de verdade**, com a configuração de verdade, que é a
única coisa que nenhum estágio anterior conseguiu testar.

## Um deploy que um smoke test barra

Eis um terceiro ambiente, `preview`, cuja configuração tem um erro de digitação que ninguém veria de
relance. Crie-o com `mkdir ~/envs/preview` e `echo SHIPQUOTE_PORT=84OO > ~/envs/preview/config.env`:

```
ana@laptop:~/shipquote$ cat ~/envs/preview/config.env
SHIPQUOTE_PORT=84OO
ana@laptop:~/shipquote$ ops/deploy.sh preview dist/shipquote-1.4.0.tar.gz; echo "exit status $?"
restart: preview did not answer on port 84OO
exit status 1
ana@laptop:~/shipquote$ tail -1 ~/envs/preview/app.log
ValueError: invalid literal for int() with base 10: '84OO'
```

A porta é `84OO`, com duas letras O maiúsculas. Os arquivos foram desempacotados e o processo
iniciado, e ele morreu na hora: o log termina com `ValueError: invalid literal for int() with base 10:
'84OO'`. O deploy esperou uma resposta naquela porta, não recebeu nenhuma, disse isso e **saiu com 1**.

Esse `ValueError` vem do `main()` em `app.py`, a função que a aula 4 seção 08 manteve na conta de
cobertura em vez de excluir, porque nenhum teste da suíte a roda. Esta é a verificação que a cobre:
**o smoke test é o teste do código que só roda numa implantação**, o ponto de entrada, a leitura da
configuração, a ligação a uma porta. Sem ele, este erro seria achado pelo primeiro cliente.

## O que mais cabe num smoke test

Mantenha-o curto, rápido e seguro de rodar contra a produção:

- as verificações de saúde e de versão acima;
- uma leitura real pelo caminho principal, como uma cotação para um CEP conhecido, que prova que o
  programa faz o trabalho dele e não só responde `/health`;
- **nada que grave dados** que um cliente possa ver, e nada que custe dinheiro, como uma chamada paga
  à transportadora.

O teste de aceitação da aula 1 seção 11, frete grátis a partir de R$ 199,00 em todas as regiões, é
um bom candidato a rodar contra a homologação depois do smoke test: é a promessa, conferida pelo
programa implantado.
