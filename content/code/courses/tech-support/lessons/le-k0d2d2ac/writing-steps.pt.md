---
title: Escrevendo um passo que alguém consegue seguir
version: 1
---

A maioria dos runbooks falha nos passos, e as falhas têm nome:

| um passo fraco | por que falha | bem escrito |
|---|---|---|
| "Verifique a impressora." | verificar o quê, como, e depois o quê? | "`lpstat -p QUEUE`. Esperado: `disabled`, com um motivo." |
| "Reinicie o CUPS se necessário." | quem decide o "necessário"? e um reinício interrompe o que todas as outras filas estão imprimindo | não é passo deste runbook: se a fila não voltar, escalone |
| "Habilite a fila e confira." | duas ações, e "confira" não é um resultado | o passo 4 e o passo 5, cada um com o que deve mostrar |
| "Resolva o papel preso." | o técnico pode estar em outro prédio | "Peça a quem está perto da impressora para…, e espere a confirmação." |

**Todo passo tem um resultado esperado**, porque é assim que quem segue sabe se pode continuar. E **todo
runbook é testado por alguém que não o escreveu**, seguindo exatamente, numa ocorrência real ou encenada. O
autor não consegue testar: ele preenche cada lacuna de memória sem perceber que ela existe.
