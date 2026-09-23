---
title: Checks numa máquina que não é de ninguém
version: 1
---

Clonar em `/tmp/fresh` funciona, e ninguém lembra de fazer toda vez. Então as equipes passam o trabalho
para uma máquina: **integração contínua**, ou CI. A cada pull request, um serviço cria uma máquina limpa,
clona o branch exatamente como foi enviado, roda os checks da equipe e marca no pull request um visto verde
ou um X vermelho.

O check do Bruno é um script de shell curto, e vale ler uma vez:

```schooling-example
{"language": "sh", "file": "check-links.sh", "parts": [{"code": "#!/bin/sh\n# Fail if any page links to a file that is not in the repository.\nstatus=0\n", "note": "O script começa supondo que está tudo bem. O status vira 1 no momento em que um link falta."}, {"code": "links=$(grep -oh '\\(src\\|href\\)=\"[^\":]*\"' *.html | cut -d'\"' -f2 | sort -u)\nfor f in $links; do\n", "note": "Todo src= e href= de toda página, sem as aspas e sem repetição. Endereços com dois-pontos, como https:, ficam de fora: apontam para fora do site."}, {"code": "  [ -e \"$f\" ] || { echo \"missing: $f\"; status=1; }\ndone\n", "note": "Se o arquivo não existe aqui, diz qual é e guarda a falha. Continua, para uma execução listar todos os arquivos que faltam."}, {"code": "exit $status\n", "note": "0 se tudo foi achado, 1 se algo não foi. Esse número é tudo o que a CI lê."}]}
```

No GitHub, as instruções da CI ficam no próprio repositório, como um arquivo em `.github/workflows/`. O GitLab
e o Bitbucket têm formatos próprios com as mesmas ideias:

```schooling-example
{"language": "yaml", "file": ".github/workflows/checks.yml", "parts": [{"code": "name: checks\n", "note": "O nome que a página do pull request mostra ao lado do resultado."}, {"code": "on: pull_request\n", "note": "Quando roda: toda vez que um pull request é aberto ou ganha um commit novo."}, {"code": "jobs:\n  links:\n    runs-on: ubuntu-latest\n", "note": "Uma máquina nova, criada para esta execução e jogada fora depois. Nada do notebook de ninguém está nela."}, {"code": "    steps:\n      - uses: actions/checkout@v5\n", "note": "Um clone do branch, exatamente como foi enviado. A imagem não rastreada não está nele, como não estava no /tmp/fresh."}, {"code": "      - run: ./check-links.sh\n", "note": "O check. Uma saída diferente de zero reprova a execução, e o pull request mostra um X vermelho em vez de um visto verde."}]}
```

Com esse arquivo no `main`, o primeiro push do `34-allergens` da Ana teria voltado com um X vermelho em um
minuto, e o log teria dito `missing: images/allergens.png`. Ninguém precisaria abrir o branch para descobrir.

## Fazendo valer

Um X vermelho que qualquer um pode ignorar acaba ignorado. Os **branches protegidos** da aula 8 fecham essa
brecha: o `main` pode ser configurado para recusar um merge até os checks indicados estarem verdes. Daí em
diante, *checks verdes numa máquina limpa* não é um hábito de que alguém lembra; é uma porteira por onde
nada passa.

## O que a CI não vê

A CI responde a perguntas que um script sabe responder: compila, os testes passam, os links existem. Ela não
sabe se a imagem de alergênicos tem o tamanho certo no celular, se o texto está claro para um cliente, ou se
a mudança faz o que quem escreveu o ticket realmente queria. Isso precisa de uma pessoa, e é aí que entra a
definição de pronto. O curso *Testes Automatizados e CI/CD* vai muito mais longe em escrever checks; por agora, a ideia
basta.
