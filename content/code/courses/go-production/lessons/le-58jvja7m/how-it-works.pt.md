---
title: De onde vem a lista, e contra o que ela é conferida
version: 1
---

Todo módulo de que o seu programa depende foi escrito por outra pessoa, e alguns deles têm bugs que
um estranho consegue usar: um cabeçalho que deixa um parser ocupado por muito tempo, uma entrada que
derruba um servidor com panic. Quando um desses é achado e corrigido, ele fica registrado. **O
`govulncheck` lê esse registro e faz uma pergunta ao seu código: alguma vulnerabilidade conhecida
chega de fato a este programa?** A resposta é uma lista, um caminho de chamadas para cada item e um
status de saída com que um job de CI pode agir.

A ideia comum de um scanner de dependências é uma conferência de versões: ler o `go.mod`, comparar
cada versão com uma lista e marcar toda coincidência. Isso é metade do que o `govulncheck` faz. A
outra metade é o motivo de ele existir. **Um módulo numa versão vulnerável não é o mesmo que um
programa que executa o código vulnerável**, e em todas as varreduras desta lição a diferença é a maior
parte da lista.

## Instalando

O `govulncheck` é um programa Go, publicado no módulo `golang.org/x/vuln`, e se instala do jeito que a
lição 5 instalou ferramentas, em `~/go/bin`. Este curso fixa a v1.9.0:

```
ana@vm:~/langs$ go install golang.org/x/vuln/cmd/govulncheck@v1.9.0
ana@vm:~/langs$ govulncheck -version
Go: go1.27.1
Scanner: govulncheck@v1.9.0
DB: https://vuln.go.dev
```

O `go install` não imprimiu nada porque esta máquina já tinha baixado e compilado a ferramenta; na sua,
ele imprime antes algumas linhas `go: downloading`. **A primeira linha de `-version` não é o Go que
compilou o `govulncheck`: é o Go do seu `PATH`**, aquele cuja biblioteca padrão a varredura vai
julgar. A seção 05 usa isso. A última linha é o banco que ele lê por padrão.

## O banco de vulnerabilidades do Go

A lista fica em vuln.go.dev, e quem a mantém é a equipe de segurança do Go. Cada entrada tem um id no
formato `GO-2022-1059`, um ano e um número, e lista os nomes que o mesmo problema tem em outros
lugares: um número CVE e um alerta do GitHub, quando existem. As entradas são escritas em OSV, o
formato Open Source Vulnerability, que é JSON. Aqui está uma, cortada nos campos que importam agora:

```
ana@vm:~/langs$ jq '{id, aliases, summary, affected}' ~/vulndb/ID/GO-2022-1059.json
{
  "id": "GO-2022-1059",
  "aliases": [
    "CVE-2022-32149",
    "GHSA-69ch-w2m2-3vjp"
  ],
  "summary": "Denial of service via crafted Accept-Language header in golang.org/x/text/language",
  "affected": [
    {
      "package": {
        "name": "golang.org/x/text",
        "ecosystem": "Go"
      },
      "ranges": [
        {
          "type": "SEMVER",
          "events": [
            {
              "introduced": "0"
            },
            {
              "fixed": "0.3.8"
            }
          ]
        }
      ],
      "ecosystem_specific": {
        "imports": [
          {
            "path": "golang.org/x/text/language",
            "symbols": [
              "MatchStrings",
              "ParseAcceptLanguage"
            ]
          }
        ]
      }
    }
  ]
}
```

Leia de fora para dentro, porque **essa ordem são os três níveis em que o `govulncheck` trabalha**:

| nível | o campo | o que esta entrada diz |
|---|---|---|
| módulo | `package.name` e `ranges` | `golang.org/x/text`, toda versão desde a primeira (`"introduced": "0"`) até `0.3.8`, exclusive |
| pacote | `imports[].path` | só o pacote `golang.org/x/text/language` tem o bug |
| símbolo | `imports[].symbols` | e só duas funções dele, `MatchStrings` e `ParseAcceptLanguage` |

A lista `symbols` é a parte que uma pessoa escreve lendo a correção. É ela que transforma "você
depende de uma versão ruim" em "o seu programa chama a função que foi corrigida". É também por causa
dela que uma entrada contra o `net/http` da biblioteca padrão não condena todo programa compilado com
aquela versão do Go.

**Este laboratório não leu o vuln.go.dev**, porque esta máquina não consegue alcançá-lo. Toda
varredura desta lição lê uma cópia do mesmo banco em `~/vulndb`, entregue a ela com
`-db file:///home/ana/vulndb`. A cópia foi montada a partir das entradas que a equipe do Go publica
no repositório dela, como ele estava em 11 de outubro de 2026. Na sua máquina você deixa a flag de
fora, e um simples `govulncheck ./...` lê o vuln.go.dev. Espere contagens diferentes das que aparecem
aqui: o banco ganhou entradas desde então. O que o `govulncheck` manda para ele, segundo a
documentação, são os caminhos de módulos que o banco já lista, nunca o seu código nem qualquer outra
coisa sobre o seu programa.

## Alcance

Sabendo quais funções são ruins, o `govulncheck` monta um grafo de chamadas do seu programa: toda
função que pode chamar toda outra, a partir dos pontos de entrada do programa. Num pacote `main`,
esses são o `main` e as funções `init`; numa biblioteca, toda função e todo método exportados. **Uma
vulnerabilidade só conta contra o seu código quando algum caminho de chamadas a partir de um ponto de
entrada chega a uma função que a entrada cita.** Os dois programas da seção 03 importam o mesmo pacote
do mesmo módulo na mesma versão, e só um deles chega lá:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Dois programas e o módulo golang.org/x/text na v0.3.7. accept.main chama accept.preferred, que chama language.ParseAcceptLanguage, uma das duas funções citadas pela GO-2022-1059; o govulncheck relata isso no nível de símbolo e sai com status 3. tag.main chama language.Parse, no mesmo pacote, que a entrada não cita, então a vulnerabilidade fica só no nível de pacote e o status de saída é 0. Os pacotes secure/precis e unicode/norm trazem a GO-2026-6629 e a GO-2026-5970, e nenhum dos programas os importa: nível de módulo.\"><defs><marker id=\"vc-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"vc-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">seu código</text><rect x=\"25\" y=\"50\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">accept.main</text><rect x=\"25\" y=\"116\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">accept.preferred</text><rect x=\"25\" y=\"232\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tag.main</text><path d=\"M110 84 V112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vc-amber)\"></path><text x=\"110\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nível de símbolo: alcançado,</text><text x=\"110\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">status de saída 3</text><text x=\"110\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível de pacote: importado,</text><text x=\"110\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nunca chamado, status 0</text><rect x=\"260\" y=\"20\" width=\"440\" height=\"300\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">golang.org/x/text@v0.3.7</text><rect x=\"278\" y=\"56\" width=\"404\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"292\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">language</text><text x=\"668\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GO-2022-1059</text><rect x=\"296\" y=\"96\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ParseAcceptLanguage</text><rect x=\"488\" y=\"96\" width=\"176\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"576\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MatchStrings</text><rect x=\"296\" y=\"156\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Parse</text><rect x=\"278\" y=\"226\" width=\"196\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"376.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">secure/precis</text><text x=\"376.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GO-2026-6629</text><rect x=\"486\" y=\"226\" width=\"196\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"584.0\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">unicode/norm</text><text x=\"584.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">GO-2026-5970</text><text x=\"480\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível de módulo: exigido, nunca importado</text><path d=\"M195 133 C245 133 248 112 292 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vc-amber)\"></path><path d=\"M195 249 C248 249 250 172 292 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vc-phosphor)\"></path></svg>", "caption": "O mesmo módulo, o mesmo pacote, dois programas. O que decide o status de saída é se um caminho de chamadas a partir do main chega a uma função citada pela entrada."}
```

Cada achado fica no nível mais preciso que alcança. **O nível de símbolo é o único que reprova a
execução.** Os outros dois aparecem como contexto. Eles viram achados no dia em que alguém acrescenta
uma chamada, e um módulo que você exige é uma dependência quer você o chame, quer não.

O grafo é montado a partir do código-fonte, então ele tem arestas que um leitor não esperaria e deixa
de ver algumas que o programa tem. Uma chamada por uma interface ou por um valor de função é seguida
de forma conservadora, rumo a toda função que ela poderia alcançar, o que pode produzir um caminho que
nunca roda. Uma chamada feita por `reflect` é invisível, e também qualquer coisa alcançada por
`unsafe`. Esses são os limites documentados, e eles apontam na mesma direção: **um achado de símbolo
merece ser corrigido, e não discutido**, e um resultado limpo quer dizer nenhum caminho conhecido, o
que é uma afirmação forte e não uma prova.
