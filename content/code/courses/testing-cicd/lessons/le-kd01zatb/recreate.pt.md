---
title: Parar o antigo, subir o novo
version: 2
---

Todo deploy da aula 7 fez a mesma coisa: parar o processo que estava rodando, subir o release novo,
conferir se ele responde. Essa estratégia tem nome, **recreate**, e tem uma propriedade que todas as
outras estratégias desta aula existem para eliminar. Entre a parada e o início, nada responde.

Aqui a produção roda o 1.5.0 na porta 8300, implantado como a aula 7 implantava:

```sh
ops/deploy.sh production dist/shipquote-1.5.0.tar.gz
```

Um laço pergunta ao `/health` a cada 50 milissegundos e
imprime o código de status; meio segundo depois, o `restart.sh` para o processo e sobe de novo.

```
ana@laptop:~/shipquote$ for i in $(seq 60); do curl -s -o /dev/null -w "%{http_code} " --max-time 1 http://127.0.0.1:8300/health; sleep 0.05; done & sleep 0.5; ops/restart.sh production; wait; echo
200 200 200 200 200 200 200 200 200 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
```

`000` é o jeito do curl de dizer que nenhuma resposta voltou: a conexão foi recusada. Vinte e quatro
verificações seguidas receberam isso, o que, a uma verificação a cada 50 ms ou mais, dá bem mais de
um segundo sem serviço. Um cliente que pediu uma cotação nesse segundo viu uma página de erro.

## De onde vem a lacuna

A lacuna é a soma de tudo o que acontece entre o processo antigo soltar a porta e o novo pegá-la:

- o processo antigo encerrando, e aqui também o sistema recolhendo ele;
- o interpretador iniciando e importando o programa;
- o que o programa faz antes de escutar: ler a configuração, abrir uma conexão com o banco,
  aquecer um cache.

O `shipquote` não faz quase nada ao iniciar e ainda assim perdeu mais de um segundo. Um serviço que
carrega um modelo grande ou roda uma migração antes de escutar pode perder minutos.

## Quando o recreate é a resposta certa

Ele não está sempre errado. O recreate é a única estratégia em que **duas versões nunca rodam ao
mesmo tempo**, e algumas mudanças precisam exatamente disso: uma mudança no jeito de guardar os dados
que a versão antiga não consegue ler, ou uma tarefa que não pode rodar duas vezes. Ele também é a
mais simples, e para uma ferramenta interna usada em horário comercial um deploy às 7 da manhã não
custa nada a ninguém.

O que ele não deveria ser é a estratégia que ninguém escolheu. O resto desta aula são as
alternativas, cada uma comprando alguma coisa com outra. Pare esta produção agora,
`kill $(cat ~/envs/production/pid)`: da seção 06 em diante, a porta 8300 é do roteador.
