---
title: Uma imagem sua, ou uma máquina configurada no boot
version: 1
---

Construir uma imagem parece trabalho de especialista, com ferramentas próprias. **Uma imagem sua é
uma máquina que você configurou, limpou do que fazia dela uma máquina específica, e copiou.** Toda
ferramenta que constrói imagens no Azure, de um botão do portal ao Azure VM Image Builder, roda os
mesmos passos. E existe um segundo jeito de ter uma máquina configurada, que é não construir imagem
nenhuma e entregar a uma imagem padrão as instruções dela no primeiro boot. Esta seção faz os dois, e
diz quando cada um ganha.

## Os passos, numa assinatura

Nada disto foi rodado neste curso, porque cada passo precisa de uma máquina numa assinatura. É a
sequência documentada pela Microsoft para uma máquina Linux, e cada comando é um que você digitaria.

1. Crie uma máquina a partir de uma imagem do Marketplace e configure: instale os pacotes,
   escreva a configuração, ponha a aplicação no lugar numa versão conhecida.
2. Desprovisione por dentro. Por SSH, na própria máquina:

   ```sh
   sudo waagent -deprovision+user
   ```

   O `waagent` é o Azure Linux Agent, que toda imagem Linux do Marketplace traz. Isto apaga o que faz
   da máquina uma máquina específica: os dados de provisionamento do agente, arquivos como as chaves
   de host do SSH, e a última conta de usuário que a plataforma criou. **Não tem volta**, e a
   documentação manda rodar só numa máquina que você está prestes a capturar. O `-deprovision`
   simples mantém esse usuário.
3. Avise o Azure que ela está generalizada. A máquina ainda está rodando; pare e marque:

   ```sh
   az vm deallocate --resource-group shop-rg --name shop-build
   az vm generalize --resource-group shop-rg --name shop-build
   ```

   Daí em diante a máquina não pode mais ser iniciada. Ela só existe para ser copiada.
4. Capture, como um dos dois tipos de imagem sua da primeira seção. Uma versão de imagem de
   galeria é `az sig image-version create ... --virtual-machine <o id da máquina>`, que a próxima
   seção declara em Bicep. Uma imagem gerenciada é um comando só:

   ```sh
   az image create --resource-group shop-rg --name shop-web-2026-10-30 --source shop-build
   ```

**Prefira a galeria, e a documentação da Microsoft diz o mesmo.** Uma imagem gerenciada só pode ser
feita a partir de uma máquina generalizada, só cria máquinas na própria região, não pode ser
compartilhada com outra assinatura e, como a primeira seção disse, não dá Trusted Launch. A
documentação a reserva para umas poucas imagens simples em desenvolvimento e teste.

## Generalizada ou especializada

O passo 2 é opcional numa galeria, e pulá-lo dá outro tipo de imagem:

| | generalizada | especializada |
|---|---|---|
| passo 2 | `waagent -deprovision` antes | pulado |
| no primeiro boot | ganha nome, usuário e chaves novos | é uma cópia da original, contas inclusive |
| o `osProfile` da máquina | dado na criação, como numa imagem do Marketplace | nenhum: não há nada a configurar |
| boot | mais lento, porque é configurada | mais rápido, porque já foi configurada uma vez |
| serve para | muitas máquinas diferentes a partir de uma imagem | cópias de uma máquina, ou uma restauração |

Uma imagem especializada mantém todas as contas da máquina de onde veio, e o nome de computador
dela, então dez máquinas feitas a partir dela começam com o mesmo nome. **Para uma imagem de onde
sairão as máquinas da loja, generalize.**

## Configurando no boot

O outro jeito é começar toda máquina pela imagem Ubuntu padrão e deixar que ela se configure. O
Azure entrega a uma máquina um bloco de **custom data** na criação, e as imagens Ubuntu do
Marketplace rodam o **cloud-init**, que lê esse bloco no primeiro boot e age conforme ele. Aqui está
um arquivo do cloud-init para as máquinas da loja. Salve como `cloud-init.yaml`:

```yaml
#cloud-config
# cloud-init.yaml
timezone: America/Sao_Paulo
package_update: true
packages:
  - docker.io
write_files:
  - path: /etc/shop/shop.env
    permissions: '0644'
    content: |
      SHOP_VERSION=1.0
      PORT=8080
runcmd:
  - systemctl enable --now docker
```

A primeira linha precisa continuar sendo a primeira: `#cloud-config` é como o cloud-init sabe que o
bloco é uma configuração e não um script. O resto está no vocabulário do próprio cloud-init. O
relógio da máquina vai para o fuso de São Paulo, o índice de pacotes é atualizado e o Docker
instalado, um arquivo de configurações é escrito onde um serviço poderia lê-lo, e o Docker é
iniciado. Nada ali cita o `apt`, porque o cloud-init chama o gerenciador de pacotes da própria
distribuição.

Para entregá-lo à máquina, acrescente uma linha ao `vm.bicep`, dentro do `osProfile` e depois do
`adminUsername`:

```bicep
    osProfile: {
      computerName: 'shop-web-1'
      adminUsername: adminUsername
      customData: loadFileAsBase64('cloud-init.yaml')
```

O `loadFileAsBase64()` é uma função do Bicep que **lê o arquivo durante a compilação**, não quando
a máquina é criada, e grava o conteúdo no template já codificado, que é a forma em que a API quer os
custom data:

```
ana@laptop:~/azure$ grep -n -B1 customData vm.bicep
34-      adminUsername: adminUsername
35:      customData: loadFileAsBase64('cloud-init.yaml')
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.osProfile.customData" vm.json
"[variables('$fxv#0')]"
ana@laptop:~/azure$ jq -r '.variables["$fxv#0"]' vm.json | base64 -d | head -n 3
#cloud-config
# cloud-init.yaml
timezone: America/Sao_Paulo
ana@laptop:~/azure$ wc -c cloud-init.yaml
267 cloud-init.yaml
```

O compilador pôs o arquivo no template como uma variável de nome gerado, e o `customData` da máquina
aponta para ela. Decodificada, é o arquivo. Então o template é completo sozinho, e uma mudança no
`cloud-init.yaml` só chega ao Azure pela próxima compilação.

O que um laptop não mostra é o cloud-init rodando, porque nada aqui dá boot numa máquina do Azure.
Quatro coisas sobre ele estão na documentação da Microsoft e importam na prática:

- **Custom data têm limite de 64 KB**; este arquivo tem 267 bytes.
- **Não são para segredos.** A documentação desaconselha pôr valores sensíveis ali; a lição 17 de
  `azure-operations` os põe no Key Vault.
- **Rodam no primeiro boot, e os custom data de uma máquina avulsa não mudam depois.** Os de um scale
  set mudam, e a lição 4 diz o que acontece com as máquinas que já estão rodando.
- **Uma falha dentro deles não faz a criação falhar.** O cloud-init avisa que a máquina está pronta
  sem esperar pela sua configuração, então um pacote que não instalou é uma máquina que parece
  saudável. A documentação manda você construir o seu próprio jeito de ficar sabendo.

## Assar na imagem ou configurar no boot

| | na imagem | no primeiro boot, com cloud-init |
|---|---|---|
| tempo da criação até atender | o boot | o boot e cada instalação |
| depende de, na criação | nada fora da máquina | espelhos de pacotes, downloads |
| duas máquinas com um mês de diferença | os mesmos bytes | o que estava em vigor em cada dia |
| uma correção de segurança | uma versão nova da imagem, depois máquinas novas | a próxima máquina criada já pega |

**Asse o que é lento de instalar e muda pouco; configure no boot o que difere por máquina.** Para a
loja, isso quer dizer o Docker e os pacotes de base na imagem, e a versão da API de pedidos e o
arquivo de configurações no boot. Os dois se combinam: uma imagem de galeria aceita custom data como
qualquer outra.

## O serviço que roda os passos por você

Feitos à mão, os quatro passos são uma lista em que alguém esquece uma linha. O **Azure VM Image
Builder** é o serviço gerenciado da Microsoft para eles, construído sobre o Packer da HashiCorp.
Você envia um *image template* que nomeia uma imagem de origem, uma lista de customizações (scripts
de shell e arquivos, no Linux) e para onde vai o resultado: uma galeria, uma imagem gerenciada ou um
arquivo de disco. Rodar o template faz o Image Builder criar uma máquina de build num grupo de
recursos de preparação só dele, chamado `IT_` seguido do seu grupo de recursos e do nome do
template, rodar as customizações, generalizar, capturar e apagar a máquina de build. A documentação
cita o tamanho padrão do build, `Standard_D2ds_v4` para uma imagem de geração 2, e diz que o custo é
o das máquinas, discos, armazenamento e rede que ele usa enquanto trabalha. Ele está disponível em
Brazil South. Não foi rodado aqui: precisa de uma assinatura.
