---
title: As ferramentas, e o que elas acrescentam a um arquivo JSON
version: 1
---

O `track.py` tem umas quarenta linhas e faz a parte essencial: toda execução deixa um registro que
diz o que a produziu. **As ferramentas de rastreamento que se usam no trabalho fazem a mesma coisa no
núcleo**, e vendem o que cresce em volta disso. Nenhuma delas foi instalada nem executada para este
curso; o que segue é o que cada uma é, e o formato do código dela.

## Quando um arquivo deixa de bastar

O `runs.jsonl` basta para uma pessoa, uma máquina e algumas dezenas de execuções. Começa a doer
quando:

- **há curvas, não só números finais.** Uma execução que registra a perda de cada época é uma série,
  e comparar vinte séries pede um gráfico, não um `tail`.
- **várias pessoas ou máquinas rodam experimentos.** Um arquivo numa VM não é onde um colega olha, e
  duas máquinas acrescentando linhas a cópias dele terminam com duas histórias.
- **uma execução produz arquivos.** Pesos salvos, uma matriz de confusão, uma amostra de previsões: o
  registro deveria apontar para eles, e eles precisam ser guardados em algum lugar.
- **as execuções chegam às centenas**, vindas de uma busca de configurações, e a pergunta passa a ser
  filtrá-las e ordená-las.

## MLflow

Código aberto, rodando na sua máquina ou num servidor da sua equipe. Uma execução é aberta, recebe os
parâmetros e é alimentada com métricas; os registros vão para um diretório local ou um servidor de
rastreamento, e uma página web os lista e desenha. As chamadas correspondem quase uma a uma ao
`track.record`:

```python
import mlflow

with mlflow.start_run():
    mlflow.log_params({**config, "seed": seed})
    for epoch, train_loss, val_loss, val_acc in history:
        mlflow.log_metric("val_acc", val_acc, step=epoch)
```

Dentro de um repositório git, o MLflow anota o commit do código que iniciou a execução, a mesma ideia
do `code_version`, feita para você.

## Weights & Biases

Um serviço hospedado, com um plano gratuito para uso individual e planos pagos para equipes. O mesmo
formato: `wandb.init` abre uma execução com a configuração, `log` envia métricas, e o serviço guarda
as execuções, desenha as curvas e registra a máquina e as bibliotecas. As execuções ficam nos
servidores da empresa, o que é a conveniência e também o ponto a conferir antes de enviar qualquer
coisa confidencial.

```python
import wandb

run = wandb.init(project="digits", config={**config, "seed": seed})
for epoch, train_loss, val_loss, val_acc in history:
    run.log({"val_acc": val_acc}, step=epoch)
run.finish()
```

## TensorBoard

Mais antigo, e mais estreito: desenha curvas a partir de arquivos de eventos que um programa escreve,
e nasceu para acompanhar ao vivo um único treino. O PyTorch traz o escritor,
`torch.utils.tensorboard.SummaryWriter`, mas não o pacote para o qual ele escreve, que este curso
nunca instalou:

```
PENDING tensorboard
```

Ele registra métricas e deixa a configuração, a semente e a versão do código por sua conta, o que faz
dele mais um visualizador que um rastreador.

## Qual, então

Para este curso, o arquivo. **Cada uma dessas ferramentas registra o que o `track.py` registra, e
nenhuma decide nada por você**: as cinco sementes por configuração, o commit antes da execução, a
escolha na validação e a única olhada no teste são hábitos, e um painel os exibe bem ou mal. Escolha
uma ferramenta quando uma das quatro dores acima de fato chegar, e mantenha os hábitos quando ela
chegar.
