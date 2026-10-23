---
title: CycloneDX e SPDX, campo a campo
version: 1
---

Existem dois formatos padrão, e a primeira pergunta que as pessoas fazem é qual é melhor. **Eles
carregam quase a mesma informação, cresceram respondendo perguntas diferentes, e toda ferramenta séria
lê e escreve os dois.** A habilidade útil é ler qualquer um deles, e saber onde cada um guarda um dado.

- O **CycloneDX** vem da OWASP e nasceu do trabalho de segurança: acompanhar componentes para
  compará-los com vulnerabilidades. É publicado como o padrão Ecma ECMA-424.
- O **SPDX** vem da Linux Foundation e nasceu da conformidade de licenças: registrar a licença de cada
  arquivo e pacote. A versão 2.2.1 é o padrão internacional ISO/IEC 5962:2021.

### O documento em volta da lista

Tire as listas longas e veja o que cada documento diz de si. Primeiro o CycloneDX:

```
ana@vm:~/linkbox$ jq "del(.components, .dependencies) | .metadata |= {timestamp, component}" ~/sbom/linkbox.cdx.json
{
  "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "serialNumber": "urn:uuid:a4721878-b418-4a79-9735-d7010d555998",
  "version": 1,
  "metadata": {
    "timestamp": "2026-10-23T08:54:37-03:00",
    "component": {
      "bom-ref": "00c172294fdeb85b",
      "type": "container",
      "name": "localhost:5000/linkbox",
      "version": "main"
    }
  }
}
```

Depois o SPDX:

```
ana@vm:~/linkbox$ jq "del(.packages, .files, .relationships, .hasExtractedLicensingInfos)" ~/sbom/linkbox.spdx.json
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "localhost:5000/linkbox",
  "documentNamespace": "https://anchore.com/syft/image/localhost-5000/linkbox-474ec5dd-b5ba-4cd2-9f5c-4806d7d145df",
  "creationInfo": {
    "licenseListVersion": "3.29",
    "creators": [
      "Organization: Anchore, Inc",
      "Tool: syft-1.54.1"
    ],
    "created": "2026-10-23T11:54:37Z"
  }
}
```

Os dois dizem o que são e em qual versão do formato, quem os fez (syft 1.54.1), quando, e o que
descrevem. Dizem isso em lugares diferentes: o CycloneDX guarda o objeto em `metadata.component`, a
imagem `localhost:5000/linkbox` em `main`; o SPDX dá ao documento um `name` e, dentro das
`relationships` deixadas de fora acima, uma relação `DESCRIBES` do documento para o pacote da imagem.
Cada documento tem uma identidade própria, um `serialNumber` no CycloneDX e um `documentNamespace` no
SPDX, que é nova a cada execução, então dois SBOMs da mesma imagem continuam sendo dois documentos.

### Um pacote, duas vezes

O gunicorn como o CycloneDX o descreve:

```
ana@vm:~/linkbox$ jq ".components[] | select(.name == \"gunicorn\") | {type, name, version, licenses, purl}" ~/sbom/linkbox.cdx.json
{
  "type": "library",
  "name": "gunicorn",
  "version": "22.0.0",
  "licenses": [
    {
      "license": {
        "id": "MIT"
      }
    }
  ],
  "purl": "pkg:pypi/gunicorn@22.0.0"
}
```

E como o SPDX descreve:

```
ana@vm:~/linkbox$ jq ".packages[] | select(.name == \"gunicorn\") | {name, SPDXID, versionInfo, supplier, licenseDeclared, purl: (.externalRefs[] | select(.referenceType == \"purl\") | .referenceLocator)}" ~/sbom/linkbox.spdx.json
{
  "name": "gunicorn",
  "SPDXID": "SPDXRef-Package-python-gunicorn-a4b2c9daf4751987",
  "versionInfo": "22.0.0",
  "supplier": "Person: Benoit Chesneau (benoitc@gunicorn.org)",
  "licenseDeclared": "MIT",
  "purl": "pkg:pypi/gunicorn@22.0.0"
}
```

Os mesmos cinco fatos, com nomes diferentes: o que é, o nome, a versão, a licença, e o purl que o
identifica em qualquer lugar. O SPDX acrescenta um `supplier`, lido dos metadados do pacote, e um
`SPDXID` para o qual outras partes do documento apontam. Ele também separa a licença que o pacote
**declara** da licença que alguém **concluiu** depois de olhar, que o syft deixa como `NOASSERTION`
porque não olhou; essa distinção é a herança da conformidade de licenças aparecendo. Os filtros acima
deixam a saída curta: os dois documentos carregam mais para cada pacote, os identificadores CPE que
bancos de vulnerabilidades mais antigos usam e os caminhos dos arquivos que o syft leu.

### Os dois lado a lado

| o quê | CycloneDX | SPDX |
|---|---|---|
| formato e versão | `bomFormat`, `specVersion` | `spdxVersion` |
| identidade do documento | `serialNumber` | `documentNamespace`, `SPDXID` |
| feito por, e quando | `metadata.tools`, `metadata.timestamp` | `creationInfo.creators`, `creationInfo.created` |
| o que descreve | `metadata.component` | uma relação `DESCRIBES` |
| um pacote | uma entrada de `components` | uma entrada de `packages` |
| versão | `version` | `versionInfo` |
| identificador | `purl`, e `cpe` | `externalRefs` dos tipos `purl` e `cpe23Type` |
| licença | `licenses` | `licenseDeclared` e `licenseConcluded` |
| fornecedor | `author` ou `supplier` | `supplier`, `originator` |
| o que depende do quê | `dependencies` | `relationships` como `DEPENDS_ON` |
| arquivos | componentes do tipo `file` | `files`, e relações `CONTAINS` |

Cada um dos elementos mínimos da NTIA, da primeira seção, tem lugar nos dois: fornecedor, nome, versão,
identificador, relações, autor, carimbo de tempo.

### Por que o arquivo SPDX é maior

O documento SPDX tem cerca de duas vezes e meia o tamanho do CycloneDX para a mesma imagem. Os dois
registram os arquivos que o syft achou na imagem; o SPDX também registra uma relação para cada arquivo
que lista e repete os identificadores de cada pacote em `externalRefs`. Nenhum está errado, e o tamanho
raramente importa, mas isso explica por que os dois arquivos de uma execução nunca se parecem.

### Qual guardar

Este curso guarda os dois, porque gerar os dois custa uma execução do syft e algumas centenas de
kilobytes. Quando é preciso escolher um, quem decide é quem consome: uma plataforma de vulnerabilidades
ou uma ferramenta de assinatura pode querer CycloneDX, um time jurídico auditando licenças pode pedir
SPDX, o contrato de um cliente pode nomear um. **Pergunte a quem vai ler antes de escolher o formato**,
uma regra que a seção sobre scan desta aula mostra valer para mais do que o formato.
