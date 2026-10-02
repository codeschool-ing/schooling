---
title: A bancada em que este curso roda
version: 1
---

Todo comando deste curso foi executado, e cada linha de saída abaixo dele é o que o comando
imprimiu. Eles rodaram em um diretório, `~/pe`, em uma máquina Linux:

```
ana@lab:~/pe$ ls
bin
corpus.txt
handbook
node_modules
reviews
ana@lab:~/pe$ head -4 corpus.txt
the coffee is strong .
the soup of the day is tomato .
the cake is gone by noon .
bruno orders a coffee .
ana@lab:~/pe$ toylm info
corpus:        761 words in corpus.txt
vocabulary:    72 distinct words
trigram rows:  152 contexts, 212 counts
bigram rows:   72 contexts, 152 counts
parameters:    436 stored counts
```

**Não há nenhum grande modelo de linguagem nesta máquina, e nenhum era alcançável a partir dela.**
Isso é um fato simples sobre como o curso foi gravado, e decide como ele é escrito:

- o que um programa **de verdade** imprimiu aparece como transcrição, com o prompt `ana@lab:~/pe$`
  na frente do comando. Isso é captura, e você pode reproduzir cada uma;
- o que um modelo grande **poderia** responder aparece num bloco simples, sem prompt, e a frase
  antes dele diz que foi escrito por este curso como ilustração. Os modelos mudam de um mês para
  outro, e uma resposta inventada e apresentada como captura seria exatamente a falha contra a qual
  a lição 5 avisa.

As ferramentas em `bin` são pequenas e estão impressas por inteiro no `lab.sh`, o arquivo que monta
a bancada:

| ferramenta | o que é | usada pela primeira vez em |
|---|---|---|
| `toylm` | o modelo de trigramas do `corpus.txt`, com os controles de amostragem de uma API de modelo | esta lição |
| `tok` | um tokenizador **de verdade**, as codificações que a OpenAI publica para os seus modelos | esta lição, logo abaixo; a lição 3 o explica |
| `validate`, `repair` | conferir uma resposta contra um JSON Schema, e recuperar uma que veio embrulhada | lições 15 e 19 |
| `retrieve` | busca por palavras-chave no `handbook/`, o manual de equipe de um café | lição 5 |
| `agent` | o laço que roda ferramentas para um modelo, com os seus limites e recusas | lição 6 |
| `vote`, `tot`, `ape` | autoconsistência, uma árvore de pensamentos, pontuação de prompts | lições 27, 28 e 31 |

O `tok` é a única ferramenta daqui que um sistema em produção também usa. Ele não chama nenhum
modelo:

```
ana@lab:~/pe$ tok show "The café opens at seven."
"The" " café" " opens" " at" " seven" "."
976 30469 24061 540 12938 13
6 tokens, 24 characters (o200k_base)
```

**O café, o seu manual e as suas avaliações foram escritos para o curso**, e o Café Aurora não
existe. Os endereços de e-mail terminam em `example.com`, o domínio reservado para exemplos.

::: track ai security
As ferramentas são escritas em Python e JavaScript, e você conheceu Python no curso `python`. Ler
uma delas é um bom jeito de conferir o que uma lição afirma: o `toylm` tem umas duzentas linhas, e a
função que transforma contagens em porcentagens ocupa quatro delas.
:::

::: track *
Você não precisa ler nem escrever código neste curso. Cada lição diz o que um comando faz e o que
olhar no que ele imprimiu. As ferramentas são Python e JavaScript, e estão no `lab.sh` para quem
quiser conferir uma afirmação contra o programa que a produziu.
:::

## Acompanhando em casa

Para rodar os mesmos comandos você precisa de uma máquina Linux (uma máquina virtual serve, e o WSL
no Windows também) com Python 3.11 ou mais novo e Node.js 20 ou mais novo:

```
ana@lab:~/pe$ python3 --version; node --version
Python 3.11.15
v20.20.0
```

O `sudo bash lab.sh tools` baixa as duas bibliotecas de que as ferramentas precisam, e o
`sudo bash lab.sh reset` monta o `~/pe` para um usuário chamado `ana`. Cada lição que mostra uma
transcrição tem um `captures.sh` ao lado, que roda todos os comandos daquela lição, em ordem.

**Quando você mesmo usar um modelo de verdade**, numa janela de chat ou com uma chave de API sua, as
respostas vão ser diferentes das ilustrações deste curso, e vão mudar entre duas execuções do mesmo
prompt. Isso não é sinal de que algo está errado. A lição 13 é sobre exatamente isso.
