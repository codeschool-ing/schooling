---
title: Estágios 4 e 5, ameaças e fraquezas
version: 1
---

Os estágios do meio adotam a visão do atacante. O estágio 4 pergunta **quem ia querer prejudicar
este sistema, e como sistemas parecidos já foram prejudicados**. O estágio 5 pergunta **onde este
sistema em particular é fraco**, e junta as duas coisas.

### Estágio 4: análise de ameaças

O STRIDE produziu catorze ameaças a partir do desenho. O estágio 4 acrescenta o que o desenho não
tem como saber: o mundo lá fora. As entradas são **inteligência de ameaças** (relatos do que está
acontecendo com organizações parecidas), os próprios logs e incidentes do sistema, e a lista de
atores que poderiam agir.

Para uma rede de clínicas de fisioterapia no Brasil, o resumo da carla para o estágio 4 tinha três
linhas:

- **Serviços de saúde são alvo comum de extorsão.** Grupos criminosos cifram ou roubam dados de
  pacientes e pedem pagamento; quanto mais sensível o dado, mais forte a posição deles. Todo
  relatório setorial que ela leu nos últimos dois anos punha a saúde perto do topo.
- **Credential stuffing atinge todo login de consumidor.** Senhas vazadas de outros sites são
  testadas automaticamente contra qualquer página de login que responda. O próprio log de login do
  portal mostra rajadas de logins falhos de endereços desconhecidos quase toda semana.
- **Ameaças internas existem, e em geral são descuido, e não má-fé.** Uma recepcionista olhando o
  prontuário de um vizinho é o caso clássico em dado de saúde, e não precisa de nada técnico.

Nenhuma dessas é ameaça nova na lista. O que o estágio 4 acrescenta é **quais das catorze têm
alguém tentando agora**: a T02 (credential stuffing) e a cadeia T03, T12, T09 (uma conta da equipe
roubada por phishing chegando aos prontuários) sobem; a T14 (um PDF preparado) é possível, mas
ninguém nos relatórios da carla estava fazendo isso com clínicas.

### Estágio 5: análise de fraquezas e vulnerabilidades

O estágio 5 liga cada ameaça a uma **fraqueza**: uma deficiência específica deste sistema que
deixaria a ameaça acontecer. Fraquezas recebem nome pelo **CWE**, a Common Weakness Enumeration da
MITRE, para que um achado do modelo, um achado de um scanner de código e uma linha num relatório
de pentest possam ser ligados pelo mesmo identificador. Vulnerabilidades conhecidas no software
que a Vereda roda, com nome pelo CVE, entram na mesma tabela quando existem.

| ameaça | fraqueza na Vereda | CWE |
|---|---|---|
| T01 | o handler do webhook não verifica a assinatura do gateway | CWE-345, verificação insuficiente da autenticidade dos dados |
| T03 | a equipe entra só com senha | CWE-308, autenticação de fator único |
| T05 | edições de anotações clínicas não são registradas | CWE-778, registro insuficiente |
| T07 | o download busca o exame pelo número no endereço, sem conferir o dono | CWE-639, contorno de autorização por chave controlada pelo usuário |
| T10 | uploads não têm limite de tamanho | CWE-770, alocação de recursos sem limites ou controle de taxa |
| T13 | o worker se conecta com a conta do dono | CWE-250, execução com privilégios desnecessários |

**A ligação é o ponto.** Quando um scanner rodado no curso `secure-pipeline` relatar CWE-639 na
rota de download, esta tabela diz qual ameaça ele confirma e qual objetivo de negócio ele põe em
risco. Sem o estágio 5, o achado do scanner e a ameaça do modelo são dois documentos que ninguém
liga.

Uma ameaça sem fraqueza achada não está fechada por isso. Significa que ninguém achou uma ainda, e
o estágio 5 a registra como "nenhuma fraqueza conhecida", com a data em que foi conferida.
