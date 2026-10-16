---
title: "BugBug e Ghost Inspector: a gravação como serviço"
version: 1
---

O Selenium IDE deixa você com um arquivo. **O BugBug e o Ghost Inspector deixam você com uma
conta.** Cada um grava por uma extensão de navegador, guarda os testes nos próprios servidores,
reproduz nos próprios navegadores, num agendamento, e avisa quando um falha. O que você compra é a
maquinaria em volta da gravação, mais do que a gravação em si.

**Nenhum dos dois foi usado neste curso, e os sites deles nem abriram na máquina em que estas aulas
foram escritas.** O que esta seção diz sobre cada um é o que as páginas de documentação dele dizem,
do jeito que o índice de um buscador as devolveu em outubro de 2026. Cada recurso abaixo é
afirmação do fornecedor, não algo testado aqui. Os dois vendem planos, os planos têm preço, e os
preços e o que cada plano inclui mudam; leia no site do fornecedor no dia em que for decidir, e
nunca num curso.

## BugBug

O guia de início rápido dele começa pela extensão: instalar a extensão do BugBug para Chrome pela
Chrome Web Store e permiti-la no modo anônimo, para que as gravações rodem num perfil de navegador
limpo. É o argumento da aula 4 chegando por uma tela de configuração: um navegador cheio dos seus
próprios cookies e do seu cache é outro navegador, diferente do que os seus usuários têm.

A documentação dele sobre agendamentos diz que o serviço consegue rodar testes "in the cloud" (na
nuvem) automaticamente e mandar um e-mail sobre os que falharam. Dois detalhes dessas páginas
importam mais do que a manchete:

- **Só uma suíte pode ser agendada, nunca um teste sozinho.** O agendamento é a unidade de
  monitoramento, e a suíte é o que ele vigia.
- **Uma suíte pode repetir um teste que falhou**, e um teste que passa numa tentativa seguinte marca
  a suíte como aprovada, com a tentativa que falhou guardada no histórico como "auto-retried"
  (repetido automaticamente). É exatamente a repetição contra a qual a aula 14 alerta: verde no
  painel, um teste intermitente por baixo, e a evidência a um clique de distância para quem for
  procurar.

A página de boas práticas acrescenta o lado da rede: uma aplicação atrás de um firewall pode
precisar liberar os executores do serviço pelo endereço, ou os testes falham numa porta, não na
loja.

## Ghost Inspector

A documentação dele descreve o mesmo ciclo. A extensão grava um passeio pela sua aplicação; o
teste salvo roda uma vez no navegador do próprio Ghost Inspector; depois, os passos e as
configurações podem ser editados no serviço.

**Duas configurações do gravador dele miram direto na aula 2 deste curso.** O gravador pode ser
instruído a ignorar atributos ou nomes de classe específicos, e uma aplicação com ids dinâmicos pode
desligar a identificação por id, para que uma gravação recorra a outros jeitos de nomear um
elemento. É um fornecedor admitindo, na própria página de configurações, que um gravador deixado
por conta própria escolhe nomes como `#card-4821`. A configuração conserta a próxima gravação; as
que já foram salvas ficam com os nomes que receberam.

O resto do que as páginas dele descrevem é monitoramento:

- **um agendamento por teste ou por suíte**, com o teste herdando o agendamento da suíte, a menos
  que receba um próprio;
- **uma comparação de capturas de tela** no fim de uma execução, contra a última captura aprovada,
  com uma tolerância dada como fração dos pixels que podem mudar. A aula 16 faz a mesma coisa com o
  `toHaveScreenshot` do Playwright, e o mesmo compromisso vale: apertado demais e toda atualização
  de fonte falha, frouxo demais e um botão sumido passa;
- **uma importação do formato HTML do Selenium**, o formato do IDE antes dos arquivos `.side`,
  anunciada no blog dele.

## O que o modelo dá, e o que ele tira

**Ele dá uma infraestrutura que você não precisa rodar.** Não há navegador para instalar, job de
CI para escrever nem máquina para manter acordada às três da manhã. Uma execução agendada contra o
site no ar, a cada poucos minutos, é mais monitoramento do que teste: uma verificação de fumaça, no
sentido da aula 8 de `manual-testing`, repetida por uma máquina.

**Ele tira os testes do seu repositório.** Eles moram na conta do fornecedor, editados no editor do
fornecedor, então a mudança num teste não viaja no mesmo pull request que a mudança na aplicação
que a tornou necessária, e ninguém revisa as duas lado a lado. Faça três perguntas antes da primeira
gravação, e não depois da centésima:

1. **Os testes conseguem sair?** Em que formato, e esse formato ainda roda em outro lugar.
2. **O que o navegador do fornecedor guarda?** Um teste que faz login deixa uma senha no serviço de
   outra empresa. Dê a ele uma conta de teste que só faça o que o teste precisa, e nada que
   pertença a um cliente de verdade.
3. **Que ambiente ele atinge?** Uma gravação que põe itens numa cesta em produção põe itens numa
   cesta de verdade. A aula 15 trata dos dados que um teste deixa para trás; um agendamento repete
   isso a cada poucos minutos.

Nada disso é motivo para não usar um serviço. São os motivos pelos quais as próximas seções rodam as
gravações e contam quanto custa mudá-las.
