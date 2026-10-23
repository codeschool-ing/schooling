---
title: O que é este curso, e a AWS contra a qual ele roda
version: 1
---

**Este curso trata de defender o que você roda no data center de outra pessoa.** Ele pega o
vocabulário do curso `cloud` — regiões, serviços gerenciados, a linha entre a sua metade do trabalho
e a do provedor — e faz a cada peça a pergunta que um engenheiro de segurança faz: o que dá errado
aqui, como você ficaria sabendo, e como prova que está corrigido.

A imagem errada com que se costuma chegar é a de que a nuvem é um data center com marketing melhor,
e portanto as mesmas defesas valem sem mudança. Algumas valem. Mas a maioria das falhas deste curso
não tem equivalente on-premises: um bucket de armazenamento respondendo a qualquer pessoa na
internet, uma chave digitada num repositório em 2019 que ainda funciona, a conta de uma prestadora
que ninguém revogou e que consegue se dar todas as permissões. **Cada uma delas é uma configuração, e
cada uma foi feita pelo cliente, não pelo provedor.** A aula 2 faz dessa frase a espinha do curso.

## Como correm as dezessete aulas

| aulas | o que cobrem |
|---|---|
| 1 a 5 | o que muda na nuvem, quem responde pelo quê, e como os três grandes provedores chamam as mesmas coisas |
| 6 a 8 | identidade e rede: menor privilégio, chaves e segredos, isolamento |
| 9 a 11 | dados: armazenamento exposto, armazenamento pessoal no trabalho, criptografia com chaves gerenciadas |
| 12 a 14 | como a infraestrutura é escrita e publicada: infraestrutura como código, serverless, o fluxo de publicação |
| 15 a 17 | como você sabe e como prova: logs, varredura de postura, conformidade e residência de dados |

Toda aula é escrita do lado de quem defende. Quando uma aula precisa de uma falha, você a coloca no
seu próprio laboratório, observa a resposta que a mostra, corrige e observa a resposta mudar. Nada
aqui é receita para alcançar o sistema de outra pessoa.

## Uma clínica, e quatro pessoas

Os exemplos acompanham uma empresa pequena: uma clínica que marca consultas pela internet e guarda
os prontuários dos pacientes na AWS. Prontuário médico é o que torna o risco concreto, porque a aula
17 do curso `security-fundamentals` já mostrou que a LGPD trata dado de saúde como dado pessoal
*sensível*, com regras mais estritas que as de um endereço de e-mail.

Quatro pessoas trabalham na conta. **ana** é você, a engenheira de segurança que acabou de chegar.
**caio** escreve o sistema de agendamento. **bia** é analista e lê relatórios. **dani** era uma
prestadora de serviço que saiu em março, e a aula 6 trata do que ela deixou para trás.

## A AWS com que estas aulas conversam

**Você não precisa de conta AWS em nenhuma aula, nem de cartão.** A AWS deste curso é o **moto**, um
programa de código aberto que responde à API da AWS numa porta do seu próprio computador. Você fala
com ele pela linha de comando real da AWS, a que a AWS publica, então todo comando que digitar aqui é
um comando que poderia digitar contra uma conta real. O moto guarda o que ouve na memória, não roda
máquina nenhuma, não carrega tráfego e esquece tudo quando para.

Ele é uma imitação, e num curso de segurança o que importa numa imitação é **o que ela verifica e o
que ela só guarda**. Aula após aula você vai encontrar a mesma lacuna, então aqui está ela num lugar
só:

| | moto 5.2.3 |
|---|---|
| uma política de identidade permitindo ou negando uma ação | **verifica**, quando você o inicia com a verificação ligada (aula 6) |
| um pedido anônimo por um objeto que uma política de bucket ou uma ACL torna público | **verifica**: o objeto é servido ou recusado como a AWS faria |
| uma condição numa política (endereço de origem, MFA, região) | guarda, ignora |
| o S3 Block Public Access, as quatro chaves da aula 9 | guarda, não aplica nenhuma |
| as políticas de controle de serviço de uma organização | guarda, não aplica nenhuma |
| uma chave agendada para exclusão | ainda decifra, onde a AWS recusaria |
| o CloudTrail registrando o que aconteceu | cria a trilha, não registra nada |

**Uma aula nunca deixa o silêncio do moto valer como resposta da AWS.** Onde a AWS recusaria algo
que o moto permitiu, o texto diz isso ao lado da transcrição, e a afirmação vem da documentação da
AWS, não de uma execução. O mesmo vale para o Azure e o Google Cloud, que aqui não têm imitação
nenhuma: a aula 5 e as seções que comparam provedores são ensinadas pela documentação deles e
marcadas como não executadas.

As próximas três seções montam esse laboratório no seu computador. Siga-as em ordem na primeira vez;
depois, a última das três é a que vale reler quando algo não responder.
