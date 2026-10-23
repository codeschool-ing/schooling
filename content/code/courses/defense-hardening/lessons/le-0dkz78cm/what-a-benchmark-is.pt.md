---
title: Um guia que alguém já argumentou
version: 1
---

**Um guia de configuração segura é uma lista de configurações, cada uma com o argumento a favor
dela já feito.** A aula 1 endureceu o `web` no olho: uma varredura, uma lista de contas, uma leitura
do `sshd -T` e um julgamento sobre cada achado. Isso funciona para uma máquina que você entende. Não
funciona para a quadragésima, e não sobrevive à primeira pergunta que um auditor faz: "contra o
quê?"

A imagem errada mais comum é a de que um guia é uma lista de coisas a ligar. A maior parte de um bom
guia é o contrário, o mesmo trabalho que a aula 1 fez, escrito uma vez para que ninguém precise
redescobri-lo: remova este pacote, recuse aquele login, ajuste as permissões deste arquivo.

## Os CIS Benchmarks

O **Center for Internet Security** publica um Benchmark por produto e por versão: um para o Ubuntu
22.04, outro para o Ubuntu 24.04, um para o Windows Server 2022, um para o nginx. São escritos por
voluntários da indústria e do governo e aprovados por consenso, e os PDFs podem ser baixados de graça
depois de um cadastro; a ferramenta que pontua uma máquina contra eles por inteiro, o CIS-CAT Pro, é
para membros. Cada **recomendação** tem as mesmas partes:

| parte | o que traz |
|---|---|
| um número e um título | um número de seção e uma frase como `Ensure SSH root login is disabled`, para que um relatório possa citá-la |
| o perfil | **Nível 1** para configurações que qualquer servidor aceita sem perder uma função, **Nível 2** para defesa em profundidade que pode custar uma |
| a justificativa | por que a configuração importa, que é a parte que encerra uma discussão |
| a auditoria | o comando que mostra se a máquina está conforme |
| a correção | a mudança que a deixa conforme |
| o impacto | o que pode parar de funcionar quando você aplica |

Dois perfis é o guia admitindo que endurecer tem preço. O Nível 1 foi feito para ser seguro de
aplicar em qualquer lugar. O Nível 2 tira coisas de que uma máquina específica pode precisar: um
perfil de estação de trabalho Nível 2 que desliga armazenamento USB está certo para uma recepção e
errado para quem recebe documentos de clientes num pendrive, e a aula 5 é essa discussão por inteiro.

**Um Benchmark é escrito para uma versão.** Caminhos, nomes de pacotes e padrões mudam entre o Ubuntu
22.04 e o 24.04, então um comando de auditoria escrito para um pode estar errado no outro, e a seção
sobre SCAP mostra o que uma ferramenta faz com um guia escrito para outra versão.

## Os outros guias

O CIS não é a única fonte, e uma organização costuma responder a um em particular:

- os **STIGs da DISA**, escritos pelo Departamento de Defesa dos Estados Unidos para os próprios
  sistemas, mais prescritivos e mais rígidos que o Nível 1 do CIS;
- o **Ubuntu Security Guide** da Canonical (`usg`), que aplica e audita os perfis CIS e STIG no
  Ubuntu e vem com uma assinatura do Ubuntu Pro;
- as **linhas de base de segurança da Microsoft** para o Windows, entregues como objetos de Política
  de Grupo, que a aula 3 explica;
- o guia de endurecimento do próprio fabricante de um produto, que muitas vezes é o único que conhece
  as configurações do produto.

Nenhum deles foi executado para este curso, porque cada um exige uma conta, uma assinatura ou uma
licença que o curso não pede a você. O que esta aula roda é gratuito e está no repositório do próprio
Ubuntu: o **Lynis**, que audita contra verificações próprias, e o **OpenSCAP**, que lê guias escritos
no formato padrão legível por máquina. Depois você escreve a sua própria linha de base, que é o que
toda organização acaba fazendo com qualquer um dos guias acima.

## Um guia é um ponto de partida, não um veredito

Um guia decide o que é razoável para a maioria das máquinas de um tipo. A sua máquina é uma máquina
específica, com um trabalho específico. Então o trabalho é sempre os mesmos três passos: **medir
contra o guia, aplicar o que serve e anotar o porquê do que não serve.** A última seção desta aula
trata desse terceiro passo, porque é o que se pula.
