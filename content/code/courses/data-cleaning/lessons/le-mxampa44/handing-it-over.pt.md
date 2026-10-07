---
title: Passando adiante
version: 1
---

O teste de tudo nesta aula é uma pessoa que não estava lá. Alguém entra na equipe no mês que vem, ou
um auditor pergunta como um número foi produzido, ou o próximo curso, `visualization`, precisa de
dados limpos para desenhar. O que essa pessoa deve receber é curto:

1. **O repositório**, num commit identificado: o código, os mapas, `sources.csv`, `raw.sha256`.
2. **Os arquivos brutos**, ou onde obtê-los, batendo com o manifesto.
3. **Um comando**, `python run.py && python checks.py`, que reconstrói `out/` e prova que as
   promessas valem.
4. **O `out/changes.csv`**, que lista todo valor diferente do que chegou, e por quê.

Nada mais deveria ser necessário, e em especial nada que more só na cabeça de alguém. Toda decisão
deste curso, da escolha da aula 2 de ler tudo como texto à escolha da aula 14 de não mandar CEPs a um
serviço web, está num arquivo ou numa regra no código.

Vale listar, uma última vez, o que os dados limpos **não** prometem, porque uma passagem de bastão
que só lista conquistas convida ao excesso de confiança:

- **O NPS da pesquisa descreve quem respondeu**, não os clientes; a aula 3 mediu a diferença.
- **Os tempos de entrega da frota própria param em 120 minutos**, e os vazios não são aleatórios.
- **246 pedidos não têm cadastro de cliente**, por dois motivos diferentes, e os 12 clientes
  eliminados precisam continuar sem identificação.
- **Os dois códigos de produto fora do catálogo não têm nome nem categoria.**

Um pipeline que declara os seus limites ao lado das saídas é a última peça do argumento do curso:
**dado limpo não é dado sem problemas; é dado cujos problemas são conhecidos, medidos e escritos.**
