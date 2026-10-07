---
title: Quando fazer, e quanto
version: 1
---

O erro comum é tratar a modelagem de ameaças como uma fase: feita uma vez, no começo, assinada,
arquivada. Um sistema muda toda semana, e um modelo do sistema do ano passado descreve um prédio
que desde então ganhou dois andares. **A resposta para "quando" é: sempre que o projeto muda de um
jeito que importa para a segurança, e o mais cedo possível nessa mudança, assim que ela puder ser
desenhada.**

### Os momentos que pedem um modelo

| momento | o que modelar |
|---|---|
| um sistema novo está sendo projetado | o todo, no nível das partes principais |
| uma funcionalidade traz um tipo novo de dado | onde o dado entra, onde fica guardado, quem pode ler |
| uma funcionalidade traz uma porta de entrada nova | um endpoint novo, um upload novo, uma integração nova com o sistema de outra empresa |
| a confiança muda | um papel novo, um parceiro novo com acesso, um serviço movido para outra rede ou outra empresa |
| uma dependência muda | uma biblioteca nova que interpreta entrada não confiável, um fornecedor novo que recebe dados pessoais |
| depois de um incidente | a parte do projeto que deixou acontecer, e as vizinhas |

A maioria das mudanças não dispara nenhum desses. Uma cor nova na página de agendamento não
dispara. Um campo no formulário de agendamento que pede o número do convênio do paciente dispara,
porque traz um dado pessoal novo para o sistema e o projeto precisa dizer para onde ele vai.

### Quanto basta

**Proporcional ao que está em jogo e ao que mudou.** Um sistema novo que vai guardar prontuários
merece uma tarde com as pessoas que vão construí-lo. Um campo novo merece dez minutos na próxima
reunião de refinamento: desenhar o fluxo por onde ele passa, perguntar o que pode dar errado,
anotar a resposta. A aula 15 transforma esse segundo formato numa rotina.

Dois sinais de que um modelo passou do ponto útil:

- **Ele lista ameaças sobre as quais ninguém vai agir.** Uma ameaça sem decisão é ruído, e uma
  lista de duzentas esconde as cinco que importam. A aula 3 conhece uma ferramenta que produz
  exatamente essa lista.
- **Ele é mais detalhado que o projeto.** Um modelo é o desenho de um projeto. Se o projeto diz "o
  portal chama o gateway de pagamento", modelar cada cabeçalho HTTP dessa chamada é chutar uma
  implementação que ainda não existe.

### Antes do código, e também depois

Modelar antes de o código existir é o mais barato, pelo motivo que a seção anterior desenhou. Não
é o único momento em que compensa. Um sistema que nunca foi modelado pode ser modelado agora:
desenhe como ele está, faça as mesmas perguntas, e as falhas que você achar são falhas vivas hoje.
O portal da Vereda está nessa situação. Ele existe, tem pacientes, e ninguém o desenhou pensando
em segurança. É o ponto de partida mais comum que existe, e é dele que este curso parte.
