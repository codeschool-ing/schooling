---
title: Voltar ou seguir em frente
version: 1
---

Quando um release se comporta mal, há duas saídas. O **rollback** volta ao release anterior. O
**roll forward** corrige o problema e entrega um release novo. A versão 1.6.1 foi um roll forward a
partir do 1.6.0: uma mudança de um caractere, `range(40, 57)` para `range(40, 58)`, liberada como
versão nova.

## Voltar primeiro, como padrão

- Leva segundos, e o release para onde volta é sabidamente bom: rodou em produção até poucos minutos
  atrás.
- Para o estrago enquanto a causa ainda é desconhecida. Uma correção escrita sob pressão, sem saber
  a causa, é um palpite, e um palpite errado entregue às pressas é um segundo incidente.
- Transforma o incidente num bug comum: a correção pode então ser escrita, revisada e testada do
  jeito de sempre, e entregue pelo pipeline de sempre.

## Quando seguir em frente é melhor

- **O release anterior também está quebrado.** Se o bug entrou três releases atrás e só foi notado
  agora, voltar um release não adianta.
- **Voltar desfaria algo que não se desfaz com segurança**, como uma migração que o release antigo
  não consegue ler. A próxima seção trata disso.
- **A correção é pequena, entendida e rápida de entregar**, e o pipeline é rápido o bastante para a
  correção chegar à produção tão depressa quanto um rollback. Para uma correção de uma linha e um
  pipeline de poucos minutos, isso pode ser verdade.
- **Uma flag consegue desligar a funcionalidade.** Isso não é nem rollback nem roll forward: o release
  fica, a funcionalidade sai. Se o código novo está atrás de uma flag, costuma ser a saída mais rápida
  de todas.

A escolha não deveria ser feita por quem escreveu a mudança, na hora, por orgulho. Uma equipe que
combina antes que o padrão é "voltar primeiro, investigar depois" tira essa discussão de todo
incidente.
