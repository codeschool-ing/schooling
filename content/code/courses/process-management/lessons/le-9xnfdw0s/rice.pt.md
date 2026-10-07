---
title: RICE
version: 1
---

O **RICE** é uma fórmula de pontuação do mundo da gestão de produto, publicada pelo time de produto da Intercom. É popular entre gerentes de produto porque pede números que times de produto costumam ter, e porque põe a **confiança** explicitamente na fórmula.

```localised
pontuação RICE = alcance × impacto × confiança / esforço
```

- **Alcance** (reach): quantas pessoas o item afeta num período — pacientes, recepcionistas, clínicas por trimestre.
- **Impacto**: quanto ele afeta cada uma, numa escala fixa: 3 para enorme, 2 para alto, 1 para médio, 0,5 para baixo, 0,25 para mínimo.
- **Confiança**: quão seguro o time está dos outros números, em percentual: 100% para evidência, 80% para um palpite razoável, 50% para um pressentimento.
- **Esforço**: pessoas-mês de trabalho.

## Três dos candidatos do time Agenda

| funcionalidade | alcance por trimestre | impacto | confiança | esforço | pontuação |
|---|---|---|---|---|---|
| lembretes por SMS | 4.000 pacientes | 1 | 80% | 1 | 3.200 |
| agendamento online | 2.500 pacientes | 3 | 50% | 4 | 937,5 |
| relatórios para donos de clínica | 300 donos e gerentes | 2 | 80% | 2 | 240 |

Os lembretes por SMS lideram de novo, por um motivo diferente do WSJF: alcançam muita gente com pouco esforço. O impacto alto do agendamento online é cortado pela **confiança de 50%**, porque o time ainda não sabe quantos pacientes vão agendar pela internet em vez de por telefone. É a fórmula funcionando como devia. O jeito mais barato de subir o agendamento online não é discutir o impacto, e sim **aumentar a confiança**, fazendo um experimento curto com uma clínica.

## RICE ou WSJF

As duas fórmulas respondem a perguntas diferentes. **O RICE ordena por valor por unidade de esforço**, e é mais forte quando a principal incerteza é sobre a demanda. **O WSJF ordena por custo do atraso por unidade de tamanho**, e é mais forte quando prazo e risco importam. O RICE não tem termo para criticidade de tempo, então a atualização do banco, valiosa sobretudo porque o suporte da versão antiga está acabando, pontuaria perto de zero; o WSJF não tem termo para confiança, então um pressentimento e uma medição pesam igual. Usar as duas no mesmo backlog, e olhar onde discordam, é um bom jeito de achar as suposições que valem ser conferidas.
