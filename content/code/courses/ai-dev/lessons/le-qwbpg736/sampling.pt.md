---
title: "Escolhendo o próximo token: temperatura, top-p e sementes"
version: 1
---

A decodificação gulosa fica presa em laços, como a aula 1 seção 02 mostrou. Por isso, por padrão,
um modelo não pega o token mais provável: ele **sorteia um, com peso dado pelas probabilidades**.
Um token com 5% sai mais ou menos uma vez em vinte. Três ajustes mudam esse sorteio. Se você pode
mexer neles depende do provedor, como o fim desta seção mostra.

## Temperatura

**A temperatura muda a forma da distribuição antes do sorteio.** Abaixo de 1 ela a deixa mais
pontuda, e os tokens prováveis ficam mais prováveis ainda. Acima de 1 ela a achata, dando mais
chance aos raros. Em 0 o sorteio desaparece e o token do topo sempre ganha, o que é decodificação
gulosa de novo. O mesmo prompt e a mesma semente aleatória em três temperaturas:

```
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0 --seed 7
The default value is a string, and
  A binascii.Error is raised if
the C
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 7
The default value is treated as distinct calls with
a logging call was issued
                    (typically at
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 1.5 --seed 7
The default value is as follows: if the exit code of the format.  See documentation for details
```

Nenhum dos três quer dizer nada (este modelo tem uma memória de dois tokens), mas o caráter de
cada um é o que se espera de um modelo grande no mesmo ajuste. Em 0 o texto é a continuação mais
previsível. Em 1,5 ele pula de assunto em assunto, porque tokens que o modelo achava improváveis
estão sendo escolhidos com frequência.

## A semente

O sorteio precisa de uma fonte de aleatoriedade. Fixe-a, e a mesma distribuição dá os mesmos
sorteios. Troque-a, e o mesmo prompt na mesma temperatura dá outro texto:

```
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 1
The default value is not stored in the list, sorted by key.

To use a string containing all
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 2
The default value is the name.  The object is returned.

If a formatter is specified, it
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 0.7 --seed 3
The default value is a list of (n - 1)
    25: 70 years
```

**É por isso que a mesma pergunta a um modelo hospedado dá uma resposta diferente a cada vez.**
Algumas APIs de provedores nem deixam fixar a semente, e as que aceitam uma descrevem o resultado
como melhor esforço. Mesmo com temperatura 0, os provedores não prometem saída idêntica
para requisições idênticas: a aritmética no hardware deles não tem garantia de dar bit a bit o
mesmo resultado de uma requisição para a outra. **Não construa nada que dependa de um modelo se
repetir exatamente.** Se um teste precisa de uma resposta fixa, o teste não devia chamar um
modelo; a aula 4 volta a isso.

## Top-p

**O top-p corta a cauda antes do sorteio.** Ele mantém os tokens mais prováveis até as
probabilidades somarem *p*, e sorteia só entre eles. Com *p* em 0,5, o sorteio fica entre o
punhado de tokens que formam a metade mais provável da distribuição, por mais que a temperatura a
tenha achatado. Aqui está de novo a execução em 1,5, com esse corte:

```
ana@dev:~/shop$ python lab/generate.py "The default value is" --tokens 16 --temperature 1.5 --top-p 0.5 --seed 7
The default value is not of a type.

Class to open, read it, and it is omitted
```

Ainda sem sentido, mas mais perto do assunto que a execução sem corte. **Mude um dos dois ajustes,
não os dois**: eles agem sobre a mesma coisa, e mexer nos dois torna impossível dizer qual mudou a
saída. Alguns provedores também oferecem o **top-k**, que mantém um número fixo de tokens em vez de
uma fatia da probabilidade.

## Que APIs deixam mexer neles

São ajustes do sorteio, e o sorteio acontece do lado do provedor, então é o provedor quem decide
quais deles você pode mudar. O laboratório tem os SDKs atuais dos três provedores instalados, e
perguntar a cada um o que a chamada de geração aceita dá três respostas diferentes:

```
ana@dev:~/shop$ python lab/knobs.py
anthropic messages.create        (none of them)
openai chat.completions.create   temperature top_p seed
google GenerateContentConfig     temperature top_p top_k seed
```

**A API atual da Anthropic não aceita nenhum dos quatro.** O SDK `anthropic` não tem esse
argumento, e a referência da API, lida em 2 de outubro de 2026, não menciona nenhum: como os
modelos Claude sorteiam os tokens é decisão da Anthropic. O Chat Completions da OpenAI aceita
temperatura, top-p e semente, e o do Google acrescenta o top-k. A aula 10 põe as três APIs lado a
lado.

## O que usar em trabalho de programação, onde se pode

- **Código, extração, classificação: temperatura baixa**, de 0 a 0,3. Existe uma resposta certa, e
  variedade só acrescenta jeitos de errar.
- **Nomes, alternativas, ideias de teste: perto do padrão do provedor**, em muitos casos 1. Aqui a
  variedade é o objetivo, e você pode pedir várias e ficar com a melhor.
- **Deixe o resto no padrão** até ter um motivo medido para mexer. Um ajuste copiado de um post é um
  ajuste que ninguém do time consegue explicar depois.

Onde a API não oferece temperatura, os mesmos objetivos se alcançam na própria requisição: peça uma
resposta num formato fixo quando quiser consistência, e várias alternativas quando quiser
variedade. A aula 5 é sobre escrever essas requisições.
