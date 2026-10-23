---
title: "Incidentes nas dependências: event-stream, ua-parser-js, torchtriton, xz"
version: 1
---

Quatro incidentes em que o build das próprias vítimas estava certo e o problema chegou dentro de algo de
que elas dependiam. **Cada um é um jeito diferente de um pacote mudar de mãos**: doado, roubado,
imitado, ou conquistado ao longo de dois anos. Cada um é contado a partir dos relatos públicos, no nível
do que quebrou e do que o teria pegado.

### event-stream, 2018: uma passagem de manutenção

O event-stream era um pacote npm popular cujo autor tinha perdido o interesse nele. Em setembro de 2018
um voluntário se ofereceu para mantê-lo, e o autor lhe passou os direitos de publicação. O novo
mantenedor acrescentou uma dependência, `flatmap-stream`, e uma release posterior dessa dependência
trazia código ofuscado que mirava uma aplicação em particular, a carteira de bitcoin Copay. Foi
descoberto em novembro de 2018.

**O código malicioso estava na release do `flatmap-stream` publicada no npm e não no código dele no
GitHub**, e é por isso que o SLSA o usa como exemplo de ameaça por dependência: um pacote que não bate
com o próprio código.

O que o teria pegado:

- **Ler o diff do lockfile**: uma dependência transitiva nova aparecendo numa release menor é uma
  mudança que merece um olhar, e só fica visível se alguém a lê.
- **Observar quem publica**: uma troca de mantenedor num pacote de que você depende é um evento, não um
  detalhe.
- **Proveniência ligando um pacote ao seu código**, para que um arquivo publicado sem código
  correspondente se destaque.

### ua-parser-js, 2021: uma conta roubada

O ua-parser-js interpreta as strings de user-agent dos navegadores e era baixado milhões de vezes por
semana. Em outubro de 2021 a conta npm do mantenedor foi tomada, e três versões foram publicadas, 0.7.29,
0.8.0 e 1.0.0, **que instalavam um minerador de criptomoeda e, no Windows, um programa que roubava
senhas**. O mantenedor percebeu em poucas horas e lançou versões corrigidas; a CISA, a agência de
cibersegurança dos Estados Unidos, emitiu um alerta.

O que o teria pegado:

- **Autenticação de dois fatores nas contas de publicação**, que os registries passaram a exigir dos
  mantenedores de pacotes populares.
- **Um lock que não aceita versões novas sozinho**: um projeto cujo lockfile fixava a 0.7.28 instalou a
  0.7.28 naquele dia.
- **Um período de espera**: uma release com menos de alguns dias não é adotada automaticamente. A aula
  15 resolve as dependências com uma data por esse motivo, e a aula 18 dá ao bot de atualização uma idade
  mínima.

### torchtriton, 2022: um nome que ninguém tinha registrado

Os builds noturnos do PyTorch dependiam de um pacote chamado `torchtriton`, servido pelo índice do
próprio PyTorch. Ninguém tinha registrado esse nome no PyPI. Alguém registrou, e entre 25 e 30 de
dezembro de 2022 quem instalou o nightly de Linux com o pip recebeu o pacote do PyPI no lugar, **porque
o pip, com os dois índices, ficou com o do PyPI**. Ele coletava informações da máquina e as enviava para
fora. O PyTorch renomeou a dependência, registrou o nome novo no PyPI e publicou os passos para checar e
remover o pacote.

O que o teria pegado é o assunto da próxima seção: um índice só, hashes, e nomes registrados. O SLSA o
põe na letra H, a escolha do pacote.

### xz-utils, 2024: confiança conquistada ao longo de dois anos

O xz é uma biblioteca de compressão presente em quase toda distribuição Linux. Ao longo de cerca de dois
anos, um colaborador com o nome Jia Tan se tornou co-mantenedor de confiança do projeto, que tinha um
único mantenedor, sobrecarregado. Em fevereiro e março de 2024 as versões 5.6.0 e 5.6.1 foram lançadas
com um backdoor que mirava o servidor SSH em algumas distribuições. **A parte que o ativava estava nos
tarballs de release e não no repositório Git**, escondida entre arquivos de build que as pessoas
raramente leem.

Em 29 de março de 2024 Andres Freund, um desenvolvedor que investigava por que os logins SSH num sistema
de teste Debian usavam mais processador do que deviam, o rastreou e o reportou. Recebeu o CVE-2024-3094.
Tinha chegado a releases contínuas e de desenvolvimento de algumas distribuições, e foi pego antes das
releases estáveis das principais.

O que o teria pegado:

- **Construir a partir do repositório em vez do tarball de release**, ou comparar os dois: a diferença
  estava exatamente onde estava o backdoor. Nos termos do SLSA, um artefato construído a partir de algo
  que não é o seu código.
- **Prestar atenção à saúde de um projeto**: um mantenedor não pago sob pressão é um risco para todo
  projeto que depende dele, e a aula 15 lê essa saúde antes de adotar um pacote.
- **Perceber**: ele foi pego por uma pessoa que olhou para um atraso de meio segundo em vez de ignorá-lo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"sp-l12-timeline\" aria-label=\"Sete incidentes posicionados por ano, de 2018 a 2025, e pelo elo da cadeia onde quebraram. Dependências: event-stream 2018, ua-parser-js 2021, torchtriton 2022, xz-utils 2024. O build e o que o alimenta: SolarWinds 2020, Codecov 2021, tj-actions 2025.\"><defs></defs><text x=\"66\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2018</text><line x1=\"66\" y1=\"40\" x2=\"66\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"152\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2019</text><line x1=\"152\" y1=\"40\" x2=\"152\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"238\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2020</text><line x1=\"238\" y1=\"40\" x2=\"238\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"324\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2021</text><line x1=\"324\" y1=\"40\" x2=\"324\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"410\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2022</text><line x1=\"410\" y1=\"40\" x2=\"410\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"496\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2023</text><line x1=\"496\" y1=\"40\" x2=\"496\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"582\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2024</text><line x1=\"582\" y1=\"40\" x2=\"582\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"668\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2025</text><line x1=\"668\" y1=\"40\" x2=\"668\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"10\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">numa dependência</text><text x=\"10\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no build e no que o alimenta</text><rect x=\"22\" y=\"49\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">event-stream</text><rect x=\"280\" y=\"39\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ua-parser-js</text><rect x=\"366\" y=\"75\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">torchtriton</text><rect x=\"538\" y=\"49\" width=\"88\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"582.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">xz-utils</text><rect x=\"198\" y=\"147\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"238.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SolarWinds</text><rect x=\"284\" y=\"177\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"324.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Codecov</text><rect x=\"628\" y=\"147\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tj-actions</text></svg>", "caption": "Sete anos, sete incidentes, e nenhum deles no código que as vítimas revisaram."}
```

| incidente | ano | como o pacote mudou de mãos | o controle |
|---|---|---|---|
| event-stream | 2018 | passado a um voluntário | ler o diff do lockfile; observar mantenedores |
| ua-parser-js | 2021 | conta de publicação roubada | 2FA; versões travadas; um período de espera |
| torchtriton | 2022 | um nome livre registrado | um índice só; hashes; nomes registrados |
| xz-utils | 2024 | confiança conquistada ao longo de anos | build a partir do código; comparar tarball e repositório |
