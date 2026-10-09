---
title: O que ele sabe, e o que ele não sabe dizer que não sabe
version: 2
---

O conhecimento de um modelo é o que o texto de treino continha, comprimido nos parâmetros e
congelado no dia em que o treino parou, o **corte de treino**. Ele não consulta nada enquanto
escreve. Quando você faz uma pergunta, a resposta é a continuação provável da sua pergunta dado
aquele treino, e para um fato comum a continuação provável quase sempre é a verdadeira. Para um
fato raro, recente, ou que nunca esteve no texto de treino, **o laço ainda produz uma continuação
com cara de provável, porque produzir uma é a única coisa que ele sabe fazer.**

## Uma pergunta com resposta, e uma sem

O `next.py` da seção 06 mostra o que o modelo acha mais provável depois de uma frase. Aqui está
uma frase que ele leu milhares de vezes, e uma que ele nunca pode ter lido, porque o país foi
inventado para esta aula:

```
ana@dev:~/shop$ python scratch/next.py "The capital of France is"
 62.7%  ' Paris'
  8.4%  ' located'
  3.7%  '...'
  3.6%  ' not'
  3.2%  ' a'
ana@dev:~/shop$ python scratch/next.py "The capital of the Republic of Veldoria is"
 10.3%  ' the'
  5.8%  ' V'
  3.8%  ' a'
  3.4%  ' located'
  2.7%  ' not'
```

A primeira é um fato que o modelo aprendeu: um token com a maior parte da probabilidade. A
segunda está espalhada. **Mas continua sendo uma distribuição que soma 100%**, e o laço sorteia
dela exatamente como antes. Uma distribuição não tem lugar para "nunca vi isto". Deixe o laço
rodar:

```
ana@dev:~/shop$ python scratch/generate.py "The capital of the Republic of Veldoria is" --tokens 30 --temperature 0
The capital of the Republic of Veldoria is the city of Veldoria, which is located in the heart of the Veldorian Valley. The city is known for its rich history, cultural
```

Uma capital, um vale e uma história rica, para um país que não existe, no tom de uma
enciclopédia. Cada token foi a continuação mais provável do texto anterior, que é tudo o que o
laço jamais prometeu.

Agora a mesma pergunta como pergunta, pelo `ollama run`, que a embrulha no template de conversa do
modelo, do jeito que toda aplicação de chat faz:

```
ana@dev:~/shop$ ollama run llama3.2:3b "What is the capital of the Republic of Veldoria?"
I couldn't find any information on a country called the "Republic of
Veldoria". It's possible that it's a fictional country or not a recognized
sovereign state. If you could provide more context or details, I'll be
happy to help you further.
```

Isso é melhor, e a próxima parte desta seção diz por que não basta.

## Dizer "não sei" é um hábito, não uma medida

O modelo que inventou um vale e o modelo que recusou a pergunta são o mesmo modelo. A diferença é
o template de conversa: depois de treinado em texto, este modelo foi treinado mais um pouco em
conversas em que um assistente diz que não sabe, e o template o põe nesse papel. **Isso
é um comportamento aprendido, não uma medida.** O modelo não tem nenhum sinal interno confiável
que separe um fato que ele aprendeu de um fato que ele está reconstruindo, então ele recusa
quando a pergunta parece com as que aprendeu a recusar, e responde com fluência no resto. Um país
inventado é fácil de reconhecer. Uma função inventada não é:

```
ana@dev:~/shop$ ollama run llama3.2:3b "In Python's standard library, which function in the statistics module computes the harmonic median? Answer with one line of code."
The `statistics.hmean` function in Python's standard library computes the
harmonic mean.
```

**`statistics.hmean` não existe.** A função do módulo é `statistics.harmonic_mean`, e não há
mediana harmônica nele. A resposta dá nome a uma função plausível, troca a pergunta de mediana
para média sem avisar, e soa tão segura quanto a resposta sobre Paris. Pergunte você mesmo e pode
vir outra resposta errada, ou uma certa; a seção 08 explica por quê.

Isso se chama **alucinação**, e para um desenvolvedor ela chega em três formas comuns:

- **uma API que não existe**: um nome de método que seria o óbvio, numa biblioteca que deu outro
  nome, como acima;
- **uma API que existia**: a versão de uma biblioteca de antes do corte de treino, com confiança,
  para um código que roda contra a versão de depois;
- **um pacote que não existe**: um import plausível que ninguém nunca publicou, o que é pior que
  um erro de digitação, porque qualquer um pode publicá-lo depois (aula 11).

## Trabalhando com isso

Dois hábitos tornam quase tudo isso administrável, e cada um tem aulas por trás:

- **Ponha os fatos no contexto.** A documentação da versão que você usa, a mensagem de erro real, o
  código real. Um modelo continuando a partir do texto certo tem muito mais chance de acertar que um
  que tenta lembrar o texto do treino. A aula 5 é sobre fazer isso num prompt, a aula 6 sobre
  fazer isso automaticamente.
- **Confira o que volta contra algo que não é um modelo.** Rode o código, rode os testes, leia a
  fonte citada. As aulas 3 e 4 fazem disso o jeito normal de aceitar uma sugestão, e a aula 11 faz
  disso uma regra de desenho.
