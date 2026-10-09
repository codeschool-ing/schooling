---
title: O que a amostragem muda
version: 2
---

A mesma verificação, numa execução diferente: um prompt, cinco amostras por mensagem com
temperatura 0,8, sobre as quarenta mensagens do dev.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
200 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/s5.jsonl
ana@lab:~/triage$ python3 selfcheck.py runs/s5.jsonl | tail -n 4
                 really wrong  really right
flagged                    33            84
not flagged                13            70
precision 0.28   recall 0.72
```

Das 200 respostas, 46 estavam de fato erradas. O revisor marcou 117 e pegou 33 das 46: revocação 0,72,
precisão 0,28. Contra uma moeda, marcar 117 de 200 ao acaso daria uma precisão de 46 em 200, 0,23, e
uma revocação de 0,59. Aqui também a verificação é um pouco melhor que o acaso, e não muito.

## Deslizes e equívocos

Há um motivo para esperar que a amostragem ajude um revisor. Uma resposta amostrada pode estar
errada de dois jeitos. Pode ser um **deslize**: o modelo preferia o rótulo certo, e o sorteio caiu
em outro. Ou pode ser um **equívoco**: o modelo prefere o rótulo errado, e o sorteio o
achou. Um revisor que lê a mensagem sem amostrar vê o rótulo que o modelo prefere, então deveria
pegar os deslizes e deixar passar os equívocos. Com temperatura 0 todo erro de rótulo é um
equívoco, já que a resposta é o rótulo preferido por definição, e por isso um revisor
deveria se sair melhor numa execução amostrada do que numa a 0.

Aqui a revocação foi de 0,69 para 0,72 e a precisão caiu de 0,40 para 0,28. A aula 19 mostrou por que
havia pouco para o argumento trabalhar: as amostras concordaram na maioria das mensagens, então a
maioria dos erros amostrados eram os mesmos equívocos da temperatura 0. E um revisor que
marca a maioria das respostas por um motivo inventado não melhora quando os erros ficam mais
fáceis. **Se a autoverificação ajuda é uma medição no seu modelo e nos seus ajustes**, e esta diz
que aqui ela mal ajuda. Uma revocação medida numa configuração diz pouco sobre outra, então meça a
verificação nos ajustes que você vai pôr em produção.

## O que outros encontraram

Para modelos maiores a pesquisa é dividida, e um resultado merece ser conhecido pelo nome. *Large
Language Models Cannot Self-Correct Reasoning Yet* (Huang e outros, 2023) pediu a modelos que
revisassem e corrigissem as próprias respostas a problemas de raciocínio sem informação de fora.
Concluiu que isso muitas vezes não as melhorava e às vezes as piorava, convencendo o modelo a trocar
uma resposta certa por uma errada. Os autores também apontaram que alguns relatos anteriores de
autocorreção funcionando dependiam de saber, de fora do modelo, quando uma resposta estava errada.

A leitura que esta aula tira das duas coisas é estreita: um modelo que confere a si mesmo sem
informação nova só tem a própria visão para conferir. Onde essa visão está certa e a resposta
escorregou, pode ajudar. Onde a visão está errada, ele concorda. E onde, como aqui, o modelo é
pequeno, pode ser que ele nem esteja conferindo muita coisa.
