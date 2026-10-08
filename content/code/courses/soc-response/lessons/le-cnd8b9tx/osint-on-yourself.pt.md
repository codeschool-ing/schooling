---
title: OSINT, apontada para você mesmo
version: 1
---

**OSINT**, inteligência de fontes abertas, é o que se aprende a partir de fontes públicas: sites, registros
públicos, logs de certificados, buscadores, redes sociais. Para um SOC, o alvo mais útil é **a própria
empresa**, vista de fora, porque é dessa visão que parte quem prepara um ataque.

O que vale conferir sobre a sua própria organização, com regularidade:

| o quê | por que importa | onde aparece |
|---|---|---|
| **nomes DNS públicos** | todo nome publicado é uma porta em que alguém pode bater | o DNS da empresa, e os logs de transparência de certificados, que listam cada certificado emitido para os domínios dela |
| **serviços alcançáveis pela internet** | um servidor de teste esquecido é o caminho de entrada de costume | buscadores que indexam serviços abertos |
| **dados da equipe** | nomes, cargos e o formato dos e-mails são a matéria-prima do phishing | o site da empresa e as redes profissionais |
| **credenciais vazadas** | uma senha reaproveitada de um site invadido abre uma porta que parece legítima | serviços de aviso de vazamento, que podem alertar sobre um domínio da empresa |
| **código e documentos** | chaves e nomes de máquinas internas esquecidos em repositórios ou arquivos públicos | hospedagem pública de código, metadados de documentos |

A rodada de tentativas de quinta começou por nomes, e vários eram reais: ana, bruno, carla, diego, helena. De
onde vieram? O próprio site da empresa lista a equipe. Isso é uma descoberta de OSINT sobre você mesmo, e a
correção não é segredo, e sim **tornar os nomes inúteis sozinhos**: nada de SSH só com senha vindo da
internet, que é assunto da aula 14.

Três limites mantêm esse trabalho defensável. Colete **passivamente**: leia o que está publicado, não
sonde sistemas. Olhe **a sua própria organização, ou uma que autorizou você por escrito**; as mesmas técnicas
apontadas para a organização de outra pessoa são reconhecimento. E lembre que perfis de funcionários são
**dados pessoais** pela LGPD: colete o que a defesa precisa, guarde pelo menor tempo que a finalidade
permite, e não monte um dossiê sobre pessoas porque uma ferramenta facilitou.
