---
title: Um modelo, cinco endereços
version: 1
---

O Claude é acessado pela API da própria Anthropic e pelas grandes nuvens, e a aula 2 seção 05 mostrou
que os preços quase não mudam entre elas. O que muda é **o nome pelo qual você o chama**:

```
ana@desk:~/desk$ python card.py "Claude Haiku 4.5" "Claude API ID" "Claude API alias" "Amazon Bedrock ID" "Google Cloud ID" "Microsoft Foundry ID"
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-07
Claude Haiku 4.5
  Claude API ID               claude-haiku-4-5-20251001
  Claude API alias            claude-haiku-4-5
  Amazon Bedrock ID           anthropic.claude-haiku-4-5
  Google Cloud ID             claude-haiku-4-5@20251001
  Microsoft Foundry ID        claude-haiku-4-5
```

Os mesmos pesos com cinco grafias. Na API da Anthropic o identificador datado termina em `-20251001`
e o apelido o dispensa. O Bedrock põe o fornecedor na frente, `anthropic.`. O Google Cloud põe a data
depois de um `@`. O Microsoft Foundry usa a forma de apelido. A aula 2 mostrou os prefixos regionais
do Bedrock por cima disso: `us.`, `eu.`, `global.`.

## Por que escolher uma nuvem em vez da API do autor

Não pelo preço, como a aula 2 mostrou. Os motivos são sobre a conta onde o modelo fica:

- **uma fatura e um contrato**: uma empresa que já compra servidores de uma nuvem acrescenta o
  modelo à mesma fatura, em termos que os advogados dela já leram;
- **a região e a rede**: as requisições ficam dentro das regiões da nuvem (aula 2 seção 07), e podem
  ser feitas da rede privada da empresa;
- **as regras de identidade e acesso da própria nuvem**: quem pode chamar o modelo é administrado
  como quem pode ler um banco de dados.

E os motivos para ficar na API do autor: modelos e recursos novos costumam chegar lá primeiro, e a
documentação dela descreve a própria API, não uma tradução.

## O que muda no código

O formato da requisição muda com a plataforma, que é um dos motivos de a aula 17 ensinar a Messages
API da Anthropic diretamente e a aula 20 o formato compatível com a OpenAI que muitas plataformas
também oferecem. **Guarde o nome do modelo na configuração, nunca no código**: o mesmo programa então
passa entre Anthropic, Bedrock e Vertex trocando uma configuração, e a avaliação da aula 5 roda de novo
no endereço novo como se ele fosse um candidato novo, que em cobrança, região e limites de requisição
ele é.
