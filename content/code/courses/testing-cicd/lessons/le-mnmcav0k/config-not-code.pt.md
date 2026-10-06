---
title: A configuração mora fora do código
version: 1
---

Se o artefato é o mesmo em todo ambiente, as diferenças precisam vir de outro lugar, e a resposta usual
é a popularizada pelo *The Twelve-Factor App*: **o programa lê a configuração do ambiente em que roda**,
como variáveis de ambiente, e o código não contém a configuração de nenhum ambiente. O `shipquote` lê
quatro:

| variável | o que decide | se ausente |
|---|---|---|
| `SHIPQUOTE_PORT` | a porta em que escuta | 8080 |
| `SHIPQUOTE_ENV` | o nome que informa em `/version` | `dev` |
| `SHIPQUOTE_CARRIER_URL` | a transportadora a que pergunta os preços | nenhuma: a tabela da própria loja |
| `SHIPQUOTE_CARRIER_TOKEN` | a chave que apresenta à transportadora | vazia |

O passo 10 do projeto, com a tag `v1.5.0`, acrescentou as duas variáveis da transportadora. Eis as
configurações dos três ambientes, com as linhas de token filtradas por enquanto, já que a aula 9 trata
delas:

```
ana@laptop:~/shipquote$ grep -v TOKEN ~/envs/*/config.env
/home/ana/envs/dev/config.env:SHIPQUOTE_PORT=8100
/home/ana/envs/production/config.env:SHIPQUOTE_PORT=8300
/home/ana/envs/production/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
/home/ana/envs/staging/config.env:SHIPQUOTE_PORT=8200
/home/ana/envs/staging/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091
```

O desenvolvimento só tem uma porta, então cota pela tabela. Homologação e produção nomeiam cada uma uma
transportadora. O **mesmo artefato** vai para os três, e cada um responde com a própria identidade:

```
ana@laptop:~/shipquote$ for env in dev staging production; do ops/deploy.sh $env dist/shipquote-1.5.0.tar.gz; done
smoke: http://127.0.0.1:8100 is up and running 1.5.0
smoke: http://127.0.0.1:8200 is up and running 1.5.0
smoke: http://127.0.0.1:8300 is up and running 1.5.0
ana@laptop:~/shipquote$ for port in 8100 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.5.0", "env": "dev", "carrier": "table"}
{"version": "1.5.0", "env": "staging", "carrier": "http://127.0.0.1:9091"}
{"version": "1.5.0", "env": "production", "carrier": "http://127.0.0.1:9092"}
```

Três smoke tests passaram, um por ambiente, e as três respostas de `/version` dizem a mesma versão,
três nomes de ambiente e três origens diferentes de preço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um artefato, shipquote-1.5.0.tar.gz, no topo, com linhas para três ambientes. dev na porta 8100 cota pela tabela e responde R$ 21,90. staging na porta 8200 consulta a transportadora em 9091 e responde R$ 18,60. production na porta 8300 consulta a transportadora em 9092 e responde R$ 18,60.\"><rect x=\"250\" y=\"16\" width=\"220\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shipquote-1.5.0.tar.gz</text><path d=\"M360 56 L125 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"30\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">dev</text><text x=\"44\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8100</text><text x=\"44\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preço vem de: a tabela</text><text x=\"44\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 21,90</text><path d=\"M360 56 L355 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"260\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">staging</text><text x=\"274\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8200</text><text x=\"274\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preço vem de: transportadora :9091</text><text x=\"274\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><path d=\"M360 56 L585 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"490\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">production</text><text x=\"504\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8300</text><text x=\"504\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preço vem de: transportadora :9092</text><text x=\"504\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os mesmos bytes em toda caixa; só a configuração muda</text><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a cotação é de 1,2 kg para São Paulo com um carrinho de R$ 50,00</text></svg>", "caption": "Os três deploys da seção 03 e as três respostas da seção 04 num desenho só. A diferença entre R$ 21,90 e R$ 18,60 é configuração, não código."}
```

## De onde vêm os valores na hora de rodar

O `restart.sh` lê o `config.env` para o ambiente do processo que inicia, então os valores vivem no
processo rodando e em lugar nenhum do release. No Linux isso é visível de fora:

```
ana@laptop:~/shipquote$ tr '\0' '\n' < /proc/$(cat ~/envs/production/pid)/environ | grep ^SHIPQUOTE_ | grep -v TOKEN
SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
SHIPQUOTE_ENV=production
SHIPQUOTE_PORT=8300
```

`/proc/<pid>/environ` guarda o ambiente com que um processo foi iniciado. O processo de produção vê a
porta, a transportadora e o nome dele, que o `restart.sh` define a partir do diretório. Esse arquivo é
legível pelo dono do processo e pelo root, o que importa para os tokens filtrados acima, e a aula 9
começa daí.

## O que não pertence à configuração

Configuração é para **o que difere entre ambientes**. Uma regra de negócio como o limite do frete
grátis é igual em todo lugar e pertence ao código, atrás de testes, como está em `quote.py`. Torná-la
uma variável "por flexibilidade" transformaria uma regra testada num valor sem teste que um ambiente
pode definir diferente do outro, e a seção 07 mostra como fica uma diferença assim quando ninguém
consegue vê-la.
