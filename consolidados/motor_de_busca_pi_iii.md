# PI III — Motor de Busca (Baixada Santista)

## Sumário

- [Preparação comum (pré-processamento)](#preparacao-comum)
- [Aula 01 — Do problema da busca ao nosso motor](#aula-01)
- [Aula 02 — Vetores, TF-IDF e similaridade do cosseno](#aula-02)
- [Aula 03 — Pré-processamento e índice invertido](#aula-03)
- [Aula 04 — Modelo probabilístico BM25](#aula-04)
- [Extras / Análise por Frases](#extras)

---

## Preparação comum (pré-processamento) <a id="preparacao-comum"></a>

Esta seção reúne as etapas iniciais de download e tratamento de texto comuns a todas as aulas.

### 1. Configuração e download dos artigos da Wikipédia

```R
library(httr2)

baixar_wiki <- function(titulo) {
  resposta <- request(
    "https://pt.wikipedia.org/w/api.php"
  ) |>
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
    stop(
      paste(
        "Não foi possível encontrar o artigo:",
        titulo
      )
    )
  }

  return(pagina$extract)
}

municipios <- c(
  santos = "Bolsa do Café",
  praia_grande = "Fortaleza de Itaipu",
  sao_vicente = "São Vicente (São Paulo)"
)

docs <- sapply(
  municipios,
  baixar_wiki
)

cat("============================================\n")
cat("       TAMANHO DOS ARTIGOS\n")
cat("============================================\n\n")
for (i in seq_along(docs)) {
  cat(
    "-",
    names(docs)[i],
    ":",
    nchar(docs[[i]]),
    "caracteres\n"
  )
}
```

### 2. Tokenização, limpeza, remoção de stopwords e stemming

```R
install.packages("SnowballC")  # só na primeira vez na sessão
library(SnowballC)

stopwords <- c(
  "a", "à", "ao", "aos", "as",
  "às", "até",
  "com", "como",
  "da", "das", "de", "do", "dos",
  "e", "é", "em", "entre",
  "era", "eram",
  "essa", "essas", "esse", "esses",
  "esta", "estas", "este", "estes",
  "foi", "foram",
  "há",
  "isso", "isto",
  "já",
  "mas",
  "mais",
  "me", "mesmo",
  "na", "nas", "nem", "no", "nos",
  "não",
  "o", "os",
  "ou",
  "para", "pela", "pelas", "pelo", "pelos",
  "por",
  "qual", "quando", "que", "quem",
  "se", "sem", "ser",
  "seu", "seus",
  "sua", "suas",
  "também",
  "tem", "têm",
  "um", "uma", "umas", "uns",
  "vai", "vão"
)

tokenizar_limpar <- function(texto) {
  texto <- tolower(texto)
  texto <- gsub("[0-9]+", " ", texto)
  texto <- gsub("[[:punct:]]+", " ", texto)

  tokens <- unlist(strsplit(texto, "\\s+"))
  tokens <- tokens[tokens != ""]
  tokens <- tokens[!tokens %in% stopwords]
  tokens <- tokens[nchar(tokens) > 2]

  # stemming: reduz variações da mesma palavra a um radical comum
  tokens <- wordStem(tokens, language = "portuguese")

  return(tokens)
}

tokens <- lapply(docs, tokenizar_limpar)

cat("\n============================================\n")
cat("       APÓS A LIMPEZA (com stemming)\n")
cat("============================================\n\n")
for (i in seq_along(tokens)) {
  cat("-", names(tokens)[i], ":", length(tokens[[i]]), "tokens\n")
}
```

---

## Aula 01 — Do problema da busca ao nosso motor <a id="aula-01"></a>

### 3. Vocabulário e frequência de termos

```R
vocab <- sort(unique(unlist(tokens)))

cat("\n============================================\n")
cat("             VOCABULÁRIO\n")
cat("============================================\n\n")
cat("Quantidade de termos diferentes:", length(vocab), "\n")

freq <- table(unlist(tokens))
top10 <- head(sort(freq, decreasing = TRUE), 10)

cat("\n============================================\n")
cat("       10 TERMOS MAIS FREQUENTES\n")
cat("============================================\n\n")
for (i in seq_along(top10)) {
  cat(i, "º -", names(top10)[i], ":", as.integer(top10[i]), "ocorrências\n")
}
```

### 4. Matriz termo-documento (TDM)

```R
tdm <- sapply(
  tokens,
  function(tk) {
    as.integer(table(factor(tk, levels = vocab)))
  }
)
rownames(tdm) <- vocab

cat("\n============================================\n")
cat("       MATRIZ TERMO-DOCUMENTO\n")
cat("============================================\n\n")
cat("Número de termos:", nrow(tdm), "\n")
cat("Número de documentos:", ncol(tdm), "\n")
cat("Dimensão:", nrow(tdm), "x", ncol(tdm), "\n")
cat("\nPrimeiros 10 termos:\n\n")
print(tdm[1:min(10, nrow(tdm)), ])
```

### 5. Busca booleana original

```R
busca_booleana <- function(termo, tdm) {
  termo <- tolower(termo)
  if (!termo %in% rownames(tdm)) {
    return(character(0))
  }
  colnames(tdm)[tdm[termo, ] > 0]
}

cat("\n============================================\n")
cat("       BUSCA BOOLEANA (versão original)\n")
cat("============================================\n\n")

termo_pesquisado <- wordStem("porto", language = "portuguese")  # precisa bater com o radical indexado

cat("Termo pesquisado (radical):", termo_pesquisado, "\n\n")

documentos_encontrados <- busca_booleana(termo_pesquisado, tdm)

if (length(documentos_encontrados) == 0) {
  cat("O termo não foi encontrado.\n")
} else {
  cat("O termo aparece nos documentos:\n")
  for (documento in documentos_encontrados) {
    cat("-", documento, "\n")
  }
}
```

---

## Aula 02 — Vetores, TF-IDF e similaridade do cosseno <a id="aula-02"></a>

### Conteúdo da Aula 02
- (1) Matriz TF-IDF
- (2) Função de similaridade do cosseno
- (3) Ranqueamento de consultas

### 6. Cálculo do TF-IDF

```R
N <- ncol(tdm)
total_termos <- colSums(tdm)
tf <- sweep(tdm, 2, total_termos, "/")
documentos_com_termo <- rowSums(tdm > 0)
idf <- log(N / documentos_com_termo)
tfidf <- tf * idf

cat("\n============================================\n")
cat("                 TF-IDF\n")
cat("============================================\n\n")
cat("Número de termos:", nrow(tfidf), "\n")
cat("Número de documentos:", ncol(tfidf), "\n")

for (documento in colnames(tfidf)) {
  cat("\n--------------------------------------------\n")
  cat("Termos mais importantes para:", documento, "\n")
  cat("--------------------------------------------\n\n")
  valores <- tfidf[, documento]
  valores <- valores[valores > 0]
  top <- head(sort(valores, decreasing = TRUE), 10)
  for (i in seq_along(top)) {
    cat(i, "º -", names(top)[i], ":", round(top[i], 4), "\n")
  }
}
```

### 7. Similaridade de cosseno entre documentos

```R
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

similaridade <- matrix(0, nrow = ncol(tfidf), ncol = ncol(tfidf))
rownames(similaridade) <- colnames(tfidf)
colnames(similaridade) <- colnames(tfidf)

for (i in 1:ncol(tfidf)) {
  for (j in 1:ncol(tfidf)) {
    similaridade[i, j] <- similaridade_cosseno(tfidf[, i], tfidf[, j])
  }
}

cat("\n============================================\n")
cat("       SIMILARIDADE DE COSSENO\n")
cat("============================================\n\n")
print(round(similaridade, 4))
```

---

## Aula 03 — Pré-processamento e índice invertido <a id="aula-03"></a>

### Conteúdo da Aula 03
- (1) Índice invertido (Postings list)
- (2) Stemming integrado (SnowballC::wordStem)
- (3) Algoritmos de busca booleana AND e OR comparados

### 8. Índice invertido (postings)

```R
postings <- list()

for (d in names(docs)) {                                  # 1) para cada documento...
  for (termo in unique(tokenizar_limpar(docs[[d]]))) {     # 2) cada termo distinto...
    postings[[termo]] <- c(postings[[termo]], d)           # 3) anexa o documento à lista do termo
  }
}

cat("\n============================================\n")
cat("       ÍNDICE INVERTIDO (POSTINGS)\n")
cat("============================================\n\n")
cat("Termos indexados:", length(postings), "\n\n")

cat("Termos com mais documentos associados:\n")
print(sort(lengths(postings), decreasing = TRUE)[1:5])
```

### 9. Operadores booleanos: busca_AND e busca_OR

```R
busca_AND <- function(consulta) {
  termos <- tokenizar_limpar(consulta)
  termos <- termos[termos %in% names(postings)]
  if (length(termos) == 0) {
    return(character(0))
  }
  Reduce(intersect, postings[termos])
}

busca_OR <- function(consulta) {
  termos <- tokenizar_limpar(consulta)
  termos <- termos[termos %in% names(postings)]
  if (length(termos) == 0) {
    return(character(0))
  }
  Reduce(union, postings[termos])
}

mostrar_resultado <- function(titulo, docs_encontrados) {
  cat("\n--------------------------------------------\n")
  cat(titulo, "\n")
  cat("--------------------------------------------\n")
  if (length(docs_encontrados) == 0) {
    cat("Nenhum documento encontrado.\n")
  } else {
    for (d in docs_encontrados) cat("-", d, "\n")
  }
}

cat("\n============================================\n")
cat("       BUSCA_AND vs BUSCA_OR\n")
cat("============================================\n")

consulta_teste <- "café museu"

mostrar_resultado(
  paste0("busca_AND('", consulta_teste, "')  — precisa ter TODOS os termos"),
  busca_AND(consulta_teste)
)

mostrar_resultado(
  paste0("busca_OR('", consulta_teste, "')  — precisa ter PELO MENOS UM termo"),
  busca_OR(consulta_teste)
)

mostrar_resultado(
  "busca_AND('porto')",
  busca_AND("porto")
)
```

---

## Aula 04 — Modelo probabilístico BM25 <a id="aula-04"></a>

### Conteúdo da Aula 04
- (1) Tamanho de documentos e IDF probabilístico
- (2) Implementação da função de ranqueamento BM25
- (3) Comparação BM25 vs. TF-IDF
- (4) Análise dos hiperparâmetros k1 e b

### 10. BM25 — tamanho dos documentos e IDF probabilístico

```R
dl <- colSums(tdm)      # |d|: tamanho de cada documento (em tokens já processados)
avgdl <- mean(dl)       # avgdl: tamanho médio dos documentos do corpus

idf_bm25 <- log((N - documentos_com_termo + 0.5) / (documentos_com_termo + 0.5) + 1)

cat("\n============================================\n")
cat("       BM25 — TAMANHO E IDF PROBABILÍSTICO\n")
cat("============================================\n\n")

cat("Tamanho dos documentos (dl):\n")
print(dl)
cat("\nTamanho médio do corpus (avgdl):", round(avgdl, 2), "\n")

cat("\nComparando IDF clássico (seção 6) x IDF do BM25:\n")
comparacao_idf <- data.frame(
  idf_classico = round(idf[c("caf", "fort", "vicent")], 3),
  idf_bm25 = round(idf_bm25[c("caf", "fort", "vicent")], 3)
)
print(comparacao_idf)
```

### 11. Implementação do BM25

```R
k1 <- 1.2   # controla a saturação da frequência (padrão)
b  <- 0.75  # controla o peso do tamanho do documento (padrão)

bm25_doc <- function(consulta, d) {
  termos <- tokenizar_limpar(consulta)   # mesma regra de pré-processamento
  s <- 0
  for (t in termos) {
    if (!(t %in% vocab)) next            # termo fora do vocabulário: contribui 0
    f <- tdm[t, d]                       # f: frequência do termo NESTE documento
    K <- k1 * (1 - b + b * dl[d] / avgdl)
    s <- s + idf_bm25[t] * (f * (k1 + 1)) / (f + K)
  }
  return(s)
}

bm25_ranking <- function(consulta) {
  scores <- sapply(colnames(tdm), function(d) bm25_doc(consulta, d))
  sort(scores, decreasing = TRUE)
}

cat("\n============================================\n")
cat("       TESTE: bm25_ranking('café museu')\n")
cat("============================================\n\n")
print(round(bm25_ranking("café museu"), 4))
```

### 12. Comparando BM25 com TF-IDF em 3 consultas

```R
tfidf_doc <- function(consulta, d) {
  termos <- tokenizar_limpar(consulta)
  termos <- termos[termos %in% rownames(tfidf)]
  if (length(termos) == 0) return(0)
  sum(tfidf[termos, d])
}

tfidf_ranking <- function(consulta) {
  scores <- sapply(colnames(tfidf), function(d) tfidf_doc(consulta, d))
  sort(scores, decreasing = TRUE)
}

consultas_teste <- c("café museu", "forte artilharia", "porto são vicente")

cat("\n============================================\n")
cat("       BM25 vs TF-IDF — 3 CONSULTAS\n")
cat("============================================\n")

for (consulta in consultas_teste) {
  cat("\n--------------------------------------------\n")
  cat("Consulta:", consulta, "\n")
  cat("--------------------------------------------\n")
  cat("BM25:\n")
  print(round(bm25_ranking(consulta), 4))
  cat("\nTF-IDF:\n")
  print(round(tfidf_ranking(consulta), 4))
}
```

### 13. Variando k1 e b

```R
testar_parametros <- function(consulta, k1_vals, b_vals) {
  for (k1v in k1_vals) {
    for (bv in b_vals) {
      k1 <<- k1v
      b  <<- bv
      cat(sprintf("\nk1 = %.1f | b = %.2f\n", k1v, bv))
      print(round(bm25_ranking(consulta), 4))
    }
  }
  k1 <<- 1.2  # restaura o padrão
  b  <<- 0.75
}

cat("\n============================================\n")
cat("       EFEITO DE k1 E b NO RANKING\n")
cat("============================================\n")

testar_parametros("café museu", k1_vals = c(0, 1.2, 3), b_vals = c(0, 0.75, 1))
```

---

## Extras — Análise por Frases <a id="extras"></a>

Análise complementar aplicando os conceitos do motor em granularidade de frases.

### 14. Segmentação de frases

```R
separa_frases <- function(texto) {
  frases <- unlist(
    strsplit(
      texto,
      "(?<=[.!?])\\s+",
      perl = TRUE
    )
  )
  frases <- trimws(frases)
  frases <- frases[
    frases != ""
  ]
  return(frases)
}

santos_frases <- separa_frases(docs[["santos"]])
praia_grande_frases <- separa_frases(docs[["praia_grande"]])
sao_vicente_frases <- separa_frases(docs[["sao_vicente"]])

cat("          FRASES DOS CORPUS\n")
cat("- Santos:", length(santos_frases), "frases\n")
cat("- Praia Grande:", length(praia_grande_frases), "frases\n")
cat("- São Vicente:", length(sao_vicente_frases), "frases\n")

cat("       PRIMEIRAS FRASES\n")
cat("\n--- SANTOS ---\n")
print(head(santos_frases, 3))
cat("\n--- PRAIA GRANDE ---\n")
print(head(praia_grande_frases, 3))
cat("\n--- SÃO VICENTE ---\n")
print(head(sao_vicente_frases, 3))

frases <- c(santos_frases, praia_grande_frases, sao_vicente_frases)
origem_frases <- c(
  rep("santos", length(santos_frases)),
  rep("praia_grande", length(praia_grande_frases)),
  rep("sao_vicente", length(sao_vicente_frases))
)
```

### 15. TF-IDF e similaridade de cosseno por frase

```R
tokens_frases <- lapply(frases, tokenizar_limpar)
vocab_frases <- sort(unique(unlist(tokens_frases)))

tdm_frases <- sapply(
  tokens_frases,
  function(tk) as.integer(table(factor(tk, levels = vocab_frases)))
)
rownames(tdm_frases) <- vocab_frases
colnames(tdm_frases) <- paste0("frase_", seq_along(frases))

N_frases <- ncol(tdm_frases)
total_termos_frase <- colSums(tdm_frases)
tf_frases <- sweep(tdm_frases, 2, total_termos_frase, "/")
documentos_com_termo_frase <- rowSums(tdm_frases > 0)
idf_frases <- log(N_frases / documentos_com_termo_frase)
tfidf_frases <- tf_frases * idf_frases

similaridade_frases <- matrix(0, nrow = ncol(tfidf_frases), ncol = ncol(tfidf_frases))
rownames(similaridade_frases) <- colnames(tfidf_frases)
colnames(similaridade_frases) <- colnames(tfidf_frases)

for (i in 1:ncol(tfidf_frases)) {
  for (j in 1:ncol(tfidf_frases)) {
    similaridade_frases[i, j] <- similaridade_cosseno(tfidf_frases[, i], tfidf_frases[, j])
  }
}
```

### 16. Pares de frases mais semelhantes

```R
resultados <- data.frame(
  frase_1 = character(),
  frase_2 = character(),
  origem_1 = character(),
  origem_2 = character(),
  similaridade = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:(ncol(tfidf_frases) - 1)) {
  for (j in (i + 1):ncol(tfidf_frases)) {
    resultados <- rbind(
      resultados,
      data.frame(
        frase_1 = frases[i],
        frase_2 = frases[j],
        origem_1 = origem_frases[i],
        origem_2 = origem_frases[j],
        similaridade = similaridade_frases[i, j],
        stringsAsFactors = FALSE
      )
    )
  }
}

resultados <- resultados[order(resultados$similaridade, decreasing = TRUE), ]

cat("\n============================================\n")
cat("      10 FRASES MAIS SEMELHANTES\n")
cat("============================================\n\n")

top_pares <- head(resultados, 10)
for (i in seq_len(nrow(top_pares))) {
  cat("\n--------------------------------------------\n")
  cat("Comparação", i, "\n")
  cat("Origem 1:", top_pares$origem_1[i], "\n")
  cat("Frase 1:", top_pares$frase_1[i], "\n")
  cat("\nOrigem 2:", top_pares$origem_2[i], "\n")
  cat("Frase 2:", top_pares$frase_2[i], "\n")
  cat("\nSimilaridade de cosseno:", round(top_pares$similaridade[i], 4), "\n")
}
```