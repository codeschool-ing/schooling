---
title: Medindo uma defesa
version: 1
---

Vermelho, azul e roxo são jeitos de descobrir quão boa é uma defesa, e essa descoberta vale mais quando
produz números que dá para comparar de um exercício para o outro. Três tipos são de uso comum.

### Cobertura: quais técnicas veríamos?

Atacantes reaproveitam um conjunto bem estável de técnicas, e o **MITRE ATT&CK** é um catálogo público
delas, organizado pelo que o atacante quer conseguir em cada etapa: entrar, ficar, se mover, tirar
dados. Um time azul pode marcar cada técnica como detectada, parcialmente detectada ou não detectada, e
os exercícios roxos são como essas marcas se provam, em vez de serem supostas. O resultado é um mapa de
onde a defesa é cega. A aula 26 de `attacks-threats` explica o catálogo em si.

### Tempo: quanto até percebermos, e até parar?

| medida | o que conta |
|---|---|
| **tempo para detectar** | do momento em que algo acontece ao momento em que alguém sabe |
| **tempo para responder** | de saber até ter contido |
| **tempo de permanência** (*dwell time*) | quanto tempo um atacante ficou dentro antes de ser achado |

Essas medidas costumam ser relatadas como médias entre incidentes e exercícios, como **MTTD** e
**MTTR**, tempo médio para detectar e para responder. O exercício da seção anterior não teria como
produzir nenhum dos dois números para adivinhação de senha, porque o log não tinha hora; corrigir isso
é o que torna a medida possível.

### Prática: as pessoas sabem o que fazer?

Nem todo exercício precisa de time vermelho. Um **exercício de mesa** (*tabletop*) é uma reunião em que
alguém descreve um incidente passo a passo, "o servidor da loja está cifrado e há um pedido de resgate
na tela", e as pessoas que responderiam dizem o que fariam em cada passo. Custa uma tarde e acha as
falhas que só aparecem sob pressão: ninguém sabe onde fica o backup, os telefones dos sócios estão no
servidor cifrado, o número da seguradora está num e-mail que ninguém consegue abrir. A aula 12 monta o
backup que responde à primeira.

### Com que frequência

Uma defesa muda toda vez que os sistemas mudam, então um teste do ano passado descreve a loja do ano
passado. Um ritmo sensato para uma organização do tamanho da loja: uma checagem roxa sempre que um
controle é acrescentado ou mudado, como no exercício desta aula; um exercício de mesa por ano; e, quando
o básico estiver no lugar, um teste de invasão externo do que fica de frente para a internet. A aula 18
descreve as carreiras dos dois lados desses exercícios, e `soc-response` e `pentest` são os cursos que
ensinam cada lado direito.
