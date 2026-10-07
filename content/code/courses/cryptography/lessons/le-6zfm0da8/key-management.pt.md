---
title: Gestão de chaves: cifragem em envelope e onde a chave mora
version: 1
---

**Toda camada desta aula é tão forte quanto a guarda da sua chave. O arranjo que venceu quase em
toda parte é a cifragem em envelope: dados cifrados com uma chave de dados, chaves de dados cifradas
com uma chave mestra, e a chave mestra num serviço que nunca a deixa sair.** A estrutura é o
cabeçalho LUKS da seção 03 e o esquema híbrido da aula 3, aplicados a uma organização inteira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Cifragem em envelope. À esquerda, os dados, cifrados com uma chave de dados. Ao lado, a chave de dados embrulhada pela chave mestra. A chave mestra fica dentro do serviço de gestão de chaves. Para ler, o serviço que tem a chave embrulhada pede ao KMS que a desembrulhe, recebe a chave de dados de volta, decifra localmente e a esquece; o KMS confere a permissão e registra o pedido.\"><defs><marker id=\"env-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"env-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"330\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"36\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">armazenamento: disco, bucket, backup</text><rect x=\"40\" y=\"66\" width=\"140\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dados</text><text x=\"110\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AES-256-GCM</text><text x=\"110\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sob a DEK</text><rect x=\"200\" y=\"96\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">DEK embrulhada</text><text x=\"265\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32 bytes + etiqueta</text><rect x=\"470\" y=\"50\" width=\"230\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">KMS ou HSM</text><rect x=\"500\" y=\"90\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">chave mestra (KEK)</text><text x=\"585\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confere permissão, registra</text><polyline points=\"332,112 468,100\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#env-ah-wire)\"></polyline><text x=\"400\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desembrulhar?</text><polyline points=\"468,140 332,132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#env-ah-phosphor)\"></polyline><text x=\"400\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">DEK, por instantes</text></svg>", "caption": "A chave mestra nunca sai do KMS; só chaves de dados embrulhadas viajam."}
```

## Dois tipos de chave

- Uma **chave de cifragem de dados** (DEK) cifra dados: um disco, um arquivo de banco, uma coluna, um
  backup. Ela é aleatória, usada localmente porque os dados são grandes, e guardada só na forma
  **embrulhada**, cifrada, ao lado dos dados que protege.
- Uma **chave de cifragem de chaves** (KEK), ou chave mestra, cifra DEKs e mais nada. Ela mora num
  **serviço de gestão de chaves** (AWS KMS, Google Cloud KMS, Azure Key Vault, HashiCorp Vault) ou num
  **módulo de segurança de hardware**, e a operação que ela oferece é "desembrulhe esta DEK para mim",
  respondida só a quem tem permissão, e registrada.

Para ler dados, um serviço manda a DEK embrulhada ao KMS, recebe a DEK em claro de volta, decifra
localmente e esquece a DEK. A chave mestra nunca sai do KMS.

## O que o arranjo compra

- **O acesso vira uma permissão, com trilha de auditoria.** Quem consegue decifrar os backups do
  banco é a lista de identidades autorizadas a chamar o desembrulhar de uma chave, e cada chamada é
  registrada. Um backup vazado é inútil para quem não consegue também chamar o KMS como uma
  identidade autorizada.
- **A troca é barata.** Trocar a chave mestra significa reembrulhar DEKs, algumas centenas de bytes
  cada, não cifrar de novo terabytes.
- **Apagamento criptográfico em escala.** Apagar uma DEK torna ilegíveis os dados dela em todo lugar
  para onde foram copiados: os dados de um cliente, os backups de um sistema aposentado. Apagar uma
  chave mestra faz isso para tudo o que está sob ela, e por isso os produtos de KMS põem um prazo de
  espera de dias na exclusão.
- **Separação de funções.** Quem administra o banco não é quem controla a política da chave.

## Três regras que uma revisão confere

1. **Uma chave nunca fica guardada ao lado do que protege.** Nem no mesmo arquivo de configuração,
   nem no mesmo repositório, nem na mesma imagem, nem no mesmo bucket. O teste da aula 11 vale para
   cada camada desta.
2. **Uma chave cuja perda seria catastrófica tem um caminho de recuperação**, testado: o slot de
   recuperação do LUKS, chaves de cifragem sob custódia (aula 3), chaves de KMS protegidas contra
   exclusão. Cifragem sem recuperação transforma uma chave perdida em dados perdidos, o que pela LGPD
   também é um incidente.
3. **Os backups são cifrados com chaves que os sistemas de produção não conseguem apagar.** Um
   ransomware que chega à produção não deveria conseguir destruir, ou cifrar de novo, também as
   chaves dos backups.

A aula 17 começa pela primeira regra, porque quebrá-la é o erro criptográfico mais comum que existe.
