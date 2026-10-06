---
title: Taxa de base e fadiga de alertas
version: 1
---

A semana da loja teve 98 casos, onze deles do exercício: pouco mais de um em dez. Ambientes reais não
são nada assim. Quase tudo o que acontece é inofensivo, e ataques são raros. Essa raridade, a **taxa
de base**, muda o que os números de um detector querem dizer.

### Um erro pequeno sobre um número grande

Imagine um detector excelente por qualquer padrão razoável: pega 99% dos ataques, e alerta por engano
em só 1% dos casos inofensivos. Agora dê a ele um sistema mais movimentado que o da loja: 10.000 casos
por dia, dos quais um é ataque.

| | quantidade |
|---|---|
| ataques pegos (99% de 1) | cerca de 1 |
| casos inofensivos com alerta (1% de 9.999) | cerca de 100 |
| alertas num dia | cerca de 101 |
| precisão | cerca de 1% |

**Uns cem alertas por dia, e um deles importa.** O detector não piorou; o palheiro cresceu. Essa é a
**falácia da taxa de base**: julgar um alerta pela exatidão do detector e esquecer quão rara é a coisa
que ele detecta. Quando a coisa é rara, até uma taxa minúscula de falsos positivos produz quase só
alarmes falsos.

### O que isso faz com as pessoas

Uma pessoa que abre cem alertas e acha todos inofensivos aprende um hábito: alerta é ruído. No dia em
que um é real, ele é fechado junto com os outros. Isso é **fadiga de alertas**, e é assim que incidentes
reais passam despercebidos em organizações que tinham uma detecção exatamente para o que aconteceu. O
alerta disparou; ninguém acreditou.

A fadiga de alertas transforma falsos positivos em falsos negativos, um passo depois, na cabeça das
pessoas. É por isso que a precisão importa tanto quanto a revocação, e por isso "alertar sobre tudo,
por garantia" não é a escolha segura que parece.

### O que fazer

- **Conte os alertas por semana, por regra.** Uma regra sobre a qual ninguém agiu em três meses está
  mal ajustada ou não mede nada.
- **Corrija fontes barulhentas na causa**, como no caso do backup, em vez de ensinar as pessoas a
  ignorá-las.
- **Gradue os alertas.** Nem tudo precisa acordar alguém: alguns vão para um resumo diário, poucos vão
  para um celular à noite.
- **Meça contra a verdade quando puder.** Um exercício roxo, como o da aula 10 e o desta, é o único
  momento em que a verdade é conhecida. Use-o para contar as quatro caixas, toda vez.

A regra final da loja, três falhas em dez minutos com o backup corrigido, teria gerado cinco alertas
nesta semana sem o exercício: a equipe com três ou quatro erros de digitação. É um número que a ana
consegue ler um por um, e essa é uma propriedade de uma detecção tão importante quanto a revocação.
