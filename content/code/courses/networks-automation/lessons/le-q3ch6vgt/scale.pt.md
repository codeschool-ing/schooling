---
title: A aritmética da escala
version: 1
---

O script levou este tempo para três roteadores:

```
real	0m3.539s
user	0m0.238s
sys	0m0.137s
```

`real` é o tempo de relógio, do momento em que o comando começou até o prompt voltar: **3,539
segundos para três roteadores**, pouco mais de um segundo cada, quase todo gasto entrando e
esperando prompts. Os roteadores do laboratório são namespaces num só computador, então uma rede
real soma suas próprias idas e voltas a cada login. A forma da conta não muda.

Agora ponha uma suposição ao lado, e chame-a assim: **uma pessoa que leva dois minutos por
roteador** para abrir a sessão, digitar a linha, conferir e salvar. É um palpite, não uma medida,
e o argumento sobrevive a qualquer palpite razoável:

| roteadores | à mão, a 2 minutos cada | o script, em sequência |
|---|---|---|
| 3 | 6 minutos | segundos |
| 100 | 3 horas e 20 minutos | cerca de 2 minutos |
| 1.000 | 33 horas | cerca de 20 minutos |

A coluna do script é uma extrapolação do segundo e pouco por roteador medido acima, então leia-a
como um tamanho e não como uma promessa. **Duas coisas crescem com o número de roteadores quando
o trabalho é manual, e só uma delas é tempo.** A outra é o número de chances de cometer os erros
da seção anterior: mil sessões são mil oportunidades de digitar `192.0.12.0`.

Um script também não precisa trabalhar em sequência. O Nornir, na aula 8, roda a mesma tarefa em
muitos equipamentos ao mesmo tempo, o que transforma "cerca de 2 minutos" em pouco mais que o
tempo do roteador mais lento.

**A escala também é o motivo de uma mudança precisar de um plano para quando der errado.** Os
vinte minutos que levam uma mudança correta a mil roteadores levam uma errada com a mesma
rapidez. A aula 13 trata de testar uma mudança em um equipamento antes dos outros.
