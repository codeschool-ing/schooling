---
title: O app, parte por parte
version: 1
---

Crie um diretório para o app, `mkdir -p ~/revenue/.streamlit`, e três arquivos nele. O primeiro é o
programa. Copie com o botão no código, que copia o programa inteiro sem as notas, e salve como
`~/revenue/app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py: Lantern's net revenue by month, read from the semantic layer.\nimport psycopg\nimport streamlit as st", "note": "Duas bibliotecas: `psycopg` conversa com o PostgreSQL, `streamlit` desenha a página. Não precisa de mais nada."}, {"code": "st.set_page_config(page_title=\"Lantern revenue\")\nst.title(\"Lantern Coffee: net revenue\")", "note": "O Streamlit roda o arquivo de cima para baixo, e cada chamada `st.` põe um elemento na página, nessa ordem."}, {"code": "@st.cache_data(ttl=600)\ndef monthly(segments):\n    sql = \"\"\"\n        SELECT date_trunc('month', o.order_date)::date AS month,\n               sum(o.net_revenue)::float AS net_revenue\n        FROM semantic.orders o\n        JOIN semantic.customers c USING (customer_id)\n        WHERE c.segment = ANY(%s)\n        GROUP BY 1\n        ORDER BY 1\n    \"\"\"", "note": "A consulta lê a camada, nunca `shop`. `%s` é um parâmetro: os segmentos vão ao lado do SQL, e não colados nele. O `@st.cache_data` guarda a resposta por dez minutos para cada combinação de segmentos, então mexer num controle não consulta o banco a cada vez."}, {"code": "    with psycopg.connect(**st.secrets[\"db\"]) as conn:\n        rows = conn.execute(sql, (list(segments),)).fetchall()\n    return {\"month\": [r[0] for r in rows], \"net_revenue\": [r[1] for r in rows]}", "note": "Os dados de conexão vêm de `st.secrets`, que o Streamlit lê de um arquivo que não faz parte do programa. O resultado vira duas listas, o formato que o gráfico aceita."}, {"code": "segments = st.multiselect(\"Segment\", [\"home\", \"office\"], default=[\"home\", \"office\"])\ndata = monthly(tuple(segments))", "note": "Um controle é uma variável. O que o leitor seleciona está em `segments` na execução seguinte, e toda interação roda o arquivo de novo desde o topo."}, {"code": "st.metric(\"Net revenue, whole period\", f\"R$ {sum(data['net_revenue']):,.2f}\")\nst.bar_chart(data, x=\"month\", y=\"net_revenue\")\nst.caption(\"June 2026 holds 17 days. Source: semantic.orders.\")", "note": "Um número, um gráfico e uma legenda. A legenda não é enfeite: é o mês parcial da aula 1, escrito onde o leitor o vê."}]}
```

O segundo guarda o que o programa não pode conter: a senha. Salve como
`~/revenue/.streamlit/secrets.toml`, com a senha que você deu ao papel:

```toml
[db]
host = "localhost"
dbname = "lantern"
user = "streamlit_app"
password = "a-third-password-to-choose"
```

**Um arquivo de segredos nunca vai para o controle de versão.** Ele é um arquivo separado justamente
para o programa poder ser compartilhado, revisado e publicado sem a senha dentro; um time que guarda os
apps no git põe esse arquivo no `.gitignore` no primeiro dia.

O terceiro é a configuração do próprio Streamlit, salva como `~/revenue/.streamlit/config.toml`:

```toml
[browser]
gatherUsageStats = false

[server]
address = "0.0.0.0"
headless = true
```

`gatherUsageStats = false` impede o Streamlit de mandar estatísticas anônimas de uso para a empresa
dele, o que ele faz por padrão. `address = "0.0.0.0"` o faz escutar em toda interface de rede da
máquina, para que a porta 8501 encaminhada na aula 1 chegue até ele; `headless = true` o impede de
tentar abrir um navegador num servidor que não tem nenhum. Os três arquivos:

```
ana@vm:~/revenue$ find . -type f | sort
./.streamlit/config.toml
./.streamlit/secrets.toml
./app.py
```

Rode a partir desse diretório, com o `streamlit` do próprio ambiente:

```sh
cd ~/revenue
~/st/bin/streamlit run app.py
```

Ele imprime os endereços em que está escutando e continua rodando nesse terminal até um Ctrl+C. De um
segundo terminal, a máquina pode perguntar se ele está de pé:

```
ana@vm:~$ curl -s -w '\n' http://localhost:8501/_stcore/health
ok
```

Abra `http://localhost:8501` no seu navegador (no UTM, o endereço da máquina). Um título, um seletor
de segmento com os dois segmentos escolhidos, um número, um gráfico de barras por mês e a legenda. O
número diz:

```
Segment: home, office
Net revenue, whole period: R$ 1,046,756.40
```

Os mesmos R$ 1.046.756,40 que a camada guarda, por um terceiro caminho. Tire *home* do seletor e o
arquivo inteiro roda de novo só com `office` em `segments`:

```
Segment: office
Net revenue, whole period: R$ 355,821.05
```

R$ 355.821,05, o número a que o Metabase chegou por segmento antes nesta aula. **Três ferramentas, um
número**, porque as três leem a mesma coluna da mesma view. É a aula 3 se pagando.
