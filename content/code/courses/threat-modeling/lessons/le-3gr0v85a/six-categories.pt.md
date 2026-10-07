---
title: Seis jeitos de dar errado
version: 1
---

"O que pode dar errado?", perguntado a uma sala, produz o que a sala lembra: injeção, porque todo
mundo já ouviu falar, e o que machucou alguém no mês passado. A lista não tem forma, então não há
como saber o que ela deixou de fora. O **STRIDE** dá forma a ela. Foi escrito na Microsoft em 1999
por Loren Kohnfelder e Praerit Garg. Ainda é o jeito mais usado de responder à segunda pergunta,
porque faz uma coisa bem: **transforma "o que pode dar errado" em seis perguntas mais estreitas,
cada uma a violação de uma propriedade que você quer que o sistema tenha.**

| letra | ameaça | a propriedade que viola | no portal |
|---|---|---|---|
| **S** | **spoofing (falsificação)**: fingir ser alguém ou algo que não é | **autenticação** | um pedido fingindo vir do gateway de pagamento |
| **T** | **tampering (adulteração)**: mudar dado ou código sem permissão | **integridade** | um PDF de exame trocado por outro arquivo |
| **R** | **repudiation (repúdio)**: negar uma ação, sem como provar o contrário | **não repúdio** | uma anotação clínica editada, sem registro de quem mudou |
| **I** | **information disclosure (divulgação de informação)**: dado chegando a quem não pode lê-lo | **confidencialidade** | um paciente baixando o exame de outro paciente |
| **D** | **denial of service (negação de serviço)**: deixar o sistema indisponível para quem precisa dele | **disponibilidade** | uploads enchendo o armazenamento até não dar mais para mandar exames |
| **E** | **elevation of privilege (elevação de privilégio)**: fazer o que o seu papel não permite | **autorização** | uma senha de recepcionista roubada chegando a todos os prontuários |

A coluna da direita é a metade útil. Três das seis são a tríade CIA da aula 1 de
`security-fundamentals`: confidencialidade, integridade, disponibilidade. As outras três são sobre
pessoas: são quem dizem ser (autenticação), conseguem negar o que fizeram (não repúdio), e têm
permissão para fazer (autorização). Cada letra, então, é uma pergunta que você faz a um elemento:
*alguém conseguiria quebrar esta propriedade aqui?*

### As letras se sobrepõem, e tudo bem

Um ataque real é várias letras em sequência. Fazer phishing com uma recepcionista (S) leva a ler
todos os prontuários (E, depois I). Gastar tempo decidindo se uma ameaça é "de verdade" falsificação
ou elevação é tempo que não vai para achar a próxima. As categorias são um estímulo para achar
ameaças, não um sistema de arquivamento; registre cada ameaça na letra que fez você pensar nela e
siga em frente.

### O que o STRIDE não é

**Não é uma lista de ataques.** "Injeção de SQL" não é categoria do STRIDE; é um jeito de causar
adulteração, divulgação ou elevação, conforme o que a consulta faz. O curso `attacks-threats`
cataloga técnicas. O STRIDE pergunta qual propriedade cada parte do seu sistema poderia perder,
que é uma pergunta sobre o seu projeto, e não sobre as ferramentas dos atacantes.

**Não ordena nada.** Uma lista STRIDE diz o que pode dar errado. Quão provável é cada item e quanto
custaria são as aulas 9 a 11, e uma ameaça achada com STRIDE não tem nota nenhuma até lá.
