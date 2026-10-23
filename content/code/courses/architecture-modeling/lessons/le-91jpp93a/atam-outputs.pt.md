---
title: Riscos, pontos de sensibilidade e trade-offs
version: 1
---

**A contribuição duradoura do ATAM é o vocabulário para o que uma revisão encontra.** Cinco palavras
separam tipos de achado que uma revisão menos cuidadosa junta sob o nome de *preocupações*, e a
separação muda o que acontece depois.

| termo | o que é | um exemplo da revisão da Carcará |
| --- | --- | --- |
| **risco** | uma decisão de arquitetura que pode levar um cenário de atributo de qualidade a não ser atendido | *a fila na frente das compras está dimensionada para 2.500 por minuto, e o pico do ano passado foi de 2.300; mais uma rota e ela não basta* |
| **não risco** | uma decisão julgada sólida para seus cenários, com o motivo | *os bloqueios de assento no Redis atendem o QS-01 com folga: medidos a 4.000 bloqueios por minuto no teste de carga* |
| **ponto de sensibilidade** | uma propriedade de um componente da qual uma qualidade depende fortemente | *o intervalo de sincronização dos celulares dos motoristas: o frescor da lista de passagens depende dele diretamente* |
| **ponto de trade-off** | um ponto de sensibilidade para duas ou mais qualidades que puxam em sentidos opostos | *o mesmo intervalo de sincronização: mais curto melhora a recusa de passagens canceladas, e custa bateria e dados móveis* |
| **tema de risco** | um padrão que vários riscos compartilham | *todo risco do lado das rodoviárias remonta à internet da rodoviária* |

## Por que as distinções importam

- **Um não risco é um achado.** Escrever *os bloqueios de assento no Redis estão bem, e aqui está a
  medição* poupa a próxima revisão de gastar uma hora nisso, e registra a evidência.
- **Um ponto de trade-off não é um risco a eliminar.** O intervalo de sincronização não pode ficar bom
  para as duas qualidades; ele só pode ser definido de propósito, por quem é dono do trade-off, e
  revisto quando os custos mudam. Tratá-lo como defeito desperdiça esforço; ignorá-lo o deixa nas mãos
  de quem editar a configuração.
- **Os temas de risco são o que abre o relatório.** Catorze riscos são uma lista; um tema, *a internet
  da rodoviária é um ponto único de falha para seis capacidades*, é uma decisão que a diretoria pode
  tomar.

## O tema que apareceu na Carcará

A revisão encontrou catorze riscos. Seis deles, em partes diferentes do sistema, voltavam ao mesmo
fato: cada uma das 26 rodoviárias tinha um único link de internet, e o modo balcão, os recibos com QR
das impressoras, o relatório de caixa do fim do dia, os estornos dos atendentes e mais duas coisas
paravam quando ele caía. Nenhum dos seis era grave sozinho; juntos, eram o maior risco para o São
João.

A decisão de Celeste, tomada na reunião com o tema diante dela, foi **um segundo link móvel nas doze
rodoviárias mais movimentadas antes do pico**, e o modo de venda off-line da aula 8 para as demais.
É para isso que existe o último passo do ATAM: **transformar uma lista de achados numa decisão que o
negócio consegue tomar**.
