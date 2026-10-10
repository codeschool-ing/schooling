---
title: Construir uma, adotar uma, ou ficar sem
version: 1
---

O `featurestore.py` tem todas as partes que uma feature store tem, e nada do que faz uma aguentar em
escala. **O que os produtos acrescentam é operação, não ideias:**

| um produto acrescenta | o que no `featurestore.py` é |
| --- | --- |
| um registro das visões de atributos, com donos e descrições | a docstring, e a memória da Ana |
| materialização numa agenda, com novas tentativas e alertas | um comando que alguém roda |
| um armazenamento online que serve milhares de leituras por segundo | um arquivo SQLite |
| monitoramento de atualidade por visão de atributos | nada |
| reuso: uma visão, lida por muitos modelos | um modelo |

O **Feast** é a de código aberto, e o vocabulário dele é o que a seção 03 usou: entidades, visões de
atributos, um armazenamento offline e um online, `materialize` e `get_historical_features`. Ele não
guarda nada próprio; ele conduz o warehouse e o armazenamento chave-valor que você já tem. As nuvens
vendem versões gerenciadas dentro das suas plataformas de aprendizado de máquina, e plataformas de
dados como o Databricks incluem uma. **Nenhuma delas foi rodada para este curso**, e nada aqui depende
de qualquer uma.

**Fique sem uma** enquanto um modelo lê um punhado de atributos de um warehouse, como a Ponto Final
faz hoje. Um `features.py` bem testado e a disciplina de calcular em relação a um corte dão a
reprodutibilidade; uma tabela noturna de notas em lote, que a lição 8 constrói, não precisa de
armazenamento online nenhum.

**Construa ou adote uma** quando o segundo modelo quiser os atributos do primeiro, quando um serviço
precisar de atributos em milissegundos, ou quando dois times começarem a calcular o mesmo atributo em
dois lugares. Esse último é o sinal a vigiar, porque é a diferença da lição 5 chegando pela
organização em vez de pelo código.
