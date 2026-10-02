---
title: De pontuações a uma escolha
version: 1
---

É tentador imaginar um modelo decidindo a próxima palavra. **O que ele produz é uma pontuação para
cada palavra que poderia escrever em seguida**, e uma etapa separada, o amostrador, transforma essas
pontuações numa escolha. Temperatura, top-k e top-p são configurações dessa etapa e de mais nada. O
`prompt-engineering` os apresentou nas aulas 13 e 14. Esta aula os retoma de propósito e os mede na
tarefa de triagem, onde uma resposta sorteada está certa ou errada.

O laboratório tem um amostrador que dá para rodar sozinho. As pontuações são de uma frase, *Your
parcel is ___*, e foram escritas pelo curso; não foram lidas de modelo nenhum:

```
ana@lab:~/triage$ grep -A1 '^NEXT' promptlab/sample.py
NEXT = [("on", 3.1), ("delayed", 2.6), ("here", 1.9), ("lost", 1.2),
        ("ready", 1.0), ("wet", -0.4), ("singing", -2.5), ("purple", -3.0)]
ana@lab:~/triage$ pl sample
Your parcel is ___   temperature 1, top-k off, top-p 1, 1000 draws
  on         45.1%    490  ##################
  delayed    27.4%    243  ###########
  here       13.6%    122  #####
  lost        6.7%     67  ###
  ready       5.5%     64  ##
  wet         1.4%     12  #
  singing     0.2%      2  
  purple      0.1%      0  
```

Cada linha é uma candidata, a probabilidade dela, quantos de 1.000 sorteios a escolheram, e uma
barra. **Softmax é a etapa que transforma pontuações em probabilidades**: eleve *e* a cada
pontuação, depois divida cada resultado pelo total, para que tudo some um. Só as diferenças entre
pontuações importam. `on` tem 0.5 a mais que `delayed`, e *e* elevado a 0.5 dá cerca de 1,65, que é
a razão entre 45.1% e 27.4%.

As contagens são uma amostra dessas probabilidades, e oscilam como amostras oscilam. `lost` é a mais
provável das duas, com 6.7% contra 5.5%, e `ready` chegou perto dela, 64 sorteios contra 67.
`purple`, com 0.1%, não saiu nenhuma vez em mil tentativas; a um milhão de chamadas por dia, seria
escrita umas mil vezes.

## A mesma engrenagem no substituto

O substituto faz a mesma coisa com as pontuações das categorias. Com temperatura 0 ele fica com o
rótulo de pontuação mais alta. Acima de 0 ele passa as cinco pontuações para a mesma função,
`distribution` em `promptlab/sample.py`, e sorteia um rótulo. Então tudo o que esta aula mostra em
*Your parcel is ___* acontece também com as respostas da triagem, e a última seção conta quanto
isso custa.
