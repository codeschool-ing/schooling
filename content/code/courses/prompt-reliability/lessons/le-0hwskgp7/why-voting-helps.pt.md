---
title: Por que uma votação pode ajudar
version: 1
---

Um ensemble faz a mesma pergunta várias vezes e fica com a resposta que a maioria deu. A ideia é
antiga, e o `prompt-engineering` viu uma forma dela na aula 27, a autoconsistência. **Esta aula
volta a ela de propósito**, com a pergunta deste curso: em setenta mensagens com respostas
conhecidas, a votação ganha mesmo do prompt sozinho, e quanto ela custa?

Antes de medir, vale saber o que uma votação consegue fazer no melhor caso, porque a conta é curta
e dá nome à suposição da qual todo o resto depende.

## Três votantes a 80%

Pegue três votantes, cada um certo 80% das vezes, e suponha que **os erros de cada um não tenham
nada a ver com os dos outros**. A maioria acerta quando os três acertam, ou quando exatamente dois
acertam.

Os três certos: 0,8 × 0,8 × 0,8 = 0,512.

Exatamente dois certos: há três jeitos de escolher qual erra, e cada jeito tem probabilidade
0,8 × 0,8 × 0,2 = 0,128, então 3 × 0,128 = 0,384.

A maioria acerta 0,512 + 0,384 = **0,896** das vezes. Três votantes a 80% fazem um votante de quase
90%, sem que nenhum deles tenha melhorado em nada.

A mesma soma com outras acurácias mostra o formato. Três votantes a 60% dão uma maioria certa
0,648 das vezes, um ganho menor. Três a 40% dão 0,352, o que é **pior que qualquer um deles**: uma
maioria de votantes que costumam errar erra com mais regularidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Acurácia da maioria de três votantes independentes contra a acurácia de cada um. A curva fica acima da diagonal quando cada votante acerta mais da metade das vezes e abaixo quando acerta menos: em 0,8 a maioria acerta 0,896 das vezes, em 0,4 só 0,352.\"><path d=\"M110 290 L390 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110 290 L110 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"110\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0</text><text x=\"102\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,0</text><text x=\"250.0\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><text x=\"102\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><text x=\"390\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><text x=\"102\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,0</text><text x=\"250.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada votante acerta</text><text x=\"70\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a maioria de três acerta</text><path d=\"M110 290 L390 40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M110.0 290.0 L112.8 289.9 L115.6 289.7 L118.4 289.3 L121.2 288.8 L124.0 288.2 L126.8 287.4 L129.6 286.5 L132.4 285.5 L135.2 284.3 L138.0 283.0 L140.8 281.6 L143.6 280.1 L146.4 278.4 L149.2 276.7 L152.0 274.8 L154.8 272.8 L157.6 270.8 L160.4 268.6 L163.2 266.4 L166.0 264.0 L168.8 261.6 L171.6 259.0 L174.4 256.4 L177.2 253.7 L180.0 250.9 L182.8 248.1 L185.6 245.2 L188.4 242.2 L191.2 239.1 L194.0 236.0 L196.8 232.8 L199.6 229.6 L202.4 226.3 L205.2 223.0 L208.0 219.6 L210.8 216.1 L213.6 212.7 L216.4 209.1 L219.2 205.6 L222.0 202.0 L224.8 198.4 L227.6 194.7 L230.4 191.1 L233.2 187.4 L236.0 183.7 L238.8 180.0 L241.6 176.2 L244.4 172.5 L247.2 168.7 L250.0 165.0 L252.8 161.3 L255.6 157.5 L258.4 153.8 L261.2 150.0 L264.0 146.3 L266.8 142.6 L269.6 138.9 L272.4 135.3 L275.2 131.6 L278.0 128.0 L280.8 124.4 L283.6 120.9 L286.4 117.3 L289.2 113.9 L292.0 110.4 L294.8 107.0 L297.6 103.7 L300.4 100.4 L303.2 97.2 L306.0 94.0 L308.8 90.9 L311.6 87.8 L314.4 84.8 L317.2 81.9 L320.0 79.1 L322.8 76.3 L325.6 73.6 L328.4 71.0 L331.2 68.4 L334.0 66.0 L336.8 63.6 L339.6 61.4 L342.4 59.2 L345.2 57.2 L348.0 55.2 L350.8 53.3 L353.6 51.6 L356.4 49.9 L359.2 48.4 L362.0 47.0 L364.8 45.7 L367.6 44.5 L370.4 43.5 L373.2 42.6 L376.0 41.8 L378.8 41.2 L381.6 40.7 L384.4 40.3 L387.2 40.1 L390.0 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"334.0\" cy=\"65.99999999999997\" r=\"4\" fill=\"var(--amber)\"></circle><path d=\"M334.0 90.0 L334.0 65.99999999999997\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"222.0\" cy=\"202.0\" r=\"4\" fill=\"var(--amber)\"></circle><path d=\"M222.0 190.0 L222.0 202.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"324.0\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0,8 → 0,896</text><text x=\"232.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0,4 → 0,352</text><path d=\"M470 120 L500 120\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"510\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">maioria de três</text><path d=\"M470 150 L500 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"510\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um votante</text></svg>", "caption": "Três votantes independentes. Acima da metade, votar torna um bom votante melhor; abaixo, torna um votante fraco pior. As duas pontas supõem que os três são independentes."}
```

## A suposição

Tudo isso se apoia numa palavra, *independentes*. É ela que permite multiplicar: a chance de dois
votantes errarem juntos é 0,2 × 0,2 = 0,04, porque o erro de um não torna o do outro mais provável.

Agora suponha que os três cometam **os mesmos erros nas mesmas mensagens**. Então, quando um erra,
os outros erram junto, a chance de dois errarem juntos é o 0,2 inteiro, e a maioria é exatamente
tão boa quanto um votante. Ensembles reais ficam em algum ponto entre esses dois extremos, e é esse
ponto que decide se a votação vale o que custa. A próxima seção o mede em três prompts deste curso.
