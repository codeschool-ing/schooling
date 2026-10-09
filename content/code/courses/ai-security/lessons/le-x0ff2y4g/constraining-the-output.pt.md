---
title: Duas fronteiras que o modelo não consegue cruzar
version: 1
---

A seção anterior pediu ao modelo que se comportasse. Esta muda **o que o modelo é capaz de produzir,
e o que a saída dele é capaz de alcançar**. Nenhuma das duas depende de o modelo decidir alguma coisa.

## Restringir o que pode sair

A aula 9 conferiu uma resposta contra um esquema depois que o modelo a escreveu. Um servidor com saída
estruturada pode fazer mais: ele **impõe o esquema enquanto o modelo escreve**, escolhendo a cada passo
só entre os tokens que mantêm a resposta válida. O Ollama faz isso com um JSON Schema enviado em
`response_format`, e a maioria dos fornecedores pagos também. Com `--schema`, as únicas respostas que o
modelo consegue produzir são `{"category": "refund"}` e suas três irmãs:

```
ana@lab:~/guard$ guard classify data/tickets.jsonl --schema --show
t1   refund    ok
t2   delivery  ok
t3   account   ok
t4   refund    ok
t5   delivery  ok
t6   account   ok
t7   refund    ok
t8   delivery  WRONG  other
     reply: {"category": "other"}
t9   account   ok
t10  other     ok
t11  other     ok
t12  refund    ok
layout plain with schema: 11 right, 0 rejected to a person, 1 wrong and accepted
```

**Onze certos, e nada para recusar.** Nenhum poema, nenhuma letra maiúscula, nenhum `URGENT`, nenhum
ticket copiado de volta, porque nada disso pode ser escrito num espaço de quatro respostas. Os pedidos
nos tickets não deixaram de ser pedidos; perderam o meio de aparecer na saída.

O `t8` continua errado, e o esquema não ajuda com ele. O ticket pediu para não ser classificado e o
modelo escolheu `other`, um valor válido. **Uma saída restrita pode estar errada dentro do conjunto
permitido**, e esse é o risco residual para o qual se projeta. Aqui ele é limitado: uma categoria move
um ticket para uma fila que pessoas leem, então o pior caso é um ticket que uma pessoa move para a fila
certa, alguns minutos atrasado. Medir com que frequência isso acontece, com muito mais que doze
tickets, é o que a aula 26 automatiza.

A regra vale além das categorias. **Todo campo sobre o qual o código age deveria ser do tipo mais
estreito que resolve**: uma escolha numa lista fechada, um número com faixa, o id de algo que existe.
Texto livre é o tipo mais largo que há, e só cabe onde uma pessoa o lê.

## Separar o que lê do que age

A segunda fronteira é sobre para onde a saída vai. O classificador lê texto escrito por clientes, então
o classificador **não tem ferramentas**: a única coisa que pode fazer é nomear uma de quatro filas. O
código que age sobre o ticket, abrindo um reembolso ou escrevendo ao freelancer, lê essa uma palavra e
nunca o texto do cliente.

Essa divisão tem nome, o **padrão de dois LLMs** (*dual LLM pattern*), descrito por Simon Willison em
2023. Um modelo em quarentena lê material não confiável e devolve valores fechados, e uma parte
privilegiada da aplicação, que pode ser outro modelo com ferramentas ou código comum, age sobre esses
valores sem ver o material. Aplicado à Tarefa:

| parte | lê o texto do cliente? | pode chamar ferramentas? | o que entrega adiante |
|---|---|---|---|
| classificador | sim | não | uma de quatro categorias |
| agente de suporte da aula 10 | só o que o código lhe passa | sim, atrás do portão | propostas sobre as quais o portão decide |
| o portão | não | decide, nunca propõe | ALLOW, HOLD ou DENY |

O agente de suporte da aula 10 é o caso difícil, porque precisa ler a mensagem do cliente para ter
alguma utilidade, e pode propor chamadas. É por isso que o portão existe, e que o escopo dele vem da
sessão e não de algo que o modelo escreveu. **Quanto mais um LLM lê, menos ele deveria poder fazer**, e
onde ele precisa fazer as duas coisas, decide um portão com quem o modelo não consegue conversar.

Nenhuma das três camadas desta aula é completa sozinha. Uma frase sobre o material é de graça e às
vezes ajuda. Um esquema elimina uma classe inteira de resposta. A divisão mantém o texto em que não se
pode confiar longe das partes que podem agir. A aula 15 aplica o mesmo raciocínio ao fluxo que a aula
13 deixou aberto, os arquivos que os clientes enviam.
