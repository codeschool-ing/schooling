---
title: Dois cofres, e para que serve cada um
version: 1
---

Um programa precisa de valores que não deveria carregar: uma senha de banco, uma chave de API do
provedor de pagamento, o próprio endereço do banco. Escritos no código, eles estão em toda cópia do
repositório, toda imagem de contêiner e todo laptop que já o clonou, e mudar um deles vira um release.
**Eles pertencem a um lugar fora do código, um cofre que o programa consulta em tempo de execução**, e a
AWS tem dois cofres assim, que se sobrepõem mais do que os nomes sugerem.

O **Parameter Store**, parte do Systems Manager, guarda valores com nome numa hierarquia,
`/shop/prod/db/host`, de três tipos: `String`, `StringList` e `SecureString`, que é criptografado com uma
chave do KMS. Parâmetros standard são grátis, até 10.000 deles e 4 KB cada. Parâmetros advanced guardam
até 8 KB, aceitam políticas de expiração e custam uma mensalidade cada.

O **Secrets Manager** guarda **segredos**: valores criptografados, geralmente um pequeno documento JSON,
com **versões rotuladas por estágio** e um jeito pronto de **rotacioná-los**, rodar uma função que muda a
senha no banco e no segredo ao mesmo tempo. Ele gera senhas, replica um segredo para outras regiões e
aceita uma política de recurso dizendo quem pode lê-lo. Todo segredo custa uma mensalidade, e as chamadas
também.

| | Parameter Store, standard | Secrets Manager |
|---|---|---|
| guarda | strings, listas, strings criptografadas, 4 KB | valores criptografados, 64 KB |
| versões | numeradas, com rótulos | numeradas, com estágios `AWSCURRENT`, `AWSPREVIOUS`, `AWSPENDING` |
| rotação | nenhuma pronta | uma função num agendamento, ou gerenciada pelo RDS |
| preço | grátis | uma taxa por segredo e por 10.000 chamadas |

## Os preços, da lista

```
ana@laptop:~/aws$ python3 price.py AWSSecretsManager
AWSSecretsManager, sa-east-1, published 2026-09-11
  SAE1-AWSSecretsManager-Secrets           0.400000 USD per Secrets    $0.40 per Secret
  SAE1-AWSSecretsManagerAPIRequest         0.000005 USD per API Requests $0.05 per 10000 API Requests
ana@laptop:~/aws$ python3 price.py AWSSystemsManager Parameter
AWSSystemsManager, sa-east-1, published 2026-10-08
  SAE1-PS-Advanced-Param-Tier1             0.000070 USD per Hour       $0.05 per Advanced Parameter per Month in South America (Sao Paulo)
  SAE1-PS-Param-Processed-Tier1            0.000005 USD per API Request $0.05 per 10,000 Advanced Parameter API interaction_Standard throughput in South America (Sao Paulo)
  SAE1-PS-Param-Processed-Tier2            0.000005 USD per API Request $0.05 per 10,000 Parameter API Interaction_Higher throughput in South America (Sao Paulo)
```

**40 centavos por mês por segredo, e 5 centavos por 10.000 chamadas.** O Parameter Store não imprime linha
para um parâmetro standard porque ele não tem; as linhas que imprime são do nível advanced, 5 centavos por
mês por parâmetro (o programa mostra o valor por hora), e da configuração de vazão maior, que cobra 5
centavos por 10.000 chamadas de todo parâmetro depois de ligada. Um valor criptografado, em qualquer dos
dois cofres, também custa as chamadas ao KMS que o decifram, que a lição 18 calcula.

Então os seis segredos da loja custam 2,40 USD por mês para guardar. O que custam para ler depende
inteiramente de quantas vezes o código pergunta, e a seção sobre leitura é sobre esse número.

## Qual dos dois

Uma regra que funciona na prática: **configuração vai no Parameter Store, e credenciais que devem mudar
vão no Secrets Manager.** Uma senha de banco, que a rotação pode mudar a cada trinta dias sem ninguém
encostar, vale 40 centavos por mês. Uma flag de funcionalidade ou um nome de host não são segredo, e uma
`SecureString` guardando uma chave de API que ninguém vai rotacionar é um bom uso do nível grátis. A única
resposta errada é o código.
