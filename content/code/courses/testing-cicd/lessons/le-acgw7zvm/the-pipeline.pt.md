---
title: Os estágios de um pipeline de entrega
version: 1
---

Um pipeline de entrega é o pipeline de integração das aulas 5 e 6 com mais estágios depois dele. Os
estágios mudam de equipe para equipe; a **ordem** não, e é a ordem que faz o pipeline merecer
confiança:

1. **Montar** o artefato a partir do commit, uma vez.
2. **Testá-lo**: tudo o que as aulas 1 a 4 construíram, na matriz da aula 5.
3. **Implantar na homologação**, um ambiente feito para se parecer com a produção, e fazer um **smoke
   test** lá.
4. **Passar pela barreira**: a aprovação de uma pessoa, ou uma regra automática, ou as duas.
5. **Implantar o mesmo artefato na produção**, e fazer o smoke test lá também.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Cinco estágios em fila: build, teste, homologação com smoke test, a barreira, produção com smoke test. Uma linha tracejada embaixo diz que o mesmo artefato, montado uma vez, atravessa todos os estágios.\"><rect x=\"20\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build</text><rect x=\"160\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">teste</text><path d=\"M140 75 L154 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M153 71 L160 75 L153 79 z\" fill=\"var(--paper-dim)\"></path><rect x=\"300\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">homologação + smoke</text><path d=\"M280 75 L294 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M293 71 L300 75 L293 79 z\" fill=\"var(--paper-dim)\"></path><rect x=\"440\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">barreira</text><path d=\"M420 75 L434 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M433 71 L440 75 L433 79 z\" fill=\"var(--paper-dim)\"></path><rect x=\"580\" y=\"50\" width=\"120\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produção + smoke</text><path d=\"M560 75 L574 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></path><path d=\"M573 71 L580 75 L573 79 z\" fill=\"var(--paper-dim)\"></path><path d=\"M80 120 L80 140 L640 140 L640 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">um artefato, montado uma vez, sha256 conferido a cada deploy</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada estágio só começa se o anterior passou</text></svg>", "caption": "Um pipeline de entrega. O artefato avança e nunca é remontado, então o que chega à produção é o que passou por tudo antes.", "same": ["build"]}
```

Cada estágio só começa se o anterior passou, e cada um pega **o artefato do estágio anterior** em vez
de montar o seu. Então um deploy em produção é, por construção, o deploy de bytes que passaram por
todos os estágios anteriores. É isso que "promover" quer dizer: o artefato avança; nunca é remontado.

## Falhar rápido, de novo

A ordem também põe primeiro as falhas baratas e prováveis, pelo motivo que a aula 6 seção 07 deu
sobre passos. Um teste unitário falha em segundos na máquina de build. Uma configuração quebrada
falha na homologação, minutos depois, antes de qualquer usuário. **A produção deveria ser o estágio em
que nada novo se aprende**, só se confirma: o mesmo artefato, o mesmo comando de deploy, o mesmo smoke
test, outra configuração.

## O pipeline deste repositório

O workflow de release que publica este curso segue a mesma forma, como jobs:

| job | o que faz | de que precisa |
|---|---|---|
| `Tag` | recusa uma tag malformada, menor que o último release, ou fora da `main` | nada |
| `Checks` | roda o workflow de CI inteiro, chamado e não copiado | `Tag` |
| `Publish` | monta, pergunta ao binário a versão dele, cria o release | `Checks` |
| `Deploy` | envia as imagens e move o serviço para a revisão nova | `Publish` |

O job `Deploy` dele roda um de cada vez e nunca é cancelado no meio, o que a aula 6 seção 09 leu no
bloco `concurrency`. O que ele não tem é um ambiente de homologação: o repositório serve uma
plataforma pequena, e os autores decidiram que o risco dela não pede um. A aula 8 pergunta quando essa
decisão está certa.

## O que um pipeline produz

Uma execução de um pipeline de entrega deixa três coisas para trás: um artefato com um hash, um
registro de cada estágio por que passou, e uma implantação que diz a própria versão. Juntas elas
respondem a pergunta com que todo incidente começa, **o que mudou e quando**, sem ninguém precisar
lembrar.
