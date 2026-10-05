---
title: Lendo um model card
version: 1
---

Um provedor hospedado diz quais são os limites numa página de preços. Um modelo aberto diz no
**model card**, a página de texto publicada com os pesos no Hugging Face. É a única descrição
daquilo para que o modelo foi treinado, e a maioria dos erros cometidos com modelos abertos são
coisas que o card dizia.

Estas são as linhas que vale ler, com o que o card do all-MiniLM-L6-v2 diz para cada uma:

| o que procurar | por que importa | all-MiniLM-L6-v2 |
|---|---|---|
| dimensão | armazenamento, e com o que ele pode ser comparado | 384 |
| tamanho máximo de sequência | onde cai o corte silencioso | 256 pedaços de palavra |
| línguas | o título em português da aula 1, avaliado como sem relação | inglês |
| dados de treino | o que *perto* significa para ele | mais de um bilhão de pares de frases |
| pooling e normalização | o que você precisa fazer se rodá-lo por conta própria | mean pooling, depois normalizar |
| prefixos ou instruções | se consultas e documentos são marcados | nenhum |
| licença | se você pode usá-lo comercialmente | Apache 2.0 |

## Os arquivos discordam entre si, e o card decide

Os pesos chegam com arquivos de configuração, e dá vontade de ler os limites neles. Eis o que três
dos arquivos que o `lab.sh` baixou dizem:

```
ana@lab:~/emb$ jq "{vocab_size, hidden_size, num_hidden_layers, max_position_embeddings}" $MINILM_DIR/config.json
{
  "vocab_size": 30522,
  "hidden_size": 384,
  "num_hidden_layers": 6,
  "max_position_embeddings": 512
}
ana@lab:~/emb$ jq .model_max_length $MINILM_DIR/tokenizer_config.json
512
ana@lab:~/emb$ jq -c "{truncation: .truncation.max_length, padding: .padding.strategy}" $MINILM_DIR/tokenizer.json
{"truncation":128,"padding":{"Fixed":128}}
```

**Há três comprimentos diferentes neles, e nenhum é 256.** 512 é o espaço que a arquitetura tem, o
número de posições para as quais ela guarda um vetor aprendido. 512 de novo é o que a configuração
do tokenizador permite. 128 é o tamanho em que o `tokenizer.json` corta e preenche se ninguém mudar.
O `minilm.py` e o Chroma mudam para 256, e o código do Chroma comenta isso: *for some reason
sentence-transformers uses 256 even though the HF config has a max length of 128* ("por algum motivo
o sentence-transformers usa 256, embora a configuração do HF tenha comprimento máximo de 128"). O
256 é o número do model card e o que o sentence-transformers aplica, então é o que este curso usa.

Isso vale para qualquer modelo aberto. **Um número num arquivo de configuração descreve o arquivo; o
card descreve como o modelo deveria ser usado.** Onde os dois discordam, uma biblioteca que lê só o
arquivo pode rodar o modelo com um limite diferente daquele com que ele foi publicado. Todo texto
mais longo que o menor limite passa a ganhar um vetor diferente, e nada avisa.

## Prefixos: task types para modelos abertos

O all-MiniLM-L6-v2 é simétrico, então não leva prefixo. Muitos modelos abertos mais novos são
treinados de forma assimétrica, como os modelos dos provedores na aula 8, e, como não há um
parâmetro de API para levar o papel, **o papel vai dentro do próprio texto.** A família E5 espera
que toda consulta comece com `query: ` e todo documento com `passage: `; os modelos de embedding da
Nomic usam `search_query: ` e `search_document: `; os modelos BGE põem uma instrução só na frente da
consulta. O card diz qual, e um modelo que recebe textos sem o prefixo dele ainda devolve vetores,
só que não os que ele foi treinado para produzir.

Nenhum desses modelos rodou aqui, porque todos são baixados do Hugging Face. Eles estão descritos
para que você reconheça a exigência quando um card a fizer.

## Escolhendo um modelo para testar

O **leaderboard do MTEB**, o Massive Text Embedding Benchmark, é onde a maioria das pessoas começa.
Ele roda centenas de modelos abertos e hospedados nas mesmas tarefas — busca, classificação,
agrupamento e outras — em muitas línguas, e os ordena. É o primeiro filtro certo: tira os modelos
que são ruins em tudo. Não é o último, porque as tarefas dele são dados de outras pessoas, e a
próxima seção mede o que acontece quando dois modelos encontram os seus.
