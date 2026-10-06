---
title: Como os frameworks se encaixam
version: 1
---

A esta altura o curso nomeou vários frameworks, e eles podem parecer rivais. Não são. Cada um responde a
uma pergunta diferente, e as organizações os combinam.

| | pergunta que responde | forma | certificável? | aula |
|---|---|---|---|---|
| **ISO/IEC 27001** | como gerimos a segurança da informação como sistema? | requisitos para um sistema de gestão | **sim** | 14 |
| **ISO/IEC 27002** | como implementamos cada controle? | orientação sobre 93 controles | não | 14 |
| **NIST CSF 2.0** | que resultados nosso programa deve alcançar, e onde estamos? | 6 funções, 22 categorias, 106 resultados | não | esta |
| **NIST RMF (SP 800-37)** | como levamos um sistema do projeto à operação autorizada? | um processo de sete passos | não (uma autorização, não um certificado) | esta |
| **NIST SP 800-53** | quais controles, em detalhe completo? | um catálogo de controles em 20 famílias | não | esta |
| **CIS Controls** | o que fazer primeiro, em que ordem? | 18 controles priorizados | não | 16 |

### Uma combinação típica

Uma empresa de algumas centenas de pessoas poderia usá-los assim: o **CSF** para falar com o conselho,
porque seis funções e um perfil atual e um alvo cabem num slide; a **ISO 27001** como sistema de gestão,
certificada porque os clientes pedem; a **27002** e os **CIS Controls** para decidir e implementar os
controles; e o **SP 800-53** como referência quando um controle precisa de especificação precisa. Uma
contratada do governo federal americano acrescentaria o **RMF** para cada sistema que opera em nome do
governo.

### As pontes entre eles

Os frameworks foram escritos para serem mapeados uns nos outros:

- o NIST publica referências informativas de cada subcategoria do CSF para controles da ISO 27001, dos
  CIS Controls e do SP 800-53;
- a ISO 27002:2022 marca cada controle com as cinco funções originais do CSF como atributo (aula 14);
- os CIS Controls publicam os próprios mapeamentos para o CSF e para a ISO 27001.

Então o trabalho do mapeamento de controles da aula 13 já vem quase pronto: uma organização que
implementou um controle para um framework consegue consultar quais resultados dos outros ele satisfaz.

### Escolhendo para a loja

Para a loja, as seis funções do CSF são o **mapa** certo: uma página que mostra aos sócios onde estão as
falhas, escrita em palavras que eles já usam. Os **CIS Controls** da próxima aula são a **lista de
tarefas** certa, porque dizem o que fazer primeiro. A ISO 27001 espera até um cliente pedir, como a aula
14 aconselhou. O RMF não se aplica à loja, e as duas ideias dele que valem levar, categorizar pelo
impacto e ter uma pessoa nomeada que autoriza, já estão nas aulas 1 e 3.
