---
title: O que ele sabe, e o que ele não sabe dizer que não sabe
version: 1
---

O conhecimento de um modelo é o que o texto de treino continha, comprimido nos parâmetros e
congelado no dia em que o treino parou, o **corte de treino**. Ele não consulta nada enquanto
escreve. Quando você faz uma pergunta, a resposta é a continuação provável da sua pergunta dado
aquele treino, e para um fato comum a continuação provável quase sempre é a verdadeira. Para um
fato raro, recente, ou que nunca esteve no texto de treino, **o laço ainda produz uma continuação
com cara de provável, porque produzir uma é a única coisa que ele sabe fazer.**

## O modelo pequeno numa pergunta que não é da conta dele

O `tinylm` foi treinado com a documentação do Python, que nunca fala da França. Pergunte assim
mesmo:

```
ana@dev:~/shop$ python lab/next.py "The capital of France is"
context used: 1 tokens
 11.5%  ' a'
  8.0%  ' the'
  5.9%  '\n'
  5.2%  ' not'
  3.8%  ' used'
ana@dev:~/shop$ python lab/generate.py "The capital of France is" --tokens 14 --temperature 0
The capital of France is a string, and
  A binascii.Error is raised if

```

`context used: 1 tokens`: ele nunca tinha visto `France is`, então recuou para o que vem depois de
` is` sozinho, e daí escreveu o que vem depois de ` is` no corpus dele. É o mesmo texto que a
execução gulosa da aula 1 seção 04 produziu depois de `The default value is`, pelo mesmo motivo.

**E ele não deu sinal nenhum disso.** Aqui ele está numa frase de que nunca viu parte alguma:

```
ana@dev:~/shop$ python lab/next.py "colourless green ideas"
context used: 0 tokens
  3.7%  ' the'
  3.0%  '\n'
  2.9%  ','
  2.4%  '.\n\n'
  2.0%  ' a'
```

Sem contexto nenhum, ele prevê os tokens mais comuns do corpus. A saída continua sendo uma
distribuição que soma 100%, e o laço de geração sortearia dela exatamente como antes. **Uma
distribuição não tem lugar para "nunca vi isto".** O script do laboratório imprime quanto contexto
usou porque o laboratório escreveu essa linha; a API de nenhum provedor devolve algo parecido.

## A versão de modelo grande da mesma coisa

Um modelo grande é muito melhor nisso que o `tinylm`, e consegue dizer "não sei", porque foi
treinado com exemplos de quem diz isso. Isso é um comportamento aprendido, porém, não uma medição:
o modelo não tem um sinal interno confiável que separe um fato que aprendeu de um fato que está
reconstruindo. Então ele comete esse erro justamente nas perguntas em que o texto de treino era
ralo, e comete no mesmo estilo fluente e confiante de todo o resto. Isso se chama **alucinação**, e
para quem desenvolve ela chega em três formas comuns:

- **uma API que não existe**: um nome de método que seria o óbvio, numa biblioteca que o batizou de
  outro jeito;
- **uma API que existia**: a versão de uma biblioteca de antes do corte de treino, com confiança,
  para código que roda contra a versão de depois;
- **um pacote que não existe**: um import plausível que ninguém nunca publicou, o que é pior que um
  erro de digitação, porque qualquer um pode publicá-lo depois (aula 11).

## Trabalhando com isso

Dois hábitos tornam quase tudo isso administrável, e cada um tem aulas por trás:

- **Ponha os fatos no contexto.** A documentação da versão que você usa, a mensagem de erro real, o
  código real. Um modelo continuando a partir do texto certo tem muito mais chance de acertar que um
  que tenta lembrar o texto do treino. A aula 5 é sobre fazer isso num prompt, a aula 6 sobre
  fazer isso automaticamente.
- **Confira o que volta contra algo que não é um modelo.** Rode o código, rode os testes, leia a
  fonte citada. As aulas 3 e 4 fazem disso o jeito normal de aceitar uma sugestão, e a aula 11 faz
  disso uma regra de desenho.
