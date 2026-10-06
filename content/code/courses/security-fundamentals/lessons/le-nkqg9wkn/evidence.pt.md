---
title: Evidência
version: 1
---

Um auditor não acredita na palavra de ninguém. Isso não é grosseria; é o trabalho. Uma auditoria existe
para que um terceiro possa confiar na conclusão dela, e uma conclusão baseada no que as pessoas disseram
só vale o quanto valem a memória e a honestidade delas. Então a pergunta do auditor é sempre a mesma:
**me mostre.**

**Evidência** é qualquer coisa que mostre que um controle existe e funciona. Ela vem em alguns tipos, do
mais fraco ao mais forte:

| tipo | exemplo | por que é mais fraca ou mais forte |
|---|---|---|
| **indagação** | perguntar à ana como as revisões de acesso são feitas | a menos confiável: uma descrição, não uma prova |
| **documentos** | a política de controle de acesso | mostram a intenção, não a prática |
| **registros** | a revisão de acesso assinada de setembro passado | mostram que aconteceu, ao menos uma vez |
| **observação** | assistir ao teste mensal de restauração | mostra que acontece, ao menos enquanto alguém olha |
| **reexecução** | o próprio auditor restaura um backup | a mais forte: o auditor vê o resultado diretamente |

Boa evidência é **datada, atribuível e guardada**: diz quando, quem fez, e ainda existe quando alguém
pergunta um ano depois. Um e-mail dizendo "feito" é evidência fraca; uma linha de log com a data, a
pessoa e o resultado é forte.

### Amostragem

Um auditor não consegue conferir todo login, toda mudança, toda conta. Ele tira uma **amostra**: vinte e
cinco contas da lista de todas, dez mudanças de firewall das do ano, e confere essas a fundo. Se a
amostra estiver limpa, ele conclui que o controle funciona; se três das vinte e cinco contas eram de
pessoas que saíram há meses, o controle falhou, por melhor que a política pareça. É por isso que o
controle precisa funcionar **toda vez**, e não só nos casos que alguém espera que sejam olhados.

### Este curso vem produzindo evidência o tempo todo

Olhe para trás, para o que as aulas anteriores deixaram:

| aula | o registro | o que prova |
|---|---|---|
| 3 | o registro de riscos, com donos, assinaturas e datas de revisão | os riscos são identificados e aceitos pelas pessoas certas |
| 5 | o arquivo de regras do firewall, e o teste de cada zona | a rede está segmentada como a política diz |
| 6 | a regra de `sudo` que nomeia dois comandos; a revisão de acesso | o acesso segue o menor privilégio, e é revisto |
| 8 | o log do portal com um nome em cada pedido | as ações são atribuíveis |
| 10 | os achados do exercício roxo, arquivados no registro | a detecção é testada, e as falhas são acompanhadas |
| 12 | o registro dos testes de restauração com datas e tempos | os backups restauram, dentro do RTO |

Nada disso foi produzido para um auditor. Cada item foi produzido porque deixou a loja mais segura ou
permitiu a alguém decidir algo. Essa é a atitude que a seção 02 descreveu: evidência como efeito
colateral de fazer o trabalho direito. A primeira auditoria da loja vai consistir quase só em abrir
esses arquivos.
