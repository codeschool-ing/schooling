---
title: Três serviços e o bucket entre eles
version: 1
---

A imagem comum das ferramentas de entrega da AWS é um produto só, que pega o código e o põe em
produção. **São três, e eles não conversam diretamente entre si.** O CodePipeline sabe a ordem dos
passos e nada sobre construir ou implantar. O CodeBuild executa comandos num contêiner novo e não sabe
nada do que vem antes ou depois. O CodeDeploy move o tráfego de uma versão para a próxima, e é o
assunto da lição 3. O que os une é um bucket.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três caixas em fila: Origem, Build executado pelo CodeBuild e Deploy executado pelo ECS ou pelo CodeDeploy, sob uma faixa que diz que o CodePipeline sabe a ordem dos passos e não executa nenhum. Abaixo, um bucket de artefatos guarda src.zip e image.zip: a Origem grava src.zip, o Build o lê e grava image.zip, o Deploy lê image.zip. Ao lado do bucket, um registro de imagens, o ECR: setas tracejadas mostram o build enviando a imagem para ele e o deploy puxando-a.\"><defs><marker id=\"chn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"680\" height=\"32\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">O CodePipeline sabe a ordem dos passos e não executa nenhum</text><rect x=\"30\" y=\"76\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Origem</text><text x=\"115.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o commit, zipado</text><rect x=\"275\" y=\"76\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Build</text><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">CodeBuild</text><rect x=\"520\" y=\"76\" width=\"170\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Deploy</text><text x=\"605.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ECS / CodeDeploy</text><rect x=\"30\" y=\"180\" width=\"470\" height=\"76\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"44\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">bucket de artefatos</text><rect x=\"70\" y=\"212\" width=\"130\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src.zip</text><rect x=\"320\" y=\"212\" width=\"150\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">image.zip</text><path d=\"M115 140 L125 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><path d=\"M175 210 L300 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><path d=\"M390 140 L395 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><path d=\"M450 210 L560 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chn-ah)\"></path><rect x=\"540\" y=\"196\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">registro de imagens</text><text x=\"615.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ECR</text><path d=\"M430 140 L545 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#chn-ah)\"></path><path d=\"M640 194 L640 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#chn-ah)\"></path><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sólidas: os artefatos no bucket. Tracejadas: a imagem, enviada pelo build e puxada no deploy.</text></svg>", "caption": "Nada passa de um passo ao seguinte a não ser um zip no bucket. A imagem viaja à parte, pelo registro.", "same": ["Build", "Deploy"]}
```

## A esteira passa arquivos, não programas

Cada ação de uma esteira recebe **artefatos de entrada** e produz artefatos de saída, e um
artefato é um arquivo zip no bucket de artefatos da esteira. A ação de origem zipa o commit e o grava
lá como `src`. A ação de build recebe `src`, o CodeBuild o descompacta no seu contêiner, roda o build
e zipa o que o build declarou como saída em `image`. A ação de deploy recebe `image`. **Nada passa de
um passo ao seguinte a não ser o que foi gravado no bucket**, e isso tem duas consequências que as
pessoas descobrem tarde:

- um arquivo que o build produziu e não listou como artefato não existe para o passo de deploy, por
  mais tempo que o build tenha trabalhado nele;
- o bucket guarda cada versão de cada artefato de cada execução, e é o bucket que você limpa com uma
  regra de ciclo de vida, não a esteira.

Para um serviço de contêiner, o que o build passa adiante não é a imagem. A imagem vai para um
registro, o ECR da lição 2; o artefato é um arquivo pequeno que a nomeia, `imagedefinitions.json`,
que a ação de deploy lê para dizer ao ECS qual imagem rodar.

## Cada serviço age como um papel

Nenhum dos três age com as suas permissões. Cada um **assume um papel**: uma identidade na sua conta
cuja política de confiança nomeia o serviço que pode assumi-la, e cujas permissões dizem o que ele
pode fazer depois disso. A lição 9 de `aws-foundations` é sobre papéis; o que importa aqui é que uma
esteira envolve pelo menos dois deles, e que cada um é tão estreito quanto o seu passo.

| papel | confiado a | precisa, no mínimo |
|---|---|---|
| o da esteira | `codepipeline.amazonaws.com` | ler e gravar o bucket de artefatos, iniciar o build, iniciar o deploy |
| o do build | `codebuild.amazonaws.com` | ler e gravar o bucket de artefatos, gravar os próprios logs, enviar para um repositório |
| o do deploy | `codedeploy.amazonaws.com`, ou o ECS na ação do ECS | alterar um serviço, ler o balanceador dele |

Um papel que pode fazer tudo em todo lugar facilita montar a esteira e transforma o build, que
executa o que estiver no repositório, num jeito de qualquer pessoa que abra um pull request fazer
qualquer coisa na conta. **O papel do build é o que precisa ficar pequeno**, porque é ele que executa
código escrito por outra pessoa.

## Onde a cadeia começa

Uma esteira começa com uma mudança na sua origem. Para código no GitHub ou no GitLab, a ação de
origem lê o repositório por uma **conexão** (o serviço se chama CodeConnections) que alguém autoriza
uma vez no console; nas lições deste curso a origem é um objeto no S3, que não precisa de conta
externa nenhuma. O bucket precisa guardar versões, e uma regra no EventBridge inicia a esteira
sempre que uma nova versão do objeto é gravada.

Muitas equipes deixam o build e os testes no GitHub Actions ou no GitLab CI, que a lição 15 de `iac`
usa, e entregam à AWS só o deploy. A cadeia tem os mesmos três passos de qualquer jeito; o que muda é
quem tem o papel que pode alterar a produção, e essa é a pergunta a fazer a qualquer esteira.
