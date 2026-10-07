---
title: STRIDE por elemento
version: 1
---

Fazer seis perguntas a cada elemento de um diagrama com vinte elementos dá cento e vinte
perguntas, e muitas não fazem sentido: não dá para "elevar privilégio" num repositório de dados,
porque um repositório não roda código. O **STRIDE por elemento** é a versão em que a Microsoft
chegou: cada tipo de elemento de um DFD está exposto a algumas letras e não a outras.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-per-element\" aria-label=\"STRIDE por elemento, como uma grade. Entidades externas: falsificação e repúdio. Processos: as seis. Repositórios de dados: adulteração, divulgação de informação e negação de serviço, mais repúdio quando o repositório é um log. Fluxos de dados: adulteração, divulgação de informação e negação de serviço.\"><text x=\"267.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">S</text><text x=\"267.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">falsificação</text><text x=\"342.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">T</text><text x=\"342.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">adulteração</text><text x=\"417.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">R</text><text x=\"417.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repúdio</text><text x=\"492.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">I</text><text x=\"492.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">divulgação</text><text x=\"567.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">D</text><text x=\"567.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">negação</text><text x=\"642.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">E</text><text x=\"642.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">elevação</text><rect x=\"20.0\" y=\"70.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">entidade externa</text><circle cx=\"267.5\" cy=\"87.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"417.5\" cy=\"87.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><rect x=\"20.0\" y=\"108.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">processo</text><circle cx=\"267.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"342.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"417.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"492.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"567.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"642.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><rect x=\"20.0\" y=\"146.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">repositório de dados</text><circle cx=\"342.5\" cy=\"163.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"417.5\" cy=\"163.0\" r=\"8\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"492.5\" cy=\"163.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"567.5\" cy=\"163.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><rect x=\"20.0\" y=\"184.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"201.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fluxo de dados</text><circle cx=\"342.5\" cy=\"201.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"492.5\" cy=\"201.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"567.5\" cy=\"201.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"250.0\" cy=\"236.0\" r=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"262.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repúdio vale para um repositório que é log: adulterá-lo apaga o registro</text></svg>", "caption": "Um processo está exposto às seis porque é onde o código roda. Um fluxo não se falsifica sozinho: a origem dele, sim.", "same": ["D", "E", "I", "R", "S", "T"]}
```

O raciocínio por trás de cada linha é o que faz a tabela valer a pena de lembrar:

- **Entidades externas: S e R.** Estão fora do seu controle, então as perguntas são se elas são
  quem dizem ser e se conseguem negar o que fizeram. Não dá para adulterar um paciente; dá para
  fingir ser um.
- **Processos: as seis.** Um processo roda código, recebe entrada, tem privilégios e atende
  pessoas. Pode ser personificado, alterado, levado a agir sem deixar rastro, levado a vazar,
  parado, e enganado para fazer o que quem o chama não pode fazer.
- **Repositórios de dados: T, I e D**, e **R** quando o repositório é um log. Dado em repouso pode
  ser mudado, lido ou tornado indisponível. Um log é o registro que responde ao repúdio, então
  adulterá-lo é uma ameaça de repúdio.
- **Fluxos de dados: T, I e D.** Dado em movimento pode ser mudado no caminho, lido no caminho ou
  bloqueado. Um fluxo não se falsifica sozinho; falsificar um fluxo é falsificar a origem dele, e
  essa pergunta é da origem.

### Percorrendo o portal

Aplicada ao diagrama de nível 1 do portal, a tabela dá o número de perguntas a fazer antes de
responder qualquer uma:

| elementos | quantos | letras cada | perguntas |
|---|---|---|---|
| entidades externas | 4 | 2 | 8 |
| processos | 3 | 6 | 18 |
| repositórios de dados | 2 | 3 | 6 |
| fluxos de dados | 12 | 3 | 36 |
| | | | **68** |

Sessenta e oito perguntas são uma tarde, e a maioria das respostas é "não, porque" ou "sim, já está
tratado". A questão não é cada uma achar uma ameaça. É que **nenhuma fica de fora porque ninguém
pensou nela**, que é o modo de falha da lista sem estrutura.

### Onde ele não alcança

O STRIDE por elemento olha cada elemento sozinho. Algumas ameaças só existem na relação entre dois
elementos: o webhook (fluxo 7) só é perigoso por causa *do que o portal faz ao recebê-lo*, que é um
fato sobre o fluxo e o processo juntos. A próxima seção é a variação que olha exatamente isso.
