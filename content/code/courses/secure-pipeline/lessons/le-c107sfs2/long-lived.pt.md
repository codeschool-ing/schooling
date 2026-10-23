---
title: O que o pipeline guarda, e por quanto tempo
version: 1
---

O perigo de um segredo são dois números multiplicados: **quantas pessoas e processos conseguem
lê-lo, e por quanto tempo ele continua funcionando**. A aula 9 de `testing-cicd` tratou da primeira
metade do lado do serviço de CI: de onde um job tira um segredo, por que mascarar nos logs é uma
cortesia e não um controle, e por que um job deve ter só o que precisa. Esta aula trabalha nos dois
números de uma vez, no pipeline do próprio linkbox, e termina com um pipeline que não guarda
credencial nenhuma.

### O que o pipeline do linkbox guarda hoje

Dois estágios lidam com algo secreto. Uma busca nos scripts dos estágios acha os dois:

@@FENCE 1@@

Eles são opostos, e a diferença é o assunto desta aula.

**O token de staging em `ci/dast.sh` é de vida curta por construção.** A aula 4 fez a varredura
subir uma cópia de staging do serviço, e a aula 6 fez o serviço se recusar a subir sem
`LINKBOX_TOKEN`. O `dast.sh` responde com 18 bytes aleatórios de `/dev/urandom`, gerados no momento
em que o contêiner sobe. Ninguém nunca anota esse valor, e ele deixa de significar qualquer coisa
quando o contêiner de staging é removido no fim da varredura. Se um log o imprimisse, quem lesse
teria a chave de um serviço que já não existe.

**A senha da chave de assinatura em `~/ci/keys/password` é do outro tipo.** A aula 14 a criou com
`openssl rand` quando o servidor de CI ganhou a chave do cosign, e o `ci/sign.sh` a lê em toda
execução. São 33 bytes no disco do servidor de CI, ela funciona desde o dia em que foi criada e vai
continuar funcionando até alguém gerar um novo par de chaves, coisa que nada no curso tem motivo
para fazer.

### Quem consegue ler

A listagem diz que o arquivo pertence a `ana` e só ela pode lê-lo. Parece estreito até você lembrar
quem é `ana` nesta máquina. A aula 16 disse com todas as letras: o hook do servidor de CI roda como
`ana`, e roda o pipeline de **toda branch enviada**, a partir da cópia de `ci/` da própria branch. Uma
branch cujo `sign.sh` imprimisse a senha em vez de entregá-la ao cosign a colocaria no log daquela
execução, e nada no pipeline reclamaria, porque o pipeline que reclamaria é justamente o que a branch
acabou de mudar.

Então as respostas honestas sobre essa senha são: toda execução de toda branch consegue lê-la, e ela
funciona por tempo indeterminado. Um serviço de CI hospedado tem a mesma forma. Um segredo guardado
nas configurações de um repositório é entregue aos workflows que as configurações permitem, e
continua válido até alguém fazer a rotação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"sp-l17-lifetimes\" aria-label=\"Quatro credenciais do pipeline do linkbox numa linha do tempo. A senha da chave de assinatura em ~/ci/keys funciona desde o dia em que foi criada até alguém trocá-la, e toda execução de toda branch pode lê-la. O token de staging do dast.sh vive uma execução de staging. Um token do Vault e um token de identidade vivem cinco minutos cada e pertencem a uma execução.\"><defs><marker id=\"sp-l17-lifetimes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">por quanto tempo funciona</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem pode ler</text><rect x=\"110\" y=\"34\" width=\"120\" height=\"196\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"170\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma execução</text><text x=\"16\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a senha da chave</text><rect x=\"130\" y=\"50\" width=\"310\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M440 62 L482 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-lifetimes-ah-amber)\"></path><text x=\"285\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">da aula 14 até alguém trocar</text><rect x=\"515\" y=\"48\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">toda execução, toda branch</text><text x=\"16\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">token de staging</text><rect x=\"130\" y=\"96\" width=\"86\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"224\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma execução de staging</text><rect x=\"515\" y=\"94\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">aquela execução</text><text x=\"16\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">token do Vault</text><rect x=\"130\" y=\"142\" width=\"40\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 minutos</text><rect x=\"515\" y=\"140\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">aquela execução</text><text x=\"16\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">token de identidade</text><rect x=\"130\" y=\"188\" width=\"40\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 minutos</text><rect x=\"515\" y=\"186\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">aquela execução, só para o Vault</text></svg>", "caption": "A senha é a única sem fim. Tudo o que esta aula constrói serve para lhe dar um fim e para estreitar a coluna da direita."}
```

### Três perguntas, e as respostas que um arquivo dá

**Escopo mínimo são três estreitamentos, e um segredo num arquivo responde "tudo" aos três.**

| pergunta | a senha em `~/ci/keys` | onde esta aula termina |
|---|---|---|
| o que pode ser feito | tudo o que a chave faz, por quem tiver o arquivo | ler um caminho no Vault, mais nada |
| quem pode fazer | qualquer execução de qualquer branch | uma execução de `main` de `ana/linkbox` |
| por quanto tempo | até alguém trocar | cinco minutos, depois o token morre |

A ordem da aula segue a tabela. O Vault, um servidor cujo único trabalho é guardar segredos, tira a
senha do disco do servidor de CI. Uma policy do Vault estreita o **quê**, e o tempo de vida de um
token do Vault estreita o **por quanto tempo**. As duas coisas são montadas num contêiner na sua
máquina nas duas seções seguintes.

Sobra um problema, e é nele que a maioria dos times para. Alguma coisa precisa entregar ao pipeline
o token do Vault. Se a resposta for "um token guardado na configuração do servidor de CI", o segredo
andou um passo e continua de vida longa: perca esse token e quem o tiver lê todo segredo que a policy
dele permite. Isso às vezes se chama **o problema do segredo zero**: todo gerenciador de segredos
precisa de um primeiro segredo que o destranque.

### A saída do segredo zero

A resposta não é um lugar melhor para guardar o primeiro segredo. É deixar de precisar dele. **O
servidor de CI já sabe qual repositório e qual branch uma execução está construindo**, porque foi ele
que iniciou a execução. Se ele assinar essa afirmação, e o Vault confiar na assinatura do servidor de
CI, a execução prova quem é sem guardar nada durável: ela apresenta um token emitido para ela há um
instante, que expira minutos depois, e o Vault decide pelo que o token diz.

Isso é **identidade federada**, e é assim que GitHub Actions, GitLab CI e os outros serviços
hospedados chegam a nuvens e cofres sem chaves guardadas. A aula 9 de `testing-cicd` mostrou a troca
de fora. Aqui você constrói as duas pontas: uma CI que emite os tokens, e um Vault que os confere e
recusa os que deve recusar.

Nada disso substitui o que a aula 6 ensinou. Um segredo que vaza ainda precisa ser revogado, e a
senha acima continua sendo a que a aula 14 criou. O que muda é até onde um vazamento alcança, e por
quanto tempo.
