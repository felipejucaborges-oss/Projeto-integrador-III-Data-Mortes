# ==========================================================
# CONFIGURAÇÕES E HIPERPARÂMETROS OFICIAIS DO MOTOR DE BUSCA
# Projeto Integrador III - Baixada Santista
# ==========================================================

cfg <- list(
  # --- Hiperparâmetros do BM25 ---
  k1 = 1.2,
  b  = 0.75,

  # --- Hiperparâmetros do LSA (SVD) ---
  k_lsa = 2,

  # --- Hiperparâmetros da Busca Híbrida (RRF) ---
  rrf_c = 60,

  # --- Hiperparâmetros do Feedback de Relevância (Rocchio) ---
  prf_k = 0,
  rocchio = c(a = 1.0, b = 0.75, g = 0.15),

  # --- Configurações da Avaliação ---
  limiar_relevancia = 2,
  k_eval = 3
)

cat("Ficheiro 'config.R' validado e carregado com sucesso!\n")

