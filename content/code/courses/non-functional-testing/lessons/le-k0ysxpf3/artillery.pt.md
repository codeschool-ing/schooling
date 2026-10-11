---
title: Node.js, depois o Artillery
version: 1
---

Os dois últimos geradores de carga deste curso são menores que os quatro anteriores, e vale
conhecer cada um por uma coisa que faz bem. **O Artillery escreve o teste em YAML**, um arquivo de
configuração em vez de um programa, com JavaScript disponível quando o YAML não dá conta. **O
Vegeta faz uma coisa só, uma taxa constante de requisições**, pela linha de comando, e faz isso de
um jeito que os outros não fazem. Esta aula é um panorama dos dois, não um curso completo de
nenhum.

## Node.js

O Artillery é um programa Node.js, e o Node.js não está na base do Ubuntu na versão que o
Artillery quer, então ele vem do nodejs.org como um pacote e é descompactado sobre `/usr/local`:

```sh
cd ~
curl -fsSLO https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz
sudo tar -xJf node-v24.21.0-linux-x64.tar.xz -C /usr/local --strip-components=1
```

Num Mac com Apple silicon o pacote é `node-v24.21.0-linux-arm64.tar.xz`, nas duas linhas que o
citam. `--strip-components=1` tira a pasta de cima do pacote, então `bin/node` cai em
`/usr/local/bin`, que já está no `PATH`. As aulas 10 e 13 usam o mesmo Node.js.

## Artillery

```sh
sudo npm install -g artillery@2.0.34
```

**Instalar o Artillery também baixa um Chromium**, para um motor do Artillery que dirige páginas
de verdade pelo Playwright. Este curso nunca o usa, e a máquina das transcrições foi montada sem
esse download. De resto, as linhas acima foram rodadas como estão impressas quando a máquina foi
montada. Confira as três coisas:

```
ana@nft:~$ node --version; npm --version; artillery --version
v24.21.0
11.19.0

        ___         __  _ ____
  _____/   |  _____/ /_(_) / /__  _______  __ ___
 /____/ /| | / ___/ __/ / / / _ \/ ___/ / / /____/
/____/ ___ |/ /  / /_/ / / /  __/ /  / /_/ /____/
    /_/  |_/_/   \__/_/_/_/\___/_/   \__  /
                                    /____/


VERSION INFO:

Artillery: 2.0.34
Node.js:   v24.21.0
OS:        linux
```

## Um cenário

Crie uma pasta para ele e abra o arquivo com
`mkdir -p ~/artillery && nano ~/artillery/boxoffice.yml`. É a jornada das aulas 5 e 6 mais uma vez,
nas palavras do Artillery:

```schooling-example
{"language": "yaml", "file": "artillery/boxoffice.yml", "parts": [{"code": "# artillery/boxoffice.yml\nconfig:\n  target: http://127.0.0.1:8000", "note": "Um teste é um arquivo YAML em duas metades: `config`, que diz onde e quanto, e `scenarios`, que diz o que um visitante faz. `target` é o endereço base a que toda requisição do fluxo se refere."}, {"code": "  phases:\n    - name: warm up\n      duration: 5\n      arrivalRate: 1\n      rampTo: 3\n    - name: steady\n      duration: 15\n      arrivalRate: 3", "note": "As fases são um modelo aberto, escrito como chegadas: `arrivalRate` é quantos usuários virtuais novos chegam a cada segundo, e `rampTo` leva essa taxa de 1 a 3 nos 5 segundos da primeira fase. A segunda mantém 3 por segundo por 15 segundos. Como um usuário do Gatling, um usuário virtual do Artillery roda o cenário uma vez e vai embora."}, {"code": "  plugins:\n    ensure: {}\n  ensure:\n    thresholds:\n      - http.response_time.p95: 200\n    maxErrorRate: 1\n", "note": "`ensure` são os limites do Artillery. `http.response_time.p95: 200` reprova a execução se o percentil 95 de todas as respostas passar de 200 ms, e `maxErrorRate: 1` se mais de 1% dos usuários virtuais falhar. Um erro aqui é uma requisição que não recebeu resposta, como uma conexão recusada ou um timeout; um 409 é uma resposta, e conta como tal."}, {"code": "scenarios:\n  - name: look and book\n    flow:\n      - get:\n          url: \"/shows/{{ $randomNumber(981, 1000) }}\"\n          capture:\n            json: \"$.id\"\n            as: show\n      - think: 2", "note": "O fluxo é a jornada de um visitante. `$randomNumber(981, 1000)` sorteia um dos vinte espetáculos à venda, e `capture` lê o `id` da resposta JSON para uma variável chamada `show`, então a reserva pede o espetáculo que o visitante olhou. `think: 2` é o tempo de reflexão, dois segundos toda vez."}, {"code": "      - post:\n          url: /bookings\n          json:\n            show_id: \"{{ show }}\"\n            seat: \"{{ $randomNumber(1, 300) }}\"\n            customer: artillery", "note": "A reserva manda um corpo JSON montado com o espetáculo capturado e um assento sorteado. O template deixa os dois valores como texto, o que a bilheteria aceita, porque os converte com `int()`. Um assento já ocupado responde 409 e aparece em `http.codes.409` no relatório."}]}
```

**O YAML é o motivo para escolher o Artillery, e também o limite dele.** Um cenário como este é lido
por qualquer pessoa que leia um arquivo de configuração, inclusive gente que nunca abriria uma classe
Java. Quando a jornada precisa de lógica que o YAML não comporta, como um laço sobre uma lista ou
um corpo montado a partir de uma conta, o Artillery chama funções de um arquivo JavaScript citado em
`config.processor`, e o teste vira dois arquivos em duas linguagens.
