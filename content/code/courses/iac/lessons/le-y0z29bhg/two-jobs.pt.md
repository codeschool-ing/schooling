---
title: Provisionamento e gerência de configuração
version: 1
---

"Infraestrutura como código" cobre dois trabalhos que parecem iguais de longe e são diferentes de
perto. Boa parte da confusão sobre qual ferramenta usar vem de tratá-los como um só.

**Provisionamento** é fazer os recursos existirem: a rede, a sub-rede, a regra de firewall, a
máquina, o bucket, o banco de dados, o registro de DNS. Cada um é algo que um provedor vende, criado
e alterado pela API do provedor, e cada um tem um conjunto pequeno de atributos que você consegue
nomear: esta VPC tem a faixa `10.20.0.0/16`, esta máquina é uma `t3.micro` em `sa-east-1a`. O
`network.sh` da Ana era provisionamento. Terraform, OpenTofu, CloudFormation e Pulumi fazem esse
trabalho.

**Gerência de configuração** é o que acontece dentro de uma máquina depois que ela existe: quais
pacotes estão instalados, o que há em `/etc/nginx/nginx.conf`, quais usuários podem entrar, quais
serviços estão rodando. Nada disso é visível para a API da nuvem. A ferramenta chega ao próprio
sistema operacional, por SSH ou por um agente instalado na máquina. Ansible, Chef, Puppet e Salt
fazem esse trabalho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas camadas, uma dentro da outra. A de fora, provisionamento, guarda o que a API do provedor de nuvem cria: a VPC, a sub-rede, o security group, a máquina e o bucket, feitos por Terraform, OpenTofu, CloudFormation ou Pulumi. Dentro da máquina está a segunda camada, gerência de configuração: pacotes, arquivos, usuários e serviços, alcançados por SSH ou por um agente, com Ansible, Chef, Puppet ou Salt.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Provisionamento: a API do provedor</text><text x=\"40.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Terraform, OpenTofu, CloudFormation, Pulumi</text><rect x=\"40\" y=\"80\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">VPC</text><rect x=\"40\" y=\"145\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede</text><rect x=\"40\" y=\"210\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">security group</text><rect x=\"560\" y=\"80\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bucket</text><rect x=\"560\" y=\"145\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">registro DNS</text><rect x=\"200\" y=\"80\" width=\"340\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma máquina</text><rect x=\"220\" y=\"115\" width=\"300\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Gerência de configuração: dentro do SO</text><text x=\"235.0\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Ansible, Chef, Puppet, Salt, por SSH ou agente</text><text x=\"235.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pacotes</text><text x=\"235.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/etc/nginx/nginx.conf</text><text x=\"235.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">usuários</text><text x=\"380.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">serviços</text></svg>", "caption": "Duas camadas. A API da nuvem consegue criar a máquina e não enxerga dentro dela; isso é um segundo trabalho, para outro tipo de ferramenta.", "same": ["Terraform, OpenTofu, CloudFormation, Pulumi", "VPC", "security group", "bucket"]}
```

Os dois trabalhos fazem perguntas diferentes, e é por isso que ganharam ferramentas diferentes. Uma
ferramenta de provisionamento pergunta *"existe uma VPC com esta faixa? se não, crie uma"*, e a
resposta vem de uma chamada de API. Uma ferramenta de configuração pergunta *"o nginx está
instalado, nesta versão, com este arquivo, e rodando?"*, e a resposta vem de olhar um disco e uma
tabela de processos em cada uma de trinta máquinas, algumas das quais podem estar desligadas.

**A sobreposição existe, e é onde começa a maior parte dos problemas.** O Ansible tem módulos que
criam recursos de nuvem, e o Terraform consegue rodar um script numa máquina depois de criá-la. Os
dois funcionam. Os dois são a segunda melhor ferramenta para aquela metade do trabalho: o Ansible
não guarda registro do que criou, então não sabe o que remover quando uma linha é apagada, e um
script que o Terraform roda uma vez na criação nunca mais roda, então a configuração que ele fez
deriva como qualquer outra. A aula 18 faz a passagem entre os dois de propósito: o Terraform cria as
máquinas e anota os endereços delas, e o Ansible os lê.

Há uma terceira resposta, que evita configurar uma máquina em execução: instalar tudo numa
**imagem** antes de a máquina existir, e ligar as máquinas a partir dela. Essa é a aula 20, e ela
transforma a maior parte da gerência de configuração de volta em provisionamento.
