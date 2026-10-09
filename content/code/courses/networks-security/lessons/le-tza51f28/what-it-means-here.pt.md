---
title: Privilégio mínimo, medido em conexões
version: 1
---

O **privilégio mínimo** (*least privilege*) diz que cada pessoa, programa e máquina recebe o acesso
de que seu trabalho precisa e nada além disso. Numa rede, acesso é algo concreto: **qual máquina pode
abrir uma conexão com qual, em qual porta, e quando**. Isso torna o princípio excepcionalmente
testável aqui, porque cada privilégio é uma célula da matriz e uma célula pode ser experimentada.

A linha de base da aula 4 já o aplica entre zonas: a equipe alcança a aplicação e não o banco de
dados, o proxy alcança a aplicação e nada mais. O que a matriz de zonas não consegue expressar é algo
mais fino que uma zona. No seu laboratório esta aula começa com `sudo bash nslab.sh reset`, com a
política da empresa carregada no `fw` por `nft -f baseline.nft`. Quem alcança o banco de dados hoje:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  open
ana@laptop:~$ probe db:5432 db:22
db:5432                blocked
db:22                  blocked
ana@admin:~$ probe db:5432 db:22
db:5432                blocked
db:22                  open
```

Da LAN da equipe, nada, como a matriz diz. Da máquina de gestão, SSH, como a matriz diz. E de `app`,
**tanto a porta do banco de dados quanto SSH**, porque `app` divide o segmento de servidores com `db`
e o firewall nunca vê esse tráfego (aula 4). `app` precisa do banco de dados; não tem motivo para
fazer login na máquina do banco de dados. Se `app` for comprometido por uma falha na aplicação, essa
porta a mais é o próximo passo do atacante.

O privilégio mínimo numa rede assume quatro formas, e esta aula constrói cada uma no laboratório:

| forma | a pergunta que ela responde | aqui |
|---|---|---|
| **um serviço, uma origem** | quem pode abrir esta porta | `db` aceita 5432 só de `app` |
| **uma só entrada para a administração** | de onde os administradores se conectam | SSH só a partir do jump host, com uma chave presa a ele |
| **nada de saída por padrão** | o que esta máquina pode iniciar | `db` não inicia conexão nenhuma |
| **acesso que expira** | por quanto tempo | o acesso de um fornecedor removido pelo relógio, não pela memória |

O custo é o de sempre: cada privilégio negado é um de que alguém pode precisar algum dia, e a
resposta para isso é um pedido de mudança e uma célula nova, nunca uma regra mais larga escrita de
antemão só por precaução.
