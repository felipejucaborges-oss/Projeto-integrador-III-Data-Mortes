# PI III — Motor de Busca (Baixada Santista)
**Documentação Consolidada e Código Completo do Sistema**

---

## Sumário
1. [Preparação Comum: Configuração e Pré-processamento](#1-preparação-comum-configuração-e-pré-processamento)
2. [Aula 01 & 02: Vocabulário, TDM e TF-IDF](#2-aula-01--02-vocabulário-tdm-e-tf-idf)
3. [Aula 03: Índice Invertido e Buscas Booleanas](#3-aula-03-índice-invertido-e-buscas-booleanas)
4. [Aula 04: Modelo Probabilístico BM25](#4-aula-04-modelo-probabilístico-bm25)
5. [Aula 05 & 05.5: Julgamentos (qrels) e Métricas de Avaliação](#5-aula-05--055-julgamentos-qrels-e-métricas-de-avaliação)
6. [Aula 06: Feedback de Relevância (Rocchio)](#6-aula-06-feedback-de-relevância-rocchio)
7. [Aula 07: LSA (SVD), Busca Híbrida (RRF) e Avaliação Comparativa](#7-aula-07-lsa-svd-busca-híbrida-rrf-e-avaliação-comparativa)
8. [Consolidação e Finalização: config.R e Ficha do Projeto](#8-consolidação-e-finalização-configr-e-ficha-do-projeto)

---

## 1. Preparação Comum: Configuração e Pré-processamento

```r
# --- Instalação e carregamento de dependências ---
if (!requireNamespace("SnowballC", quietly = TRUE)) install.packages("SnowballC")
if (!requireNamespace("httr2", quietly = TRUE)) install.packages("httr2")

library(SnowballC)
library(httr2)

# --- Stopwords em Português ---
stopwords <- c(
  "a", "à", "ao", "aos", "as", "às", "até", "com", "como", "da", "das", "de",
  "do", "dos", "e", "é", "em", "entre", "era", "eram", "essa", "essas", "esse",
  "esses", "esta", "estas", "este", "estes", "foi", "foram", "há", "isso", "isto",
  "já", "mas", "mais", "me", "mesmo", "na", "nas", "nem", "no", "nos", "não",
  "o", "os", "ou", "para", "pela", "pelas", "pelo", "pelos", "por", "qual",
  "quando", "que", "quem", "se", "sem", "ser", "seu", "seus", "sua", "suas",
  "também", "tem", "têm", "um", "uma", "umas", "uns", "vai", "vão"
)

# --- Função de Tokenização, Limpeza e Stemming ---
tokenizar_limpar <- function(texto) {
  texto <- tolower(texto)
  texto <- gsub("[0-9]+", " ", texto)
  texto <- gsub("[[:punct:]]+", " ", texto)

  tokens <- unlist(strsplit(texto, "\\s+"))
  tokens <- tokens[tokens != ""]
  tokens <- tokens[!tokens %in% stopwords]
  tokens <- tokens[nchar(tokens) > 2]
  tokens <- wordStem(tokens, language = "portuguese")
  return(tokens)
}

# --- Função de Similaridade de Cosseno ---
similaridade_cosseno <- function(v1, v2) {
  v1[is.nan(v1)] <- 0
  v2[is.nan(v2)] <- 0
  produto_escalar <- sum(v1 * v2)
  norma_v1 <- sqrt(sum(v1^2))
  norma_v2 <- sqrt(sum(v2^2))
  if (is.nan(norma_v1) || is.nan(norma_v2) || norma_v1 == 0 || norma_v2 == 0) {
    return(0)
  }
  return(produto_escalar / (norma_v1 * norma_v2))
}

cosseno <- similaridade_cosseno
```

---

## 2. Aula 01 & 02: Vocabulário, TDM e TF-IDF

```r
# --- Download do Corpus da Wikipédia ---
baixar_wiki <- function(titulo) {
  resposta <- request("https://pt.wikipedia.org/w/api.php") |>
    req_url_query(
      action = "query",
      prop = "extracts",
      explaintext = 1,
      format = "json",
      redirects = 1,
      titles = titulo
    ) |>
    req_perform() |>
    resp_body_json()

  pagina <- resposta$query$pages[[1]]
  if (is.null(pagina$extract)) {
    stop(paste("Não foi possível encontrar o artigo:", titulo))
  }
  return(pagina$extract)
}

municipios <- c(
  santos = "Bolsa do Café",
  praia_grande = "Fortaleza de Itaipu",
  sao_vicente = "São Vicente (São Paulo)"
)

docs <- sapply(municipios, baixar_wiki)
tokens <- lapply(docs, tokenizar_limpar)

# --- Salvamento do arquivo corpus.csv padrão ---
titulo_limpo <- gsub(" ", "_", municipios)
urls <- paste0("https://pt.wikipedia.org/wiki/", titulo_limpo)

cp_bruto <- data.frame(
  id = names(docs),
  titulo = municipios,
  texto = docs,
  fonte = "Wikipedia pt",
  url = urls,
  stringsAsFactors = FALSE
)

write.csv(cp_bruto, "corpus.csv", row.names = FALSE, fileEncoding = "UTF-8")

# --- Geração do Vocabulário e TDM ---
vocab <- sort(unique(unlist(tokens)))
tdm <- sapply(tokens, function(tk) {
  as.integer(table(factor(tk, levels = vocab)))
})
rownames(tdm) <- vocab

# --- Geração da Matriz TF-IDF ---
N <- ncol(tdm)
dl <- colSums(tdm)       # Tamanho dos documentos
avgdl <- mean(dl)        # Tamanho médio dos documentos
documentos_com_termo <- rowSums(tdm > 0)

idf <- log(N / documentos_com_termo)
tf <- sweep(tdm, 2, dl, "/")
tfidf <- tf * idf

cat("Dimensões da Matriz TF-IDF:", nrow(tfidf), "termos x", ncol(tfidf), "documentos.\n")
```

---

## 3. Aula 03: Índice Invertido e Buscas Booleanas

```r
# --- Construção do Índice Invertido ---
postings <- list()
for (d in names(docs)) {
  for (termo in unique(tokens[[d]])) {
    postings[[termo]] <- c(postings[[termo]], d)
  }
}

# --- Funções de Busca Booleana ---
busca_AND <- function(consulta) {
  termos <- tokenizar_limpar(consulta)
  termos <- termos[termos %in% names(postings)]
  if (length(termos) == 0) return(character(0))
  Reduce(intersect, postings[termos])
}

busca_OR <- function(consulta) {
  termos <- tokenizar_limpar(consulta)
  termos <- termos[termos %in% names(postings)]
  if (length(termos) == 0) return(character(0))
  Reduce(union, postings[termos])
}

cat("Índice Invertido construído com", length(postings), "termos mapeados.\n")
```

---

## 4. Aula 04: Modelo Probabilístico BM25

```r
# --- IDF Probabilístico do BM25 ---
idf_bm25 <- log((N - documentos_com_termo + 0.5) / (documentos_com_termo + 0.5) + 1)

# --- Função de Ranqueamento BM25 ---
ranking_bm25 <- function(consulta, tdm_local) {
  termos <- tokenizar_limpar(consulta)
  scores <- sapply(colnames(tdm_local), function(d) {
    s_bm <- 0
    for (t in termos) {
      if (!(t %in% vocab)) next
      f <- tdm_local[t, d]
      K <- 1.2 * (1 - 0.75 + 0.75 * dl[d] / avgdl) # k1 = 1.2, b = 0.75
      s_bm <- s_bm + idf_bm25[t] * (f * (1.2 + 1)) / (f + K)
    }
    return(s_bm)
  })
  sort(scores, decreasing = TRUE)
}

cat("Função de ranqueamento BM25 definida com k1 = 1.2 e b = 0.75.\n")
```

---

## 5. Aula 05 & 05.5: Julgamentos (qrels) e Métricas de Avaliação

```r
# --- Carregamento de Necessidades de Busca e qrels ---
necessidades_texto <- "consulta,texto_consulta,necessidade,escopo,conjunto
q01,café museu santos,Quero saber o que funcionava no prédio da Bolsa do Café em Santos e o que existe lá hoje.,\"Não conta texto sobre o cultivo ou o preparo do café, nem sobre museus de outras cidades.\",dev
q02,forte artilharia canhões,Quero saber como era a defesa militar da Fortaleza de Itaipu: que armamento tinha e como estava organizada.,Não conta história geral de Praia Grande nem outras fortificações citadas só de passagem.,dev
q03,primeira vila fundada no Brasil,Quero saber quando e por quem a ilha de São Vicente foi descoberta e como a vila se tornou a primeira da América Portuguesa.,\"Não conta a história posterior da cidade (economia, população, política atual).\",dev
q04,onde se negociava o café antigamente,\"Quero saber como e por que foi criada a Bolsa do Café de Santos, e onde ela se localizava, para entender como o comércio de café era organized.\",Não conta descrição do museu atual sem relação com a atividade de negociação.,teste
q05,proteger a costa contra invasores,Quero saber por que a Fortaleza de Itaipu foi construída e de que ameaças ela protegia o litoral.,Não conta o estado de conservação ou o uso turístico atual.,teste"

con <- textConnection(necessidades_texto)
df_necessidades <- read.csv(con, stringsAsFactors = FALSE)
close(con)
write.csv(df_necessidades, "necessidades.csv", row.names = FALSE, fileEncoding = "UTF-8")

consultas <- setNames(df_necessidades$texto_consulta, df_necessidades$consulta)

# Carregamento/Simulação do gabarito (qrels)
df_qrels <- read.csv("qrels_simulado.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
qrels <- split(setNames(df_qrels$grau, df_qrels$documento), df_qrels$consulta)

limiar_grupo <- 2
R_q <- sapply(qrels, function(g) sum(g >= limiar_grupo))
usar <- names(qrels)[R_q > 0]

# --- Implementação das Métricas de Avaliação ---
precisao_k <- function(rel, k = 3) {
  if (length(rel) < k) k <- length(rel)
  if (k == 0) return(0)
  sum(rel[1:k]) / k
}

ap <- function(rel, R) {
  if (R == 0) return(NA)
  p <- cumsum(rel) / seq_along(rel)
  sum(p[rel == 1]) / R
}

rr <- function(rel) {
  if (sum(rel) == 0) return(0)
  1 / which(rel == 1)[1]
}

dcg <- function(g) {
  sum(g / log2(seq_along(g) + 1))
}

ndcg <- function(g) {
  ideal <- sort(g, decreasing = TRUE)
  if (dcg(ideal) == 0) return(NA)
  dcg(g) / dcg(ideal)
}

metricas <- function(ranking, grau, limiar, k = 3) {
  g <- grau[names(ranking)]
  g[is.na(g)] <- 0
  rel <- as.integer(g >= limiar)
  R   <- sum(grau >= limiar)

  c(P_at_k   = precisao_k(rel, k),
    AP       = ap(rel, R),
    RR       = rr(rel),
    nDCG_bin = ndcg(rel),
    nDCG_grad= ndcg(g))
}
```

---

## 6. Aula 06: Feedback de Relevância (Rocchio)

```r
# --- Algoritmo de Rocchio ---
rocchio <- function(q, Dr, Dnr = character(0), ix, a = 1, b = 0.75, g = 0.15) {
  cr  <- rowMeans(ix$tfidf[, Dr, drop = FALSE])
  cnr <- if (length(Dnr)) rowMeans(ix$tfidf[, Dnr, drop = FALSE]) else 0
  a * q + b * cr - g * cnr
}

ranking_vetor <- function(q, ix) {
  scores <- sapply(colnames(ix$tfidf), function(d) similaridade_cosseno(q, ix$tfidf[, d]))
  sort(scores, decreasing = TRUE)
}

# --- Estrutura de Índice Agrupado ---
ix <- list(
  postings = postings,
  dl = dl,
  avgdl = avgdl,
  vocab = vocab,
  tdm = tdm,
  tfidf = tfidf
)
```

---

## 7. Aula 07: LSA (SVD), Busca Híbrida (RRF) e Avaliação Comparativa

```r
# --- SVD Aplicado à Matriz TF-IDF (LSA) ---
w <- tfidf
N_docs <- ncol(w)
s <- svd(w)

# --- Função de Ranqueamento LSA ---
ranking_lsa <- function(texto, k) {
  D <- s$v[, 1:k, drop = FALSE] %*% diag(s$d[1:k], k)
  rownames(D) <- colnames(w)

  termos_w <- rownames(w)
  q0 <- as.integer(table(factor(tokenizar_limpar(texto), levels = termos_w))) * idf[termos_w]
  q0[is.na(q0)] <- 0

  qk <- t(s$u[, 1:k, drop = FALSE]) %*% q0
  scores <- apply(D, 1, function(d) cosseno(as.vector(qk), d))
  sort(scores, decreasing = TRUE)
}

# --- Reciprocal Rank Fusion (RRF) ---
rrf <- function(..., c = 60) {
  rs <- list(...)
  ids <- unique(unlist(lapply(rs, names)))
  s_scores <- sapply(ids, function(d) {
    sum(sapply(rs, function(r) {
      p <- which(names(r) == d)
      if (length(p)) 1 / (c + p) else 0
    }))
  })
  sort(s_scores, decreasing = TRUE)
}

# --- Ranqueamento Cosseno ---
ranking_cosseno <- function(consulta, indice, config) {
  termos <- tokenizar_limpar(consulta)
  vetor_q <- setNames(rep(0, length(indice$vocab)), indice$vocab)
  freq_q <- table(termos)
  for (t in names(freq_q)) {
    if (t %in% names(vetor_q)) {
      vetor_q[t] <- as.numeric(freq_q[t]) * idf[t]
    }
  }

  scores <- sapply(colnames(indice$tfidf), function(d) {
    similaridade_cosseno(vetor_q, indice$tfidf[, d])
  })
  sort(scores, decreasing = TRUE)
}

# --- Avaliação Comparativa em Lote ---
k_lsa_aval <- min(2, N_docs)

tab_cos <- sapply(usar, function(q) {
  txt <- consultas[[q]]
  rk  <- ranking_cosseno(txt, ix, cfg)
  metricas(rk, qrels[[q]], limiar_grupo, k = 3)
})

tab_lsa <- sapply(usar, function(q) {
  txt <- consultas[[q]]
  rk  <- ranking_lsa(txt, k = k_lsa_aval)
  metricas(rk, qrels[[q]], limiar_grupo, k = 3)
})

tab_hib_alt <- sapply(usar, function(q) {
  txt <- consultas[[q]]
  rk_cos <- ranking_cosseno(txt, ix, cfg)
  rk_lsa <- ranking_lsa(txt, k = k_lsa_aval)
  rk_h   <- rrf(rk_cos, rk_lsa)
  metricas(rk_h, qrels[[q]], limiar_grupo, k = 3)
})

resumo_final_alt <- rbind(
  Cosseno     = rowMeans(tab_cos, na.rm = TRUE),
  LSA         = rowMeans(tab_lsa, na.rm = TRUE),
  Hibrido_Alt = rowMeans(tab_hib_alt, na.rm = TRUE)
)

cat("============================================\n")
cat("   MÉDIAS GLOBAIS (COSSENO + LSA + HÍBRIDO)\n")
cat("============================================\n")
print(round(resumo_final_alt, 3))
```

---

## 8. Consolidação e Finalização: config.R e Ficha do Projeto

```r
# --- Atualização do Ficheiro config.R ---
config_conteudo <- paste0(
  "# ==========================================================\n",
  "# CONFIGURAÇÕES E HIPERPARÂMETROS OFICIAIS DO MOTOR DE BUSCA\n",
  "# Projeto Integrador III - Baixada Santista\n",
  "# ==========================================================\n\n",
  "cfg <- list(\n",
  "  # --- Hiperparâmetros do BM25 ---\n",
  "  k1 = 1.2,\n",
  "  b  = 0.75,\n\n",
  "  # --- Hiperparâmetros do LSA (SVD) ---\n",
  "  k_lsa = 2,\n\n",
  "  # --- Hiperparâmetros da Busca Híbrida (RRF) ---\n",
  "  rrf_c = 60,\n\n",
  "  # --- Hiperparâmetros do Feedback de Relevância (Rocchio) ---\n",
  "  prf_k = 0,\n",
  "  rocchio = c(a = 1.0, b = 0.75, g = 0.15),\n\n",
  "  # --- Configurações da Avaliação ---\n",
  "  limiar_relevancia = 2,\n",
  "  k_eval = 3\n",
  ")\n\n",
  "cat(\"Ficheiro 'config.R' validado e carregado com sucesso!\\n\")\n"
)

writeLines(config_conteudo, "config.R")
source("config.R")

# --- Atualização do Ficheiro 00_FICHA_PROJETO.md ---
ficha_conteudo <- "# Ficha do Projeto: Motor de Busca — Baixada Santista (PI III)

## 1. Identificação do Grupo e Projeto
* **Projeto:** Motor de Busca para o Corpus da Baixada Santista (Wikipédia)
* **Repositório GitHub:** `enzoura07/TEA-DataMortes` (Módulo PI3)
* **Integrantes:** Enzo Shinji Sugano Ura, Felipe Juca Gozza Borges, Victor Ferreira Santos
* **Ambiente de Execução:** R / Google Colab (Kernel IR)

---

## 2. Hiperparâmetros Oficiais do Motor de Busca

| Módulo / Modelo | Hiperparâmetro | Valor Escolhido | Descrição / Justificativa |
| :--- | :--- | :--- | :--- |
| **BM25** | `k1` | **1.2** | Saturação da frequência dos termos |
| **BM25** | `b` | **0.75** | Penalização pelo tamanho do documento |
| **LSA (SVD)** | `k` | **2** | Dimensões/tópicos latentes retidos |
| **RRF (Híbrido)**| `c` | **60** | Constante de suavização do Reciprocal Rank Fusion |
| **Avaliação** | `limiar_grupo` | **2** | Limiar para binarização de relevância nos qrels |
| **Avaliação** | `k` | **3** | Profundidade de corte nas métricas Top-K |
| **Rocchio** | `a` (alpha) | **1.0** | Peso da consulta original |
| **Rocchio** | `b` (beta) | **0.75** | Peso do centroide de documentos relevantes |
| **Rocchio** | `g` (gamma) | **0.15** | Peso do centroide de documentos não relevantes |

---

## 3. Resumo da Avaliação Comparativa de Desempenho

| Modelo | P@3 | AP (MAP) | RR (MRR) | nDCG (Binário) | nDCG (Graduado) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Cosseno (TF-IDF)** | 0.444 | 0.611 | 0.611 | 0.710 | 0.797 |
| **LSA (Semântico)** | 0.444 | **0.778** | **0.833** | **0.850** | **0.942** |
| **Híbrido (RRF: Cos + LSA)** | 0.444 | 0.611 | 0.611 | 0.710 | 0.797 |
"

writeLines(ficha_conteudo, "00_FICHA_PROJETO.md")

cat("Documentação consolidada com sucesso!\n")
```