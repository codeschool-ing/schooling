---
title: Com que velocidade ele responde
version: 1
---

Caber na memória diz se um modelo roda. **Com que velocidade ele gera** vem de um segundo número
sobre a mesma memória: quantos bytes por segundo o acelerador consegue ler dela, a **largura de
banda de memória**.

O motivo é o jeito como a geração funciona. Para produzir cada token novo, o runtime multiplica o
estado atual por **todos os pesos do modelo**, uma vez. Para uma requisição sozinha, a aritmética é
rápida e a espera é pelos pesos chegando da memória. Então um teto aproximado de velocidade, para uma
conversa de cada vez, é:

**tokens por segundo ≈ largura de banda ÷ tamanho dos pesos**

O `size.py` recebe a largura de banda como argumento e imprime esse teto para os pesos em 4 bits. Os
dois valores abaixo são **suposições do curso**, escolhidas para mostrar o formato, não
especificações de produto nenhum: 1.000 GB/s, e o triplo disso.

```
ana@desk:~/desk$ python size.py 1000 | cut -c1-17,76-
model            at 4-bit
Llama-3.1-8B          249
Llama-3.1-70B          28
Llama-3.1-405B          5
ana@desk:~/desk$ python size.py 3000 | cut -c1-17,76-
model            at 4-bit
Llama-3.1-8B          747
Llama-3.1-70B          85
Llama-3.1-405B         15
```

O 8B em 4 bits conseguiria produzir até uns 249 tokens por segundo com 1.000 GB/s; o 405B, uns 5.
Runtimes reais chegam a uma fração desses tetos, e o cache da seção 03 também precisa ser lido, o
que pesa mais conforme o contexto cresce.

## O que os números significam para quem lê

Cinco tokens por segundo é mais lento do que uma pessoa lê. Uma resposta de 300 tokens leva um
minuto para aparecer. Para a tarefa de classificação da ana, que responde em uns dois tokens, isso
mal importaria; para rascunhar uma resposta que alguém está esperando, decide.

## Muitas requisições ao mesmo tempo

Um servidor raramente atende uma conversa só. Runtimes feitos para servir juntam requisições em
**lotes** (*batching*): os pesos são lidos uma vez por passo e usados para todas as requisições do
lote, então a vazão total sobe bem acima do número de uma requisição sozinha, enquanto cada uma fica
um pouco mais lenta. É assim que um provedor de API faz a conta fechar, e é por isso que
auto-hospedar sai mais barato por token quando a máquina está **ocupada**. Um acelerador parado
custa por hora o mesmo que um ocupado, que é a frase que a seção 06 transforma em dinheiro.
