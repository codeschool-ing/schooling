---
title: Três pacotes pelos dois filtros
version: 1
---

**Um pacote que entra numa sub-rede encontra primeiro a network ACL e depois o security group, e
precisa passar pelos dois.** Na saída ele os encontra na ordem inversa. Os dois filtros não sabem um
do outro. A network ACL não vê que grupo uma interface carrega, e o security group nunca vê um
pacote que a network ACL descartou. Esta seção leva três pacotes pelas regras que a loja tem agora,
do jeito que você faria num quadro branco. Nada no laboratório vai levá-los por você.

## Os três percursos

**Um cliente em `203.0.113.50` abre a loja na porta 443.** O pacote chega à interface do load
balancer em `public-a`. A network ACL `public` lê as regras de entrada a partir da menor. A regra 90
nomeia outro endereço e não casa, e a regra 100 permite TCP 443 de qualquer lugar, então o pacote
entra na sub-rede. O `alb-sg` permite 443 de `0.0.0.0/0`, então ele chega ao load balancer. A
resposta sai para a porta efêmera do cliente, digamos 50812. O `alb-sg` a deixa sair porque ela
pertence a uma conexão que ele deixou entrar. A network ACL a deixa sair porque a regra 100 de saída
permite de 1024 a 65535. **Dois filtros, quatro decisões, todas de permissão.**

**`198.51.100.7` tenta a mesma coisa.** A regra 90 casa primeiro e nega, e a network ACL descarta o
pacote na borda da sub-rede. O `alb-sg` nunca o vê, e nem poderia tê-lo recusado. Ele permite 443 de
todo lugar, e um security group não tem como dizer "menos".

**O load balancer está mal configurado e manda um pedido direto para o banco de dados**, em
`10.20.97.10` porta 5432. A network ACL `public` o deixa sair pela regra 120, e `data-a` está na
network ACL padrão, que o deixa entrar. Então o `db-sg` lê sua única regra: 5432 de interfaces que
carregam o `app-sg`. A interface do load balancer carrega o `alb-sg`, então **o security group o
recusa**, embora todo endereço e toda regra de sub-rede no caminho o tenham permitido. O mesmo
pedido vindo de uma máquina da aplicação passaria. É exatamente a corrente que os três grupos
descrevem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" data-fig=\"l18-walks\" aria-label=\"Três pacotes, cada um encontrando a network ACL na borda da sub-rede e depois o security group na interface. Primeiro: um cliente em 203.0.113.50 manda para a porta 443. A network ACL pública pula a regra 90, que nomeia outro endereço, e a regra 100 permite a 443; o alb-sg permite 443 de qualquer lugar; o pacote chega ao load balancer. Segundo: 198.51.100.7 manda para a porta 443. A regra 90 da network ACL o nega, e o alb-sg nunca o vê, embora o fosse permitir. Terceiro: o load balancer manda para o banco de dados na porta 5432. A network ACL pública o deixa sair pela regra 120 e a network ACL padrão de data-a o deixa entrar, mas o db-sg só permite 5432 vindo do app-sg, e o load balancer carrega o alb-sg, então o security group o recusa.\"><defs><marker id=\"l18-walks-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-walks-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"82.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">de</text><text x=\"260.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">network ACL, na sub-rede</text><text x=\"460.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">security group, na interface</text><text x=\"637.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">para</text><path d=\"M20.0 36.0 L700.0 36.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"20.0\" y=\"62.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um cliente</text><text x=\"82.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.50</text><rect x=\"175.0\" y=\"62.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">90: no match</text><text x=\"260.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">100: allow 443</text><rect x=\"375.0\" y=\"62.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">alb-sg:</text><text x=\"460.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">443 from 0.0.0.0/0</text><rect x=\"575.0\" y=\"62.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"637.5\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load balancer</text><text x=\"637.5\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">public-a</text><path d=\"M147.0 88.0 L172.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><path d=\"M347.0 88.0 L372.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><path d=\"M547.0 88.0 L572.0 88.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">permitido duas vezes na entrada, e a resposta sai pela regra 100 de saída</text><rect x=\"20.0\" y=\"182.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o recusado</text><text x=\"82.5\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">198.51.100.7</text><rect x=\"175.0\" y=\"182.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">90: deny</text><text x=\"260.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">198.51.100.7/32</text><rect x=\"375.0\" y=\"182.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"460.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o permitiria,</text><text x=\"460.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca o vê</text><rect x=\"575.0\" y=\"182.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"637.5\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">load balancer</text><text x=\"637.5\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">public-a</text><path d=\"M147.0 208.0 L172.0 208.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-amber)\"></path><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">descartado na borda da sub-rede: um security group não sabe negar</text><rect x=\"20.0\" y=\"302.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load balancer</text><text x=\"82.5\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carrega alb-sg</text><rect x=\"175.0\" y=\"302.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">public out 120</text><text x=\"260.0\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">data-a in: 100</text><rect x=\"375.0\" y=\"302.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460.0\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">db-sg: 5432</text><text x=\"460.0\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só do app-sg</text><rect x=\"575.0\" y=\"302.0\" width=\"125.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"637.5\" y=\"320.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">banco de dados</text><text x=\"637.5\" y=\"337.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.97.10</text><path d=\"M147.0 328.0 L172.0 328.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><path d=\"M347.0 328.0 L372.0 328.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18-walks-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"368.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">todo endereço e regra de sub-rede permitiu; o grupo que ele carrega, não</text><text x=\"360.0\" y=\"412.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o mesmo pedido de uma máquina com app-sg passaria</text></svg>", "caption": "A network ACL sabe recusar um endereço. Só o security group sabe recusar uma identidade.", "same": ["load balancer"]}
```

Os três percursos são o motivo de ter os dois filtros. A network ACL faz o que só ela sabe fazer,
uma negação para um endereço na borda de uma camada. Os security groups fazem o que só eles sabem
fazer, **confiar por identidade em vez de por endereço**. É isso que mantém o load balancer longe do
banco de dados sejam quais forem os endereços de um e de outro.

## O que não foi executado, e como você conferiria na AWS

**O moto não filtra nada.** Ele guarda toda regra, confere a forma delas e recusa uma repetida. Não
deixa pacote nenhum passar por nenhuma delas, porque não existe pacote. Os três percursos acima são
raciocínio a partir das regras, e a figura é um desenho desse raciocínio, não de uma captura.

Na AWS, duas ferramentas respondem à pergunta de verdade, e nenhuma foi executada aqui:

- **VPC Flow Logs** registram, para cada interface de rede, toda tentativa de conexão com endereços,
  portas e um `ACCEPT` ou `REJECT`. Eles mostram o que aconteceu, depois que aconteceu. São onde se
  olha quando alguém diz "não conecta".
- **VPC Reachability Analyzer** recebe uma origem e um destino, como o load balancer e o banco de
  dados. Ele lê as tabelas de rotas, as network ACLs e os security groups entre eles. Então diz se
  um pacote conseguiria passar e, se não, qual regra o impede. Ele não manda tráfego. Lê a mesma
  configuração que esta seção leu, sem os erros que uma pessoa comete ao lê-la.

O Reachability Analyzer é cobrado por análise, e a linha dele está na mesma oferta da VPC que a
lição 17 leu, de 17 de setembro de 2026:

```
ana@laptop:~/aws$ python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-Analysis-Runs
AmazonVPC 20260917190528, published 2026-09-17, USD
SAE1-Analysis-Runs
          0 to       Inf ReachabilityAnalyses 0.1000
```

**Dez centavos por pergunta.** Perguntar a ele sobre os três percursos acima custaria trinta
centavos.

## A lição como script

Os grupos e a network ACL pública, como um script para as lições 19 e 20 reconstruírem a partir
dele:

```sh
cat > ~/aws/net/18-filters.sh <<'EOF'
# Lesson 18: the shop's filters. Three security groups, each trusting the one
# in front of it, and a network ACL for the public subnets. Run after 17-routes.sh.
vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod \
  --query "Vpcs[0].VpcId" --output text)
group() { aws ec2 create-security-group --vpc-id "$vpc" --group-name "$1" \
  --description "$2" --query GroupId --output text; }
alb=$(group alb-sg "shop load balancer")
app=$(group app-sg "shop application")
db=$(group db-sg "shop database")
aws ec2 authorize-security-group-ingress --group-id "$alb" --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$app" --protocol tcp --port 8080 --source-group "$alb" > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$db" --protocol tcp --port 5432 --source-group "$app" > /dev/null
aws ec2 revoke-security-group-egress --group-id "$db" --protocol all --cidr 0.0.0.0/0 > /dev/null
echo "alb-sg $alb, app-sg $app, db-sg $db"
acl=$(aws ec2 create-network-acl --vpc-id "$vpc" \
  --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=public}]' \
  --query NetworkAcl.NetworkAclId --output text)
rule() { aws ec2 create-network-acl-entry --network-acl-id "$acl" "$@"; }
rule --ingress --rule-number 90 --protocol -1 --cidr-block 198.51.100.7/32 --rule-action deny
rule --ingress --rule-number 100 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
rule --ingress --rule-number 110 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
rule --ingress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
rule --egress --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
rule --egress --rule-number 110 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
rule --egress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
for z in a b c; do
  s=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text)
  old=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values="$s" \
    --query "NetworkAcls[0].Associations[?SubnetId=='$s'].NetworkAclAssociationId" --output text)
  aws ec2 replace-network-acl-association --association-id "$old" --network-acl-id "$acl" > /dev/null
done
echo "network ACL public $acl on public-a, public-b and public-c"
EOF
```

Reinicie o moto e rode os três scripts em ordem para conferir:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null && bash net/18-filters.sh
alb-sg sg-53a72398a75c4e2e7, app-sg sg-19bff292e592ad5d8, db-sg sg-f673dd8488f3156d0
network ACL public acl-9bc6a9407274c43a1 on public-a, public-b and public-c
```
