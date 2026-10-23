---
title: CVSS, EPSS e KEV, três respostas a três perguntas
version: 1
---

Três números viajam com os avisos, e muitas vezes são lidos como três versões de um número só,
"quão sério é". **Eles respondem a perguntas diferentes.** O CVSS diz quão grave é a falha se alguém
a explorar. O EPSS estima a chance de alguém tentar, em breve. O KEV diz que alguém já tentou e
conseguiu. Uma falha pode ser alta num e ausente nos outros, e as decisões que cada um apoia são
diferentes.

### CVSS: quão grave, em abstrato

O Common Vulnerability Scoring System, mantido pelo FIRST, descreve uma falha como um **vetor** de
propriedades e calcula uma nota de 0 a 10 a partir delas. A nota base descreve a falha em si, não a
sua implantação. A tabela do pip-audit não traz nota; o Trivy, que a próxima seção usa como segunda
opinião, traz. O relatório dele para a primeira falha de smuggling do gunicorn tem dois vetores:

```
ana@vm:~/linkbox$ trivy fs -q --scanners vuln -f json requirements.txt > /tmp/trivy.json
ana@vm:~/linkbox$ jq ".Results[].Vulnerabilities[] | select(.VulnerabilityID == \"CVE-2024-1135\") | {Severity, CVSS}" /tmp/trivy.json
{
  "Severity": "HIGH",
  "CVSS": {
    "ghsa": {
      "V3Vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:H/A:N",
      "V3Score": 8.2
    },
    "redhat": {
      "V3Vector": "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:H/A:N",
      "V3Score": 7.5
    }
  }
}
```

Leia o vetor um campo de cada vez. `AV:N`, alcançável pela rede. `AC:L`, sem condições especiais.
`PR:N`, sem conta nenhuma. `UI:N`, nenhum usuário precisa clicar em nada. `S:U`, o dano fica dentro do
componente. Depois o impacto em confidencialidade, integridade e disponibilidade: `H` alto, `L`
baixo, `N` nenhum.

**As duas fontes discordam**, e numa letra: os revisores do GitHub dão ao impacto em
confidencialidade `C:L`, e os da Red Hat dão `C:N`, então uma nota é 8.2 e a outra 7.5. Nenhuma está
errada. Cada uma pontuou a mesma descrição e julgou uma consequência de outro jeito. Esse é o estado
normal do CVSS, e é por isso que uma gravidade impressa por uma ferramenta diz qual fonte escolheu,
ou deveria dizer. As duas notas caem na faixa alta do CVSS, de 7.0 a 8.9, e o Trivy relata `HIGH`.

O que a nota base não sabe é tudo sobre você. Ela supõe que o código vulnerável é alcançado e está
exposto. A falha do Flask da seção anterior tem a mesma nota para o linkbox, que nunca toca na
sessão, e para um serviço construído em torno dela. O CVSS tem um grupo de métricas ambientais
justamente para esse ajuste, e quase ninguém o preenche.

### EPSS: qual a chance, em breve

O Exploit Prediction Scoring System, também do FIRST, dá a cada CVE uma **probabilidade**, entre 0 e
1, de que atividade de exploração contra ele seja observada nos próximos trinta dias. Ela sai de um
modelo treinado com o que de fato foi visto sendo explorado, e é republicada todo dia, então o
número de um CVE muda com o tempo. O FIRST a publica em `api.first.org`. A máquina deste curso não
alcança esse endereço, então **nenhum número de EPSS é citado nesta aula**; o que está dito aqui vem
da documentação do FIRST.

O EPSS responde à pergunta que o CVSS não faz. A maioria das falhas publicadas nunca é explorada, e
uma nota CVSS alta numa delas é uma afirmação sobre as consequências, não sobre as chances.

### KEV: já aconteceu

O catálogo Known Exploited Vulnerabilities, mantido pela CISA, a agência de cibersegurança dos
Estados Unidos, lista CVEs com **evidência confiável de exploração de verdade** e com remediação
disponível. É uma lista, não uma nota: um CVE está nela ou não está. Órgãos federais americanos
precisam corrigir o que está nela dentro de um prazo, e todo o resto do mundo pode usar a mesma lista
como o sinal mais forte que existe. A CISA a publica em JSON e mantém uma cópia num repositório no
GitHub:

```
ana@vm:~/linkbox$ curl -sSfo /tmp/kev.json https://raw.githubusercontent.com/cisagov/kev-data/main/known_exploited_vulnerabilities.json
ana@vm:~/linkbox$ jq -r ".catalogVersion, .count" /tmp/kev.json
2026.10.21
1754
ana@vm:~/linkbox$ jq -r ".vulnerabilities[].cveID" /tmp/kev.json | grep -cxFf /tmp/cves.txt
0
```

O catálogo de 21 de outubro de 2026 tem 1754 CVEs. O `grep -cxFf` conta as linhas do catálogo que
batem exatamente com uma linha de `/tmp/cves.txt`, os quinze CVEs do linkbox: **nenhum deles está
nele**.

### Três perguntas, lado a lado

| | pergunta | publicado por | muda | não diz |
|---|---|---|---|---|
| CVSS | quão grave, se explorada | as fontes do CVE: NVD, GitHub, fabricantes | raramente | se alguém vai tentar, nem se você está exposto |
| EPSS | qual a chance de exploração em 30 dias | FIRST | todo dia | quão grave, nem se você está exposto |
| KEV | ela já foi explorada | CISA | quando chega evidência | nada sobre um CVE que ainda não está nele |

**Nenhum dos três responde à pergunta da seção anterior**, se o linkbox alcança o código. Essa é
sua. Uma ordem razoável de atenção, quando há mais a corrigir que tempo: o que está no KEV primeiro,
seja qual for a nota; depois o alcançável e provável; depois o alcançável e grave; depois o resto, na
próxima atualização de rotina. A aula 7 escreve regras desse tipo no portão.

Para o linkbox a ordem pouco importa. Nada está no KEV, três achados são alcançáveis, todos têm
correção, e a correção é a última seção desta aula.
