---
title: O Agent Builder, a metade hospedada
version: 2
---

A oferta do Google para agentes tem as mesmas duas metades que a da OpenAI na aula 8. **Vertex AI Agent Builder** é o nome que o Google Cloud dá aos produtos hospedados para construir, implantar e rodar agentes, e o **Agent Engine** é o runtime gerenciado, dentro dele, que roda um agente como serviço. O **Agent Development Kit** (ADK) é uma biblioteca de código aberto, `google-adk` no PyPI; este laboratório fixa a 2.11.0, e é a metade que o resto da aula roda.

**A metade hospedada não pôde rodar neste curso.** Ela precisa de um projeto no Google Cloud, de uma região e de uma fatura, e este curso roda na sua própria máquina. O que dá para ver daqui é a ponte entre as duas, porque a própria ferramenta de linha de comando da biblioteca sabe implantar:

```
ana@lab:~/agents$ adk deploy --help
Usage: adk deploy [OPTIONS] COMMAND [ARGS]...

  Deploys agent to hosted environments.

Options:
  --help  Show this message and exit.

Commands:
  agent_engine  Deploys an agent to Agent Engine.
  cloud_run     Deploys an agent to Cloud Run.
  docker        Deploys an agent to a local Docker container.
  gke           Deploys an agent to GKE.
```

Um agente escrito com o ADK é implantado no Agent Engine, no Cloud Run (o serviço do Google para rodar contêineres), num cluster Kubernetes no GKE, ou num contêiner Docker nesta máquina. Nenhum desses comandos foi rodado: cada um precisa de credenciais de um projeto que não existe aqui. Os produtos do lado da plataforma, os nomes deles e o que está disponível para todos mudam no ritmo do Google, como a aula 8 disse dos da OpenAI, e este curso não tem como dizer o que mudou depois de escrito. **Leia a documentação atual do Google Cloud antes de confiar num detalhe da metade hospedada.**

O que vale tirar da lista é a forma. O código que você escreve e testa localmente é o mesmo que é implantado. A decisão sobre onde ele roda vem depois, e traz as mesmas perguntas de qualquer serviço: quem pode chamá-lo, onde ficam as sessões e os logs dele, e que dados saem para qual fornecedor.
