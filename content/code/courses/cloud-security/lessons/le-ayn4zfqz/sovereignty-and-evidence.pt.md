---
title: Qual lei alcança o dado, e o que mostrar ao auditor
version: 1
---

**Manter o dado no Brasil decide em discos de qual país ele fica. Não decide quais governos podem
mandar o provedor entregá-lo, porque isso segue o provedor tanto quanto o dado. E nada disso conta
para conformidade enquanto a clínica não conseguir mostrar.** Esta seção trata das duas coisas, uma de
cada vez. Tudo nela vem de lei publicada e da documentação dos provedores; nada é algo que um
laboratório consiga rodar.

## Soberania: três datas que valem saber

**2018, o CLOUD Act dos Estados Unidos.** Ele deixou explícito que um provedor sujeito à lei dos
Estados Unidos precisa entregar dados que estejam em sua posse, guarda ou controle quando recebe uma
ordem judicial válida, **estejam os dados guardados nos Estados Unidos ou fora**. Os três grandes
provedores de nuvem são empresas americanas. Então um prontuário num disco em São Paulo, nas mãos de
um deles, está ao alcance de uma ordem americana tanto quanto de uma brasileira. A lei também dá ao
provedor um caminho para contestar uma ordem que conflite com a lei de certos outros países, e os
provedores publicam quantas ordens recebem; nenhuma das duas coisas muda o alcance.

**2020, *Schrems II*.** O Tribunal de Justiça da União Europeia derrubou o Privacy Shield, o acordo
pelo qual dados pessoais iam da União Europeia para os Estados Unidos, com o argumento de que a lei
americana de vigilância não dava aos europeus proteção equivalente. Por um tempo, toda transferência
para um provedor americano precisou de justificativa própria.

**2023, o EU-US Data Privacy Framework.** A Comissão Europeia adotou uma nova decisão de adequação para
empresas americanas que se certificam por ele. É o terceiro acordo do tipo, depois do Safe Harbour e
do Privacy Shield, e os dois anteriores terminaram no tribunal.

Nada disso é lei brasileira, e a clínica não está na Europa. Está aqui porque é o registro mais claro
da pergunta que a soberania faz — **um governo estrangeiro consegue alcançar este dado pela empresa
que o guarda?** — e porque o próprio teste de adequação da LGPD, no artigo 34, a faz a todo país para
onde o dado vai.

O que os provedores vendem em resposta tem nomes como *nuvem soberana*: regiões operadas por equipe
local, sob uma pessoa jurídica local, às vezes com as chaves de criptografia guardadas fora do
provedor de vez, um passo além das chaves gerenciadas pelo cliente da aula 11. A AWS anunciou uma
European Sovereign Cloud em 2023. Se algo disso responde à pergunta para uma determinada lei é um
julgamento jurídico, e a contribuição útil da engenharia é saber exatamente onde está cada cópia e
cada chave.

## Conformidade: evidência, dos dois lados da linha

Um auditor faz uma pergunta de muitas formas: **me mostre**. A linha da aula 2 divide a resposta.

**A metade do provedor é provada pelo provedor.** AWS, Microsoft e Google publicam relatórios de
auditores independentes sobre os próprios controles — relatórios SOC 2, certificados ISO 27001,
atestados PCI DSS — e os disponibilizam aos clientes; a AWS, por um serviço do console chamado AWS
Artifact. **Não executado**: precisa de uma conta real. A clínica os baixa e os arquiva. Ela não
precisa verificar o data center do provedor, e nem conseguiria.

**A metade da clínica é provada pela clínica**, e este curso vem produzindo essa evidência desde a
aula 1:

| o auditor pergunta | a evidência | aula |
|---|---|---|
| onde está o dado pessoal? | o inventário de regiões desta aula, com a data | 17 |
| quem consegue chegar a ele? | o relatório de credenciais, as políticas anexadas a cada identidade | 6 |
| ele é cifrado, e com a chave de quem? | a criptografia padrão do bucket e a política da chave | 11 |
| quem mudou o quê, e quando? | a trilha de auditoria, guardada onde quem aparece nela não consegue apagar | 15 |
| como você sabe que a configuração continua certa? | a varredura de postura, os achados e as exceções com data | 16 |

As aulas 13 e 14 do curso `security-fundamentals` descreveram para que serve um auditor e o que a ISO
27001 pede. O que a nuvem acrescenta é que **a maior parte dessa evidência é a saída de um comando**,
então pode ser produzida de novo na manhã da auditoria em vez de reconstruída de memória. Uma captura
de tela mostra um momento que alguém escolheu. Um comando que qualquer um pode rodar de novo, com a
saída e a data, mostra o estado como ele era, e é nisso que um auditor consegue confiar.

## O curso numa linha, de novo

A aula 1 disse que na nuvem quase toda defesa é uma configuração, e quase toda falha também.
Conformidade é a mesma frase lida por alguém de fora da clínica: **toda configuração que protege os
pacientes precisa ser uma que a clínica consegue mostrar.**
