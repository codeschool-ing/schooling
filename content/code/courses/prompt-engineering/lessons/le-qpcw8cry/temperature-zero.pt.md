---
title: Temperatura 0 e a mesma resposta duas vezes
version: 2
---

Na temperatura 0 não há sorteio. **A palavra de nota mais alta é escolhida todas as vezes**, e essa
regra tem nome: decodificação gulosa (*greedy decoding*). O `toylm dist` mostra o que sobra para
escolher:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 0
context: trigram after 'coffee is'
  hot      100.0%  ########################################
```

Uma palavra com toda a fração. A semente decide como um sorteio sai, então duas execuções com
sementes diferentes são o jeito de conferir se algo foi sorteado:

```
ana@lab:~/pe$ toylm generate "the coffee is" --temperature 0 --seed 1
hot.
-- finish: end, prompt 3 tokens, output 2 tokens
ana@lab:~/pe$ toylm generate "the coffee is" --temperature 0 --seed 2
hot.
-- finish: end, prompt 3 tokens, output 2 tokens
```

O mesmo texto, a mesma parada, a mesma contagem. Na temperatura 1 as mesmas sementes dão frases
diferentes, porque ali a semente trabalha:

```
ana@lab:~/pe$ toylm generate "the coffee is" --temperature 1 --samples 3
[seed 1] hot.
[seed 2] cold and the cat wakes.
[seed 3] hot.
```

**Na temperatura 0, o `toylm` é determinístico: o mesmo prompt dá a mesma saída em toda execução,
em qualquer máquina.** É isso que você quer de um teste, de um processo que extrai campos de
documentos, ou de qualquer coisa cuja saída outro programa vai ler.

## Quando duas palavras empatam

A decodificação gulosa precisa de uma vencedora, e às vezes não há:

```
ana@lab:~/pe$ toylm next "is the"
context: trigram after 'is the'
  bread     33.3%  #############
  coffee    33.3%  #############
  soup      33.3%  #############
ana@lab:~/pe$ toylm dist "is the" --temperature 0
context: trigram after 'is the'
  bread    100.0%  ########################################
```

Três palavras dividem a nota do topo exatamente, e o `toylm` ficou com `bread`. Nada no café
escolheu isso. O programa ordena as palavras empatadas em ordem alfabética, então `bread` ganha
sempre, e a saída se mantém igual porque o empate é desfeito por uma regra.

## Num modelo hospedado, quase determinístico e sem garantia

**Um modelo atrás de uma API na temperatura 0 é quase determinístico, e os provedores não prometem
mais do que isso.** Duas requisições com o mesmo prompt geralmente devolvem o mesmo texto, e às
vezes não. Os motivos estão na maquinaria em volta do modelo, não na ideia de temperatura:

- um modelo grande calcula as notas com aritmética de ponto flutuante em muitos processadores ao
  mesmo tempo, e a ordem em que as somas parciais são feitas pode mudar entre requisições. Quando
  dois tokens estão quase empatados, uma diferença no último dígito pode trocar o que fica no topo.
  Depois de um token diferente, o resto do texto segue outro caminho;
- as requisições muitas vezes são agrupadas com as de outras pessoas e rodadas juntas, e o jeito
  como um lote é formado pode mudar a aritmética;
- o modelo por trás de um nome pode ser atualizado, o que muda tudo de uma vez.

Algumas APIs também aceitam uma semente, que torna a saída sorteada repetível mais vezes. Leia o
que a documentação do provedor diz garantir, e a data daquela página, antes de construir em cima
disso. Meça no seu: mande o mesmo prompt várias vezes na temperatura 0 e compare. No modelo local, dez
vezes:

```
ana@lab:~/pe$ for i in 1 2 3 4 5 6 7 8 9 10; do ask "In one sentence, describe the coffee at a small café." --temperature 0 --plain; done | sort | uniq -c
     10 The café's coffee is a specialty blend of expertly roasted beans, carefully selected to bring out a rich, smooth flavor with hints of chocolate and a subtle acidity that complements the cozy, intimate atmosphere of the small café.
```

Dez respostas, um texto só. Isso é um prompt curto numa máquina, e não é uma taxa. Enquanto este
curso era gravado, o mesmo modelo na temperatura 0 deu, sim, duas respostas diferentes ao mesmo
prompt mais longo em duas execuções, nas lições 4, 6 e 7. Cada transcrição ali é uma execução, e a
frase embaixo dela descreve aquela execução.

**A regra prática: a temperatura 0 torna a variação rara, e o seu código ainda precisa lidar com
ela.** Um programa que quebra quando duas respostas diferem numa palavra ia quebrar de qualquer
jeito, no dia em que o modelo por trás do nome mudasse.

A temperatura 0 também não torna uma resposta certa. Ela faz o modelo dar a resposta mais provável
todas as vezes. Quando a resposta mais provável está errada, você recebe a mesma resposta errada em
toda execução, e uma resposta errada que nunca muda parece um fato. A lição 5 trata de por que o
provável e o verdadeiro podem se separar.
