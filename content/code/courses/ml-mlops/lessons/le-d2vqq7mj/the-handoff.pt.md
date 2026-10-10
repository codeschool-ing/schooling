---
title: O que pedir antes de assumir um modelo
version: 1
---

Um modelo chega a um engenheiro de dados como algo que alguém fez. **O que chega junto com ele decide
se ele pode ser rodado, verificado e treinado de novo por outra pessoa**, e a hora de pedir o que
falta é antes da entrega, não na noite em que ele quebra.

| peça | por quê | na Ponto Final |
| --- | --- | --- |
| **o rótulo, definido em código** | uma frase que o descreve são duas implementações esperando para divergir | `features.py`, a linha do `NOT EXISTS` |
| **o tempo de maturação do rótulo** | ele decide a distância entre treino e teste, e quando a qualidade pode ser medida | 90 dias |
| **os atributos, definidos em código, em relação a um corte** | o mesmo código precisa servi-los, ou haverá diferença | `features.py` |
| **a definição do modelo, separada dos dados de treino** | para ele poder ser ajustado de novo em linhas novas | `model.py` |
| **a nota que decide, e a sua linha de base** | para um modelo treinado de novo ser julgado do mesmo jeito | precisão média contra a taxa de base, e afastamentos nos 300 primeiros |
| **as faixas de entrada esperadas** | elas viram o contrato de dados | as verificações do `validate.py` |
| **quem usa a saída, e como** | isso decide a publicação e o limiar | o marketing, trezentos vouchers por mês |
| **quem chamar quando ele errar** | um modelo tem um dono depois de ir ao ar, ou não tem nenhum | a Ana, neste curso |

A maior parte da tabela nem é modelagem. É o mesmo conjunto de perguntas que um engenheiro de dados
faz a qualquer produto de dados novo: o que significa, como é calculado, quando está completo, quem
o lê, o que acontece quando atrasa. **Um modelo é um produto de dados cuja saída é um palpite sobre o
futuro**, o que só acrescenta uma pergunta: como alguém vai descobrir se os palpites acertaram? A
lição 9 é a resposta a isso.
