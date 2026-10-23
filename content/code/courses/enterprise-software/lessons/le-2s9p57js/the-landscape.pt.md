---
title: O panorama da automação de processos
version: 1
---

Todo produto desta seção é vendido com a palavra *automação*, e quase todos mostram um diagrama de
caixas e setas na primeira página do site. Por isso o erro comum é tratá-los como um só mercado,
enfileirar os fornecedores e comparar preços. **Eles automatizam coisas diferentes, e a primeira
pergunta é o que o problema precisa que seja automatizado: uma tela, um salto curto entre duas
aplicações, ou um processo com pessoas dentro que dura dias.** O fornecedor vem depois disso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l06-landscape\" aria-label=\"Um mapa das ferramentas de automação de processos em dois eixos. Na horizontal: o que é automatizado, de uma tela, passando por uma tarefa entre aplicações, até um processo com pessoas que dura dias. Na vertical: quem constrói, de um usuário de negócio em cima a um desenvolvedor profissional embaixo. Ferramentas de RPA, como UiPath e os fluxos de desktop do Power Automate, ficam na tela, construídas pelos dois. Fluxos low-code, os fluxos de nuvem do Power Automate, ficam numa tarefa entre aplicações, construídos por usuários de negócio. Código de integração e o ESB ficam numa tarefa entre aplicações, construídos por desenvolvedores. Suítes de BPM, como IBM Business Automation Workflow, Pega e Appian, ficam no processo longo, construídas por especialistas no produto. Motores abertos, como Camunda, Flowable e jBPM, ficam no processo longo, construídos por desenvolvedores.\"><path d=\"M110.0 270.0 L705.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 40.0 L110.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma tela</text><text x=\"410.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma tarefa entre apps</text><text x=\"610.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um processo com pessoas, dias</text><text x=\"407.5\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que é automatizado →</text><text x=\"55.0\" y=\"53.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">usuário de</text><text x=\"55.0\" y=\"66.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">negócio</text><text x=\"55.0\" y=\"243.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desenvolvedor</text><text x=\"55.0\" y=\"256.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">profissional</text><text x=\"55.0\" y=\"147.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">construído</text><text x=\"55.0\" y=\"162.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">por ↕</text><rect x=\"118.0\" y=\"125.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RPA</text><text x=\"210.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">UiPath, Automation Anywhere,</text><text x=\"210.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Power Automate desktop</text><rect x=\"318.0\" y=\"45.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fluxos low-code</text><text x=\"410.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fluxos de nuvem do</text><text x=\"410.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Power Automate (aula 3)</text><rect x=\"318.0\" y=\"195.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">código de integração</text><text x=\"410.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o ESB (aula 8),</text><text x=\"410.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">serviços que você escreve</text><rect x=\"518.0\" y=\"90.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">suítes de BPM</text><text x=\"610.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IBM Business Automation</text><text x=\"610.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Workflow, Pega, Appian</text><rect x=\"518.0\" y=\"195.0\" width=\"184.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">motores abertos</text><text x=\"610.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Camunda, Flowable, jBPM</text><text x=\"610.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no seu próprio código</text></svg>", "caption": "A pergunta é o que a ferramenta automatiza, antes de quem a vende. O RPA opera uma tela; uma suíte de BPM ou um motor guarda um processo longo com pessoas dentro.", "same": ["Camunda, Flowable, jBPM", "IBM Business Automation", "Power Automate desktop", "RPA", "UiPath, Automation Anywhere,", "Workflow, Pega, Appian"]}
```

## Suítes de BPM

Uma suíte é o que a seção anterior desmontou: modelador, motor, lista de tarefas, formulários,
integração e monitoramento num produto só, sob uma licença só, com um fornecedor só para ligar. O
Business Automation Workflow da IBM é uma. Pega e Appian são os outros dois nomes que um arquiteto
mais encontra em empresas grandes. A Pega fez o nome com regras de negócio e gestão de casos; a
Appian se vende antes de tudo como uma plataforma low-code com processos dentro. As três são
compradas por contrato corporativo, como a da IBM.

O que uma suíte dá é velocidade no primeiro processo e um fornecedor que responde por tudo. Os
formulários, a caixa de entrada, os papéis e os relatórios vêm junto, e um time que conhece o produto
consegue pôr um processo de aprovação novo na frente dos usuários em semanas. O que ela custa é o
assunto da seção 05 desta aula. Em resumo: **o processo vive no formato do fornecedor, e quem
consegue mudá-lo são as pessoas que conhecem aquele produto.**

## Motores abertos

Camunda, Flowable e jBPM são motores, não suítes. São bibliotecas ou servidores que os seus próprios
desenvolvedores rodam, e os processos deles são arquivos BPMN 2.0 que vivem no seu repositório, ao
lado do código. O jBPM é o mais antigo dos três. O Camunda e o Flowable começaram como forks do
Activiti, um motor criado pelo autor do jBPM. A árvore genealógica importa menos que o que eles têm em
comum: o modelo é um arquivo XML padrão, e o comportamento por trás de cada passo é código que o seu
time escreve numa linguagem comum, testado e implantado como o resto do seu software.

O motor continua fazendo a parte difícil. Ele guarda as instâncias, acorda cada uma, roda os timers e
mantém o histórico. O que você escreve é tudo o que uma suíte teria entregado: os formulários, a
caixa de entrada se os usuários precisarem de uma, os relatórios. As empresas por trás do Camunda e do
Flowable vendem edições corporativas com mais dessas ferramentas. Os termos de licença também mudaram entre versões principais, então **leia a licença da versão exata que você rodaria, não a que um post de
blog descreve.**

É a família que serve a um processo que a empresa muda com frequência e considera seu. Ela exige
desenvolvedores à vontade para cuidar de um sistema de longa duração, e os times de produto da Serra
Alta são assim.

## Fluxos low-code

O Power Automate, que a aula 3 encontrou se espalhando pelos departamentos da Serra Alta, é o exemplo
que todo funcionário já tem. Um fluxo de nuvem começa num evento (chega um e-mail, uma linha é
adicionada a uma lista, um formulário é enviado), executa alguns passos entre aplicações por meio de
conectores e termina. Há aprovações como passo pronto, então um fluxo consegue pedir a um gestor que
diga sim.

Isso faz os fluxos low-code parecerem uma suíte de BPM leve, e para uma aprovação de dois passos que
termina no mesmo dia eles são uma boa. A diferença aparece quando o processo fica longo. **Um fluxo
foi feito para rodar por minutos ou horas; uma instância de processo foi feita para viver um mês.** Os
fluxos têm limites documentados de quanto uma execução pode durar, e o histórico de uma execução é
guardado por um período limitado, e não como o registro permanente que um motor mantém. Antes de
confiar a um fluxo um processo que espera uma visita da qualidade ou um contrato assinado, procure o
limite de duração de execução do seu plano e compare com a instância mais lenta que você já teve.

A questão de governança que a aula 3 levantou vale aqui também: um fluxo pertence a quem o construiu,
e a Serra Alta achou fluxos cujo autor já tinha saído da empresa.

## Automação robótica de processos

Ferramentas de RPA, como UiPath, Automation Anywhere e os fluxos de desktop do Power Automate,
operam uma interface de usuário. Um robô de software abre a aplicação, lê o que está na tela, clica,
digita e copia valores de uma janela para outra, exatamente como uma pessoa faria. **O RPA automatiza
uma tela, não um processo.** O que ele substitui são as mãos de uma pessoa, e ele não sabe nada do
passo de negócio que aquelas mãos estavam fazendo.

Isso o torna honesto numa situação e frágil em outra.

Ele é honesto quando não há outro jeito de entrar. O cadastro de fazenda da Serra Alta termina com um
funcionário redigitando a fazenda nova no Coleta, o sistema de coleta de leite no IBM i: 23 campos
numa tela verde, copiados do formulário do BPM, cerca de 220 vezes por ano. O Coleta não tem API, e
ninguém vai dar uma a ele, porque a aula 13 trata de aposentá-lo. Um robô que digita esses 23 campos
é uma peça de engenharia razoável para os anos que restam ao Coleta, desde que todos o chamem pelo
que ele é: uma ponte temporária para um sistema sem interface.

Ele é frágil porque a tela não é um contrato. Quando um campo muda de lugar, um rótulo muda ou aparece
uma janela de confirmação, o robô ou para, que é o caso bom, ou digita um valor no campo errado e
segue em frente, que é o ruim. **Uma API muda com aviso; uma tela muda porque alguém a melhorou.** A
tela do Coleta quase não mudou em vinte anos, e é essa circunstância incomum que torna um robô seguro
ali. Um robô na tela de um SaaS que o fornecedor redesenha duas vezes por ano é um contrato de
manutenção com você mesmo.

Um robô também esconde o problema que resolve. Depois que a redigitação é automatizada, ninguém mais
sente o custo de um sistema sem interface, e a pressão para consertá-lo some. Use o RPA como uma
ponte com data para acabar.

## Código de integração não é automação de processos

Mais uma família aparece no mapa porque é confundida com as outras. Um fluxo no barramento de
integração da Serra Alta que transforma um pedido de venda numa mensagem EDI, ou o arquivo noturno do
Coleta para o SAP, move dados entre sistemas. Não tem pessoas, não tem caixa de entrada e nada nele
espera semanas. Isso é integração, e as aulas 8 a 11 tratam dela. A confusão corre nos dois sentidos. Um time põe uma transformação de mensagem de dois segundos numa
suíte de BPM porque a suíte é o que ele conhece; outro monta uma aprovação de um mês com mensagens e
flags no banco porque nunca viu um
motor.

## Como saber de qual um problema precisa

As perguntas são curtas, e funcionam melhor feitas nesta ordem.

| pergunta | se a resposta for sim |
| --- | --- |
| Há uma pessoa decidindo algo, e o caso pode ficar aberto por dias? | um motor de processos: uma suíte ou um motor aberto |
| A empresa muda esse processo com frequência e o considera seu? | tenda para um motor aberto no seu próprio código |
| São alguns passos entre aplicações que terminam em poucas horas? | um fluxo low-code, sob a governança de alguém |
| São dados se movendo entre sistemas sem ninguém envolvido? | integração (aulas 8 a 11), não uma ferramenta de processos |
| O único jeito de entrar num sistema é a tela dele? | RPA, como ponte com data para acabar |

Passe as necessidades da própria Serra Alta por ela e elas caem em lugares diferentes. A aprovação de
crédito tem pessoas decidindo e casos abertos por dias, então precisa de um motor. A redigitação no
Coleta é uma tela sem interface, então um robô é honesto ali até o Coleta sair. Mandar a um cliente o
certificado de análise quando um lote é liberado são alguns passos entre o SAP, o Documentum e o
e-mail, terminados em minutos, então um fluxo ou uma integração servem. Nenhuma das três respostas é
"a ferramenta que já pagamos", que é a resposta que a maioria das empresas dá primeiro.
