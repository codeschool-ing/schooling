---
title: "Infracost: o preço de um pull request"
version: 1
---

Quem revisa um diff vê palavras. Aqui está uma mudança de uma palavra no `web.tf`:

```
ana@laptop:~/shop$ git diff
diff --git a/web.tf b/web.tf
index 841b9ea..db6a789 100644
--- a/web.tf
+++ b/web.tf
@@ -1,7 +1,7 @@
 resource "aws_instance" "web" {
   count         = 2
   ami           = "ami-1e749f67"
-  instance_type = "t3.medium"
+  instance_type = "m7i.large"
   subnet_id     = aws_subnet.private_c.id
 
   root_block_device {
```

`t3.medium` para `m7i.large` parece um tamanho, e um tamanho é fácil de aprovar. O plano concorda que é
pouca coisa, dois updates no lugar e nada substituído. Com preço, a leitura muda:

```
ana@laptop:~/shop$ terraform plan -no-color -out tfplan | grep -E "will be updated|instance_type|Plan:"
  # aws_instance.web[0] will be updated in-place
      ~ instance_type                        = "t3.medium" -> "m7i.large"
  # aws_instance.web[1] will be updated in-place
      ~ instance_type                        = "t3.medium" -> "m7i.large"
Plan: 0 to add, 2 to change, 0 to destroy.
ana@laptop:~/shop$ terraform show -json tfplan | python3 price.py
aws_instance.web[0]    update      52.10 ->   120.31
aws_instance.web[1]    update      52.10 ->   120.31
change per month, USD                      +136.44
```

**Uma palavra, 136.44 USD a mais todo mês**, e cada servidor web passa de 52.10 para 120.31. Nada no
diff nem no plano diz isso. A decisão pode até estar certa, a loja pode precisar da memória, mas deve
ser tomada por alguém que viu o número.

## O que o Infracost faz

**O Infracost faz o que o `price.py` faz, para centenas de tipos de recurso, em todo pull request.** Ele
lê um diretório de Terraform ou o JSON de um plano, descobre quais atributos de cada recurso carregam
um preço, pede esses preços a um serviço de preços e imprime um detalhamento por recurso com um total
mensal. O comando `diff` compara duas versões do código, a branch contra a linha principal, e imprime
a mudança no custo; as integrações dele com os sistemas de CI mais comuns publicam essa diferença como
comentário no pull request, ao lado do plano que a aula 15 põe lá.

Três coisas sobre ele valem saber antes de adotá-lo:

- **Ele precisa de um serviço de preços e de uma chave de API.** Os preços não estão no programa; ele
  os consulta no banco de preços do próprio Infracost, pela API, com uma chave que você ganha ao se
  cadastrar.
- **Ele usa preços de tabela da região em que você faz o deploy**, e não sabe nada dos seus descontos,
  assim como a planilha da seção anterior.
- **O uso é você quem informa.** Para o que um plano não sabe, gigabytes transferidos ou requisições
  atendidas, ele lê um arquivo de uso em que você escreve suas próprias estimativas. Sem ele, essas
  linhas mostram um preço por unidade e nenhum valor mensal, em vez de um chute.

## Não executado aqui

**O Infracost não foi executado para esta aula, e não há saída do Infracost nesta página.** Ele precisa
do serviço de preços, e o laboratório não tem rede; um detalhamento inventado seria justamente a coisa
que este curso promete nunca imprimir. Os comandos abaixo são o que um pipeline rodaria, escritos como
referência e não executados:

```sh
# Not run in this lab: Infracost needs an API key and its pricing service.
export INFRACOST_API_KEY=...   # from your Infracost account

# on the main branch: the baseline
infracost breakdown --path . --format json --out-file infracost-base.json

# on the pull request's branch: the difference
infracost diff --path . --compare-to infracost-base.json
```

## O que continua igual

Trocar a ferramenta não troca o método. **O plano é a entrada, o preço é de tabela, e o uso é um palpite
que alguém anotou.** O que o Infracost acrescenta é cobertura, um banco de preços atuais em vez de uma
planilha fixada e um lugar na revisão que ninguém precisa lembrar de abrir. O que ele não consegue
acrescentar é nada que o plano não contenha, e é por isso que o resto desta aula trata do dinheiro que
nunca aparece num plano.
