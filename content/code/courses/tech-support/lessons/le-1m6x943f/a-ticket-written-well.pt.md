---
title: Um chamado que o próximo consegue usar
version: 1
---

O chamado do Daniel da aula 3, escrito de dois jeitos. O primeiro é comum:

> *Disco cheio. Limpei. Resolvido.*

O segundo é o mesmo trabalho, registrado:

```localised
Solicitante: Daniel (financeiro), pc1, conta daniel
Sintoma:     cp: error writing '/srv/shared/reports/september.csv': No space left on device
Impacto:     o relatório de setembro não pode ser salvo na pasta compartilhada
Checado:     arquivo e pasta são do Daniel (ok); o echo falha igual (não é o programa)
             df /srv/shared: 100% usado; du: logs 55M; findmnt: disco local; dmesg: 0 erros
Causa:       logs/export.log cresceu até encher o disco compartilhado; o programa que
             o escreve tenta uma conexão para sempre e registra cada tentativa
Feito:       guardei as últimas 1000 linhas do log, gravadas antes em /tmp (a primeira
             tentativa, no disco cheio, falhou); df: 1% usado
Confirmado:  o próprio Daniel salvou o relatório
Pendente:    dono do job de exportação avisado; test.txt vazio em reports, de uma checagem
```

O segundo leva alguns minutos a mais para escrever. Na próxima vez que a pasta compartilhada encher, ele
poupa a tarde: a causa tem nome, o comando que falhou está lá para ninguém tentar de novo, e o que vai
enchê-la de novo tem uma linha própria.
