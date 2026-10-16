---
title: Sem culpa, e por que isso não é ser mole
version: 1
---

Depois do incidente de 30 de setembro, a pergunta óbvia é **quem** deixou uma mudança que cobra as lojas duas vezes chegar à produção. Rafa escreveu a nova tentativa; Duda revisou; o deploy saiu às 17:20 na tarde mais movimentada do mês. Qualquer um deles poderia ser apontado, e apontar um daria a sensação de responsabilização.

Seria também o fim de qualquer aprendizado. Um **postmortem sem culpa** se propõe a entender como o sistema, incluindo as pessoas dentro dele, produziu a falha, partindo da premissa de que **as pessoas fizeram o que fazia sentido para elas com o que sabiam naquele momento**. A pergunta deixa de ser "quem cometeu o erro?" e passa a ser "como fez sentido cometê-lo, e o que o teria pegado?"

## De onde vem a ideia

Vem de áreas em que a falha mata pessoas. A aviação e a medicina aprenderam, ao longo de décadas, que culpar o piloto ou a enfermeira produzia menos relatos, e não menos acidentes; a próxima pessoa a cometer o mesmo erro ficava calada. O pesquisador de segurança Sidney Dekker chama o relato que culpa de **primeira história**, o "erro humano", e o relato das circunstâncias que tornaram o erro provável de **segunda história**. Só a segunda leva a algum lugar. No software, o ensaio de John Allspaw de 2012 sobre a prática na Etsy, *Blameless PostMortems and a Just Culture*, tornou a ideia amplamente conhecida.

## Por que não é ser mole

Sem culpa não quer dizer que ninguém é responsável. Quer dizer que a responsabilidade é posta onde ela pode fazer algum bem:

- **Os fatos aparecem.** Quem espera ser culpado deixa coisas de fora, ou se lembra delas de outro jeito. Quem espera ser compreendido diz "eu vi o alerta e achei que era o ruído de sempre", que é exatamente a frase de que a aula 18 precisa.
- **As correções caem no sistema.** "Rafa deveria ser mais cuidadoso" não corrige nada, porque a próxima pessoa não vai ser Rafa. "Novas tentativas de cobrança no cartão precisam de uma chave de idempotência, e o checklist de revisão pergunta sobre isso" corrige para todo mundo.
- **O viés de retrospectiva tem nome.** Depois de um incidente, o caminho até a falha parece óbvio, porque você sabe onde ele terminou. Na hora, era uma entre centenas de mudanças comuns. Um postmortem que esquece isso conclui que todos os envolvidos foram descuidados, o que quase nunca é verdade.

## A linha que continua existindo

Uma cultura justa ainda distingue **um erro honesto** da **imprudência**, pular de propósito uma salvaguarda sem motivo, e da má-fé, que são raras e assunto da gestão, não de um postmortem. O padrão, para todo o resto, é a segunda história. Um time que mantém esse padrão fica sabendo dos seus quase acidentes além dos seus incidentes, e é neles que está a maior parte do aprendizado.
