---
title: O que conta como segredo
version: 1
---

Um **segredo** é qualquer valor que dá acesso a algo, de modo que quem o tem consegue agir como você.
Senhas e tokens de API são os óbvios. Os menos óbvios importam tanto quanto: uma string de conexão de
banco com senha dentro, uma chave privada de assinatura, uma URL de webhook com token na query, o
arquivo de credenciais de um provedor de nuvem, o cookie de sessão de um administrador.

O `shipquote` tem um. `SHIPQUOTE_CARRIER_TOKEN` é a chave que a loja apresenta à transportadora; com
ela, qualquer pessoa conseguiria pedir preços à transportadora na conta da loja, e numa
transportadora de verdade, criar remessas e gerar uma conta. No laboratório ele é `lab-live-token`, um
valor inventado para o curso que só abre a simulação em 127.0.0.1, e esta aula o trata como se fosse
real.

## Por que o pipeline é onde segredos vazam

A aula 8 terminou com credenciais por ambiente, e um pipeline é a coisa que segura todas elas: o token
da homologação, o token da produção, a chave que implanta, a chave que publica um release. Ele também
roda código de muita gente e de muitos lugares, imprime logs que muita gente lê, e guarda artefatos e
caches por dias. **Cada uma dessas coisas é um caminho por onde um segredo sai do lugar a que
pertence.**

O resto da aula percorre os caminhos um de cada vez, como quem defende: como cada vazamento acontece,
como achar um que já aconteceu, e o que o torna inofensivo quando acontece mesmo assim.

| caminho | seção |
|---|---|
| commitado no repositório | 03 |
| legível na máquina que roda o programa | 04 |
| entregue a um job sem cuidado | 05 |
| impresso num log | 06 |
| um token que faz mais do que o trabalho dele pede | 07 |
| código que ninguém revisou, rodando com os segredos ao alcance | 08 |
| uma credencial que dura para sempre | 09 |
| um vazamento, e o que fazer primeiro | 10 |

## Três propriedades de um segredo bem guardado

1. **Não está no código.** Nem no repositório, nem no artefato, nem numa imagem de contêiner. Ele
   chega ao programa na hora de rodar, pelo ambiente, como a aula 8 seção 03 descreveu.
2. **Só faz o trabalho dele.** Um token que lê preços não deveria conseguir criar remessas.
3. **Expira, ou pode ser trocado em minutos.** Um segredo que não se troca sem interrupção ou sem uma
   reunião é um segredo que ninguém vai trocar depois de um vazamento.
