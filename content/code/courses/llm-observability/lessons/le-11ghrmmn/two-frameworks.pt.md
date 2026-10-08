---
title: Dois frameworks, e do que são feitos
version: 2
---

**DeepEval** e **RAGAS** são as duas bibliotecas de avaliação de código aberto mais encontradas em
projetos Python que chamam um modelo. As duas fazem o que as aulas 8 a 11 fizeram à mão, dentro de uma
estrutura comum, e ler essa estrutura é a maior parte de aprender qualquer uma.

| | DeepEval 4.2.8 | RAGAS 0.3.1 |
| --- | --- | --- |
| um item a avaliar | `LLMTestCase`: input, actual output, expected output, retrieval context | `SingleTurnSample`: user input, response, retrieved contexts, reference, reference contexts |
| uma métrica | uma classe com `measure()`, um `threshold`, e `score`, `reason` e `success` depois de medir | uma classe com um `single_turn_ascore()` assíncrono que devolve um número |
| rodar muitos | `evaluate(test_cases, metrics)`, ou um arquivo pytest rodado por `deepeval test run` | `evaluate(dataset, metrics)`, que devolve uma tabela |
| as métricas próprias | em geral um prompt a um modelo mais aritmética | o mesmo, mais uma família que não precisa de modelo |

Os nomes dos campos mudam e as ideias não: uma pergunta, uma resposta, os trechos que o modelo viu e,
quando existe, a resposta esperada. As quarenta e oito respostas da aula 10 levam as quatro coisas, e é por
isso que os dois frameworks conseguem avaliá-las sem coletar nada de novo.

## Instalando, e três coisas a saber antes

Os dois entram no ambiente do curso, com dois ajustes antes:

```sh
cat >> ~/llmobs/bin/activate <<'EOF'
export DEEPEVAL_TELEMETRY_OPT_OUT=YES
export RAGAS_DO_NOT_TRACK=true
EOF
source ~/llmobs/bin/activate
pip install deepeval==4.2.8 ragas==0.3.1 langchain-community==0.3.31 langchain-openai==1.6.7 pillow==12.3.0 rapidfuzz==3.14.6
```

**Os dois mandam telemetria por padrão.** O DeepEval e o RAGAS relatam uso anônimo a quem os faz, a
menos que se diga que não, e as duas linhas acrescentadas ao `activate` dizem que não. O raciocínio da
aula 2 é o motivo: uma biblioteca de avaliação roda sobre as palavras dos clientes, e o que ela manda
para fora da máquina é uma questão a resolver antes da primeira execução, não depois.

**O DeepEval guarda cada caso de teste em disco.** Ele escreve uma pasta `.deepeval` ao lado do script,
e a última execução ali guarda cada entrada, saída e contexto recuperado inteiros. É texto de clientes
num arquivo que ninguém pensa como dado: ele vai para o `.gitignore` e fica sob a mesma retenção dos
traces.

**O RAGAS 0.3.1 não importa como os próprios requisitos o instalam.** Ele importa um modelo de chat que
o `langchain-community` removeu na 0.4, e usa dois pacotes, `pillow` e `rapidfuzz`, sem declará-los. O
RAGAS mais novo, 0.4.3, puxaria o cliente da OpenAI de volta de 3.24 para 1.x, por baixo de todos os
outros programas deste curso. Então a linha acima fixa o `langchain-community` em 0.3.31 e acrescenta os
outros dois, e o `langchain-openai` é como o RAGAS chega a um modelo. Um framework de avaliação é uma
dependência como outra qualquer, e muitas vezes é a que tem mais dependências próprias.
