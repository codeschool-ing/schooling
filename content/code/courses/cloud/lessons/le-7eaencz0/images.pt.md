---
title: "Imagens: o disco de onde uma instância parte"
version: 1
---

Uma imagem costuma ser descrita como "o sistema operacional que você escolhe", como se fosse uma opção
de menu igual ao tipo de instância. **Uma imagem é um disco.** Mais precisamente, é um modelo de disco
de boot: o sistema operacional e o que mais foi instalado e configurado nele quando a imagem foi
feita. Lançar uma instância copia esse modelo para um disco novo e dá boot a partir dele. A AWS chama
isso de AMI, Amazon Machine Image; os outros provedores dizem imagem.

## De onde vêm as imagens

**Imagens publicadas** são feitas por quem faz o sistema operacional. A Canonical publica o Ubuntu, o
Debian publica o Debian, a AWS publica o Amazon Linux, e cada um segue lançando builds novas da mesma
versão com as correções de segurança mais recentes. São o ponto de partida de quase todo mundo, e
trazem quase nada: o sistema, o agente de nuvem que lê o user data e um servidor SSH.

**Suas próprias imagens** partem de uma dessas. Você a lança, instala o runtime, as dependências, a
configuração e às vezes a própria aplicação, e salva o disco como uma imagem nova. Uma imagem feita
assim e usada como ponto de partida padrão das máquinas de uma equipe se chama **golden image**.
Fazer uma à mão funciona uma vez; as equipes as constroem com uma ferramenta que executa os mesmos
passos toda vez, e o Packer é a mais comum. O curso `iac` constrói imagens desse jeito.

Uma imagem vive numa região, e o id dela só tem sentido ali. A mesma versão do Ubuntu tem um id em
`sa-east-1` e outro em `us-east-1`, e uma golden image feita em São Paulo precisa ser copiada antes
que qualquer coisa na Virgínia possa usá-la. Ela também fica guardada, e armazenamento é cobrado: na
AWS uma imagem é mantida como snapshots de disco, a 0,0680 USD por GB-mês em `sa-east-1` na tabela.
Uma imagem de 20 GB guardada inteira custa no máximo 1,36 USD por mês; snapshots guardam só os blocos
que foram escritos, então muitas vezes sai menos, e isso se acumula quando cada build é guardada para
sempre.

## Embutir na imagem ou instalar no boot

Toda máquina precisa do mesmo software, e há dois lugares para pôr esse trabalho. Você pode
**embutir** na imagem, para que a instância dê boot pronta. Ou pode partir de uma imagem publicada e
**configurar no boot**, com um user data que instala e prepara tudo no primeiro início. A troca tem
dois lados, e os dois importam quando há mais de uma máquina.

| | embutir na imagem | configurar no boot |
|---|---|---|
| tempo do lançamento até atender | o próprio boot | o boot mais cada instalação, muitas vezes minutos |
| depende, no boot, de | nada fora da instância | espelhos de pacotes e downloads acessíveis |
| duas máquinas lançadas com uma semana de diferença | os mesmos bytes | o que os espelhos tinham em cada dia |
| uma correção de segurança | uma imagem nova, depois trocar as máquinas | a próxima máquina já pega |

A terceira linha é o **drift**: máquinas que deveriam ser iguais e não são. Uma configuração que roda
`apt install nginx` no boot pega a versão do `nginx` que o espelho tem naquele dia, então um grupo que
cresceu ao longo de um mês pode ter três versões dele sem que ninguém tenha decidido isso. Uma imagem
embutida não sofre drift, porque os bytes dela foram fixados na construção. Ela envelhece, e a única
cura é reconstruí-la e trocar toda máquina que roda a antiga.

A segunda linha importa no dia em que falha. Uma máquina que instala o software no boot precisa que
os espelhos respondam naquele momento, e uma máquina nova é lançada justamente quando algo está sob
pressão: um pico de tráfego, uma zona que caiu. Uma máquina de imagem embutida não precisa de nada de
fora para começar a atender.

A maioria das equipes fica no meio-termo. **Embuta o que é lento e estável**, o runtime, os pacotes,
a aplicação numa versão conhecida. **Configure no boot o que muda por máquina**, o hostname, a que
ambiente ela pertence, um segredo buscado no cofre de segredos do provedor em vez de gravado na
imagem. A primeira linha é o motivo de isso importar para o resto desta aula: quando o autoscaling
pede uma máquina nova, os minutos entre o lançamento e o atendimento são minutos de sobrecarga, e é na
imagem que a maior parte deles se ganha ou se perde.
