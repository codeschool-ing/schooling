---
title: Agent Builder, the hosted half
version: 2
---

Google's offer for agents has the same two halves as OpenAI's in lesson 8. **Vertex AI Agent Builder** is the name Google Cloud gives its hosted products for building, deploying and running agents, and **Agent Engine** is the managed runtime inside it that runs an agent as a service. The **Agent Development Kit** (ADK) is an open-source library, `google-adk` on PyPI; this lab pins 2.11.0, and it is the half the rest of the lesson runs.

**The hosted half could not be run for this course.** It needs a Google Cloud project, a region and a bill, and this course runs on your own machine. What can be seen from here is the bridge between the two, because the library's own command-line tool knows how to deploy:

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

An agent written with the ADK is deployed to Agent Engine, to Cloud Run (Google's service for running containers), to a Kubernetes cluster on GKE, or into a Docker container on this machine. None of these commands was run: each needs credentials for a project that does not exist here. The products on the platform side, their names and what is generally available move on Google's schedule, as lesson 8 said of OpenAI's, and this course cannot tell you what has moved since it was written. **Read Google Cloud's current documentation before relying on a detail of the hosted half.**

What is worth taking from the list is the shape. The code you write and test locally is the same code that is deployed. The decision about where it runs comes after, and it carries the same questions as any service: who can call it, where its sessions and logs are kept, and what data leaves for which provider.
