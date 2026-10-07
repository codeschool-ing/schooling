---
title: O que é enriquecimento
version: 1
---

**Enriquecer** é acrescentar colunas vindas de uma fonte de fora do conjunto de dados: uma região
para cada estado, um código oficial para cada cidade, uma marca em cada data que foi feriado, uma
taxa de câmbio para cada nota. A aula 7 já fez isso uma vez, quando converteu as notas com as taxas
que o financeiro registrou. Esta aula trata disso como uma técnica à parte, porque traz riscos que
as outras aulas não trazem.

Mecanicamente, enriquecer é uma junção, e tudo o que a aula 11 disse vale: conferir a chave dos
dois lados, usar `validate`, contar as linhas que ficaram sem par. O que é novo é o outro lado da
junção. **A tabela de referência é dado de outra pessoa**, e chega com quatro perguntas presas a
ela:

- **Quem publicou**, e é a autoridade no que afirma? Uma lista de códigos de estado do instituto
  nacional de estatística é; a mesma lista copiada num blog não é.
- **Quando**, e ela muda? Os códigos dos estados estão estáveis há décadas; feriados mudam por lei,
  e uma lista feita no ano passado pode estar errada neste.
- **Em que termos** ela pode ser usada, copiada e repassada junto com os seus resultados?
- **O que você mandou para obtê-la?** Baixar um arquivo público não manda nada. Chamar um serviço
  web com os CEPs dos seus clientes manda dados pessoais para quem o opera.

O laboratório guarda três arquivos de referência em `ref/`, e diferente de tudo em `raw/` eles são
reais: os códigos do IBGE para as 27 unidades da federação e para as cinco cidades que a empresa
atende, e os feriados nacionais e pontos facultativos de 2025. Foram digitados no gerador da aula 1
a partir das listas publicadas, o que já é um fato de procedência que vale registrar, e a quinta
seção desta aula registra.

Enriquecer também limpa. Uma coluna com treze grafias de quatro estados, casada com a lista
oficial, sai como quatro códigos; uma coluna de cidade com vinte e oito grafias de cinco
cidades sai como cinco códigos do IBGE.
**Uma tabela de referência é a normalização mais forte que existe**, porque as grafias de destino
não foram escolhidas por você.
