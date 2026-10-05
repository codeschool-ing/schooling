---
title: Modelos da comunidade
version: 1
---

A maioria dos repositórios do Hub não foi feita pelos autores de um modelo. Foi feita a partir de um:
ajustada com os dados de alguém, quantizada para caber num notebook, mesclada a partir de outros dois. A
documentação do Hub dá nome às relações e ao campo que as registra:

```
ana@desk:~/desk$ sources quote hub-model-cards "is a fine-tune, an adapter, or a quantized|infer the type of relationship"
# huggingface/hub-docs@08175d0f docs/hub/model-cards.md
 105: If your model is a fine-tune, an adapter, or a quantized version of a base model, you
      can specify the base model in the model card metadata section. This information can also
      be used to indicate if your model is a merge of multiple existing models. Hence, the
      `base_model` field can either be a single model ID, or a list of one or more base_models
      (specified by their Hub identifiers).
 156: The Hub will infer the type of relationship from the current model to the base model
      (`"adapter", "merge", "quantized", "finetune"`) but you can also set it explicitly if
      needed: `base_model_relation: quantized` for instance.
```

Quatro relações, cada uma mudando algo de que as aulas 2 a 5 cuidam:

- **finetune**: pesos diferentes, treinados um pouco mais; o comportamento, e a avaliação, são novos.
- **adapter**: um pequeno conjunto de pesos extras (LoRA é o tipo comum) carregado por cima da base;
  inútil sem a base exata com que foi treinado.
- **quantized**: o mesmo modelo com precisão menor, a troca da aula 3 seção 04, feita por quem subiu.
- **merge**: pesos combinados de dois ou mais modelos. A licença dele é a de cada um dos pais.

## Antes de confiar num deles

Um repositório da comunidade pode ser excelente; muitas das quantizações mais usadas são uploads da
comunidade. Também pode estar abandonado, mal rotulado ou coisa pior. Cinco verificações, nesta ordem,
antes de a ana deixar um chegar perto dos e-mails da Lantern Books:

1. **De quem é.** Uma organização com histórico, ou uma conta criada semana passada.
2. **O que diz ser.** `base_model` e `base_model_relation`, e se batem com o nome.
3. **Que licença ele pode de fato ter.** A licença da base vale mais que o YAML (aula 2 seção 04).
4. **Em que formato estão os pesos.** `safetensors`, como disse a seção 03, não um pickle.
5. **Se passa nos casos.** Aula 5, fixado no hash de commit da revisão que ela testou.

A quinta é a que decide. As quatro primeiras decidem se vale rodar a quinta.
