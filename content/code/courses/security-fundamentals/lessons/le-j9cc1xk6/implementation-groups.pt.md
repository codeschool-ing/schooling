---
title: Grupos de implementação
version: 1
---

153 salvaguardas são demais para uma loja de nove pessoas fazer de uma vez, e muitas seriam esforço
desperdiçado ali. Então os CIS Controls classificam cada salvaguarda em **grupos de implementação**
(*implementation groups*, IGs), pelo tipo de organização que precisa dela:

```schooling-figure
{"svg": "<svg id=\"sf-implementation-groups\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Os grupos de implementação do CIS como conjuntos aninhados. IG1, a higiene cibernética essencial, 56 salvaguardas, dentro do IG2, 130 salvaguardas, dentro do IG3, todas as 153. A loja fica no IG1.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"172\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">IG3 · 153 salvaguardas</text><text x=\"36\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">especialistas em segurança, impacto público sério</text><rect x=\"60\" y=\"66\" width=\"520\" height=\"108\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">IG2 · 130 salvaguardas</text><text x=\"76\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">TI dedicada, dados mais sensíveis</text><rect x=\"100\" y=\"116\" width=\"320\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"116\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">IG1 · 56 salvaguardas</text><text x=\"116\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">higiene cibernética essencial: a loja</text></svg>", "caption": "Cada grupo contém o anterior. O IG1 é o piso de todo mundo."}
```

| grupo | para quem | salvaguardas (acumuladas) |
|---|---|---|
| **IG1** | organizações pequenas e médias com pouca experiência em TI e segurança, guardando sobretudo dados comuns de negócio | **56** |
| **IG2** | organizações com equipe de TI dedicada, vários departamentos, dados mais sensíveis ou deveres regulatórios | **130**: o IG1 mais 74 |
| **IG3** | organizações com especialistas em segurança, guardando dados ou operando serviços cujo comprometimento seria grave para o público | **153**: o IG2 mais 23 |

**O IG1 é descrito como higiene cibernética essencial**: o mínimo que toda organização deveria fazer,
qualquer que seja o tamanho. Os grupos são acumulativos, então uma organização IG2 faz tudo do IG1 e mais.

### A loja é IG1

Uma pequena livraria on-line com uma pessoa de TI e dados comuns de clientes é o caso típico de IG1. Isso
é boa notícia: 56 salvaguardas são uma lista que a ana consegue percorrer. Alguns exemplos do que o IG1
contém, e onde a loja já está:

| área de salvaguarda no IG1 | a loja |
|---|---|
| um inventário dos ativos da empresa | em parte: a lista de ativos da aula 2, ainda incompleta |
| processo de configuração segura | o checklist da próxima seção é o começo de um |
| desativar contas sem uso | o processo de saída da aula 6 |
| MFA para aplicações expostas e acesso remoto | o próximo passo do portal, aula 9 |
| backups automáticos, protegidos, com uma cópia isolada | aula 12 |
| treinamento de conscientização em segurança | ainda não |
| um processo de resposta a incidentes: quem chamar, como comunicar | ainda não |

As duas linhas de "ainda não" são o resultado honesto do exercício. Uma lista curta de IG1, percorrida
linha por linha, produz a lista de tarefas da loja numa tarde.

### Não é um ranking de organizações

Os grupos descrevem do que uma organização **precisa**, não quão boa ela é. Uma organização IG1 que faz
bem as 56 salvaguardas está numa posição muito melhor que uma IG3 que alega as 153 e faz metade. Subir de
grupo é uma decisão guiada pelo risco, como tudo neste curso: a loja vai para o IG2 quando começar a
guardar dados mais sensíveis ou contratar mais gente de TI, e não porque um grupo maior soa melhor.
