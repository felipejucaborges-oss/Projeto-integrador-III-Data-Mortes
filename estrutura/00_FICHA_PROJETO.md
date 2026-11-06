# Ficha do Projeto: Motor de Busca — Baixada Santista (PI III)

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
| **LSA (SVD)** | `k` | **2** | Dimensões/tópicos latentes retidos ($k \le N_{docs}$) |
| **RRF (Híbrido)**| `c` | **60** | Constante de suavização do Reciprocal Rank Fusion |
| **Avaliação** | `limiar_grupo` | **2** | Limiar para binarização de relevância nos $qrels$ |
| **Avaliação** | `k` | **3** | Profundidade de corte nas métricas Top-K |
| **Rocchio** | `a` ($\alpha$) | **1.0** | Peso da consulta original |
| **Rocchio** | `b` ($\beta$) | **0.75** | Peso do centroide de documentos relevantes |
| **Rocchio** | `g` ($\gamma$) | **0.15** | Peso do centroide de documentos não relevantes |

---

## 3. Resumo da Avaliação Comparativa de Desempenho

Médias globais obtidas no conjunto de consultas com relevância confirmada ($R_q > 0$):

| Modelo | P@3 | AP (MAP) | RR (MRR) | nDCG (Binário) | nDCG (Graduado) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Cosseno (TF-IDF)** | 0.444 | 0.611 | 0.611 | 0.710 | 0.797 |
| **LSA (Semântico)** | 0.444 | **0.778** | **0.833** | **0.850** | **0.942** |
| **Híbrido (RRF: Cos + LSA)** | 0.444 | 0.611 | 0.611 | 0.710 | 0.797 |

