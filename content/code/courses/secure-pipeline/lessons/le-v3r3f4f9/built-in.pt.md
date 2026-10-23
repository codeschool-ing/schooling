---
title: As checagens embutidas do Trivy ao lado das suas
version: 1
---

Você não precisava escrever nada disso do zero. O Trivy, que este curso usa desde a aula 8 para
imagens, traz uma biblioteca de checagens de configuração para Dockerfiles, manifestos de Kubernetes,
Terraform, CloudFormation e mais, e o `trivy config` as roda. Elas também são escritas em Rego, a
mesma linguagem da sua política. **Então a pergunta não é qual ferramenta, e sim de quem são as
regras**: uma biblioteca escrita por pessoas que nunca viram o seu projeto, ou um punhado escrito por
quem tomou as decisões dele.

### As checagens embutidas no linkbox, depois da correção

```
ana@vm:~/linkbox$ trivy config --quiet --format json . | jq -r '.Results[] | .Target as $t | .Misconfigurations[]? | "\($t)  \(.ID) \(.Severity) \(.Title)"'
Dockerfile  DS-0026 LOW No HEALTHCHECK defined
k8s/linkbox.yaml  KSV-0011 LOW CPU not limited
k8s/linkbox.yaml  KSV-0020 LOW Runs with UID <= 10000
k8s/linkbox.yaml  KSV-0021 LOW Runs with GID <= 10000
k8s/linkbox.yaml  KSV-0125 MEDIUM Restrict container images to trusted registries
```

Cinco achados em dois arquivos. Vale ler cada um contra o que este projeto já decidiu, porque essa
comparação é o que separa usar bem uma biblioteca embutida de usá-la mal:

| checagem | o que ela diz | contra as decisões deste projeto |
|---|---|---|
| DS-0026 | não há HEALTHCHECK no Dockerfile | o Kubernetes ignora o HEALTHCHECK de um Dockerfile e usa as próprias probes, então neste deploy a linha não faria nada. Uma decisão, não um esquecimento |
| KSV-0011 | sem limite de CPU | o manifesto da aula 10 tem um request de CPU e um limite de memória, e nenhum limite de CPU: um limite de CPU estrangula um processo mesmo com núcleos ociosos. Uma escolha com argumento |
| KSV-0020, KSV-0021 | o manifesto não define `runAsUser` nem `runAsGroup` acima de 10000 | a imagem roda como 65532, que é acima de 10000, mas o manifesto não diz isso. A mesma cegueira que o DS-0002 tinha com o Dockerfile |
| KSV-0125 | a imagem vem de um registry não confiável | a lista de registries confiáveis do Trivy não inclui `localhost:5000`, que é o único registry em que este projeto confia. Errado para este projeto |

Antes da correção desta aula havia um sexto, o DS-0002, o USER que faltava e que a sua própria regra
achou. Esse coincidiu exatamente: duas ferramentas, um achado, uma correção.

### Onde elas coincidem, e onde não

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"sp-l19-overlap\" aria-label=\"Uma tabela de regras contra duas fontes de checagens. Tanto a sua política quanto as checagens embutidas do Trivy cobrem: o usuário do Dockerfile (DS-0002), runAsNonRoot (KSV-0012), sistema de arquivos raiz só de leitura (KSV-0014), limite de memória (KSV-0018) e nada de tag latest (KSV-0013). Só a sua política cobre imagens base por digest (o Trivy só procura a tag latest, DS-0001) e o binding de admissão dizendo Deny. Para imagens de localhost:5000 o Trivy discorda e aponta falha (KSV-0125). Só o Trivy cobre HEALTHCHECK, limite de CPU e UID acima de 10000.\"><defs></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que é checado</text><text x=\"335\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">onde</text><text x=\"435\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">policy/ (sua)</text><text x=\"595\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">embutidas do Trivy</text><rect x=\"12\" y=\"40\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">imagem base por digest</text><text x=\"435\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só :latest (DS-0001)</text><text x=\"335\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">só a sua</text><rect x=\"12\" y=\"76\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">USER do Dockerfile não é root</text><text x=\"435\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">DS-0002</text><text x=\"335\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">as duas</text><rect x=\"12\" y=\"112\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">runAsNonRoot</text><text x=\"435\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0012</text><text x=\"335\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">as duas</text><rect x=\"12\" y=\"148\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sistema de arquivos raiz só de leitura</text><text x=\"435\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0014</text><text x=\"335\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">as duas</text><rect x=\"12\" y=\"184\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limite de memória</text><text x=\"435\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0018</text><text x=\"335\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">as duas</text><rect x=\"12\" y=\"220\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sem :latest</text><text x=\"435\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">KSV-0013</text><text x=\"335\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">as duas</text><rect x=\"12\" y=\"256\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">imagens de localhost:5000</text><text x=\"435\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">aponta como falha (KSV-0125)</text><text x=\"335\" y=\"271\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">discordam</text><rect x=\"12\" y=\"292\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"307\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o binding de admissão diz Deny</text><text x=\"435\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><text x=\"595\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><text x=\"335\" y=\"307\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">só a sua</text><rect x=\"12\" y=\"328\" width=\"696\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"343\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HEALTHCHECK, limite de CPU, UID acima de 10000</text><text x=\"435\" y=\"343\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><text x=\"595\" y=\"343\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DS-0026, KSV-0011, -0020, -0021</text><text x=\"335\" y=\"343\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só o Trivy</text></svg>", "caption": "As regras gerais estão nas duas. As regras que conhecem este projeto, o registry, os digests, a política de admissão, estão só na sua."}
```

Quatro checagens do Trivy no manifesto perguntam o que quatro das suas regras perguntam, e passam
pelos mesmos motivos:

```
ana@vm:~/linkbox$ trivy config --quiet --include-non-failures --format json k8s/linkbox.yaml | jq -r '.Results[].Misconfigurations[] | select(.Status == "PASS") | "\(.ID) \(.Title)"' | grep -E '^KSV-00(12|13|14|18) '
KSV-0012 Runs as root user
KSV-0013 Image tag ":latest" used
KSV-0014 Root file system is not read-only
KSV-0018 Memory not limited
```

**A sobreposição é grande nas regras gerais e vazia nas que tratam deste projeto.** A biblioteca do
Trivy é feita sobretudo de regras gerais que ninguém num time pequeno pensaria em escrever, e é o
lugar certo para buscar ideias: o KSV-0020 tem razão, e acrescentar `runAsUser: 65532` ao manifesto o
responderia do mesmo jeito que `USER 65532:65532` respondeu ao DS-0002. As suas regras sabem coisas
que nenhuma biblioteca sabe: que `localhost:5000` é o registry, que este projeto usa digests, que o
binding de admissão precisa dizer `Deny`. O KSV-0125 não só deixa isso passar; ele entende ao
contrário.

### Por que o pipeline bloqueia pelas suas regras, e não pela biblioteca

O estágio do pipeline na próxima seção roda o conftest, e o `trivy config` continua sendo uma
ferramenta que você roda quando quer uma segunda opinião. Três motivos, cada um de uma aula anterior:

- **Um portão deve falhar só pelo que alguém deveria corrigir** (aula 7). Dos cinco achados acima,
  dois são decisões já tomadas e um está errado para este projeto, e um portão que falhasse por eles
  seria contornado até sexta-feira. Dá para mandar o Trivy pular checagens com um arquivo
  `.trivyignore`, mas isso é uma lista das opiniões da biblioteca de que você discorda, e ela cresce.
- **A biblioteca muda debaixo de você.** O `trivy config` baixa o pacote de checagens quando roda, na
  primeira vez e de novo quando sai um mais novo, então uma checagem nova pode quebrar um build que
  não mudou nada. Isso é certo para dados de vulnerabilidade, que a aula 8 fixou num banco só para a
  gravação, e incômodo para uma regra sobre como este projeto é configurado.
- **Uma política é uma decisão, e decisões são revisadas.** Uma regra em `policy/` chegou num commit
  que alguém aprovou, com uma mensagem dizendo por quê. Uma checagem acrescentada a uma biblioteca lá
  fora não.

Nada disso torna as checagens embutidas menos úteis. Leia a saída delas quando um manifesto ou um
Dockerfile mudar bastante, adote como regra sua, com teste, o que você aceitar, e anote por que
discorda do resto. O Trivy também roda o seu próprio Rego ao lado das embutidas se você apontá-lo
para um diretório de políticas (`--config-check`), o que vale saber se você preferir uma ferramenta a
duas; este curso as mantém separadas para a diferença continuar visível.

### Nem toda regra é uma checagem de configuração

Algumas decisões não podem ser lidas de arquivo nenhum. Se a imagem que roda é a imagem que foi
assinada (aula 14), se uma dependência tem um aviso de segurança (aula 5), se o contêiner em execução
de fato descarta as capabilities (aula 9): essas precisam do artefato, de um banco de dados ou do
sistema rodando. Uma política sobre arquivos checa o que foi declarado, e vale checar porque
declarações são baratas de mudar e fáceis de errar. Ela não checa o que aconteceu.
