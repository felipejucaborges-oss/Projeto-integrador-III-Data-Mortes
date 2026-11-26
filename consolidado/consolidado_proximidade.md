# Consolidado de Experimentos: Reordenação por Proximidade

Este documento consolida os resultados e análises dos experimentos de reordenação de documentos baseados em critérios de proximidade de termos (Proximidade Ordenada vs. Proximidade Livre), tendo o BM25 como nossa baseline de Estágio 1.

---

## 1. Configurações do Experimento

* **Janela de Proximidade ($w$):** Testada na grade de $1$ a $5$.
* **Documentos Reordenados ($k$):** Testado na grade de $3$, $5$ e $10$.
* **Seleção de Hiperparâmetros:** Otimizado no conjunto de desenvolvimento (`dev`) visando maximizar o MAP (Mean Average Precision).
* **Configuração Escolhida:**
  * **Proximidade Ordenada:** $k = 3$, $w = 3$
  * **Proximidade Livre:** $k = 3$, $w = 3$

---

## 2. Resultados Comparativos Globais (Limiar \ge 2$)

As métricas principais computadas para o conjunto de **Desenvolvimento** (`dev`) e de **Teste** (`teste`) são apresentadas a seguir:

### Conjunto de Desenvolvimento (6 Consultas)
| Abordagem | $P@k$ ($k=3$) | MAP | RR | nDCG (Graduado) |
| :--- | :---: | :---: | :---: | :---: |
| **BM25 (Estágio 1)** | 0.444 | 1.000 | 1.000 | 0.950 |
| **Proximidade Ordenada** | 0.444 | 0.972 | 1.000 | 0.946 |
| **Proximidade Livre** | 0.444 | 1.000 | 1.000 | 0.950 |

*Nota: O conjunto de desenvolvimento obteve teto de desempenho (MAP = 1.000) devido à alta especificidade e calibração das consultas para este subconjunto.*

### Conjunto de Teste (4 Consultas)
| Abordagem | $P@k$ ($k=3$) | MAP | RR | nDCG (Graduado) | Ganho Relativo (MAP) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **BM25 (Estágio 1)** | 0.167 | 0.393 | 0.488 | 0.712 | *Baseline* |
| **Proximidade Ordenada** | 0.167 | 0.393 | 0.488 | 0.705 | 0.0% |
| **Proximidade Livre** | 0.167 | **0.455** | **0.613** | **0.727** | **+15.7%** |

---

## 3. Principais Descobertas e Análise de Comportamento

1. **Superioridade da Proximidade Livre:**
   * Enquanto a proximidade ordenada não trouxe melhorias agregadas no conjunto de teste, a **Proximidade Livre obteve ganhos expressivos de +15.7% no MAP e +25.6% no Reciprocal Rank (RR)**.
   * A restrição de ordem estrita da proximidade ordenada prejudica consultas em que a estrutura gramatical natural do português ou a redação da Wikipédia inverte a ordem dos termos chaves em relação à consulta do usuário.

2. **Estudo de Caso — Consulta q08 (*"marcos da fundação de São Vicente"*):**
   * No BM25 e na Proximidade Ordenada, a consulta obteve $AP = 0.417$.
   * Com a aplicação de **Proximidade Livre**, o $AP$ saltou para **0.667** e o nDCG graduado subiu de **0.785** para **0.873**.
   * Isso ocorreu porque os termos mapeados (`marc`, `fundaçã`, `sã`, `vicent`) aparecem distribuídos de forma muito próxima no documento altamente relevante `sao_vicente_01`, porém fora da ordem sequencial da consulta original.

3. **Sensibilidade ao Limiar de Relevância (Limiar \ge 1$):**
   * Ao suavizar o critério de relevância para englobar documentos parcialmente relevantes (grau 1), o ganho relativo da Proximidade Livre no teste se manteve robusto, suavizando o impacto de penalizações em consultas extremamente restritivas como a `q09`.

