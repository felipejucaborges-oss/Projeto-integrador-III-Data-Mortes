# Consolidado — PI III — Aula 08 — Tema 1 (proximidade e janela) — 24/11/2026

*Guia versão 1 · Tutora: ChatGPT (GPT-6.2) · motor08.R complementado com as funções da Aula 08 (motor09.R indisponível)*

**Aluno:** Felipe Juca Gozza Borges

## 1. O que foi passado

- **M1 — Janela, par a par:** executei os experimentos nos oito documentos didáticos. Para a consulta “modelo de recuperacao”, obtive em d3 pontuação 0 com $w=1$ e $\frac{1}{2}$ de $w=2$ a $5$. Em d2, obtive 1 em todas as janelas. No exercício “modelo de texto”, com $w=5$, obtive 1,7.
- **M2 — Janela no ranking:** obtive AP de 0,833 para $k=1$ e $k=2$, e 1,000 para $k=3$ e $k=4$, em todas as cinco janelas. Na consulta “vetores de documentos”, a janela 4 deslocou d2 da primeira para a terceira posição, ao contrário da janela 2.
- **M3 — Ordem literal:** comparei BM25, proximidade ordenada e livre, com AP de 0,833, 1,000 e 0,583, respectivamente, na consulta do gabarito. No exercício “relevancia documentos”, a ordenada resultou em 0 e a livre em 0,5. A versão livre considera também a ordem inversa, mas continua limitada pela janela.
- **M4 — Corpus do grupo:** utilizei 29 documentos, 10 consultas (6 dev e 4 teste) e 290 julgamentos, com limiar 2. Reproduzi o pré-processamento do grupo (73 stopwords, SnowballC em português, 1.095 termos e média de 77,2 tokens). Reproduzi a metodologia do artigo, somando BM25 e proximidade para reordenar o top-$k$, em vez de usar apenas a proximidade como no guia. No dev, o BM25 e a livre atingiram MAP 1,000; a ordenada atingiu 1,000 com $w=1$ e 0,972 com $w=2$ a $5$, para os três valores de $k$ testados (3, 5 e 10). Reproduzi os parâmetros previamente usados pelo grupo ($k=3$, $w=3$), sem nova seleção pelo teste. No teste, obtive MAP 0,358 (BM25), 0,358 (ordenada) e 0,421 (livre), e nDCG graduado 0,678, 0,704 e 0,726, respectivamente. Na q03 do dev, a ordenada promoveu sao_vicente_03 (grau 1) à frente de sao_vicente_05 (grau 2), reduzindo a AP em 0,1667. Não houve melhora de AP no dev porque o BM25 já atingia o máximo. O teste foi consultado para reproduzir os resultados publicados, inclusive a referência BM25 antes da grade dev; não foi usado para escolher novos parâmetros.

## 2. Como foi o aprendizado — opinião da tutora

Na avaliação da tutora, consegui executar os experimentos com orientação, solucionar dificuldades de carregamento de arquivos e reproduzir os resultados numéricos. Identifiquei corretamente, em uma pergunta inicial, o par de palavras que cabia na janela 1. Contudo, ainda não demonstrei domínio autônomo dos cálculos de proximidade, do efeito da janela e da distinção entre ordem livre e limite de distância. Compreendi a separação entre desenvolvimento e teste na pergunta final.

**Teste final:** acertei M4; a revisar M1, M2 e M3 (1 de 4 acertos). Preciso revisar o limite da janela, a estabilidade da pontuação quando o par já está dentro dela e o fato de a ordem livre também respeitar a distância máxima.

## 3. Observações para a frente

- **Revisar:** cálculo $1/\delta$ para pares válidos, uso da menor distância, diferença entre $w$ e $k$ e limites da proximidade livre.
- **Perguntas guardadas:** nenhuma pergunta conceitual adicional registrada.
- **Para o grupo:** apresentar a técnica e a aplicação ao corpus, destacando o caso q03 e a diferença entre o comportamento nos exemplos didáticos e no corpus real. O empate no dev não demonstra superioridade da livre sobre o BM25; a melhora observada no teste é um resultado descritivo, não critério de escolha.
- **Registro técnico:** devido ao erro 404 do motor09.R, usei motor08.R e as funções originais de proximidade e reordenação das páginas 9 e 11 da teoria. O caso $k=0$ foi tratado na função de avaliação do grupo. Foi utilizada a versão de qrels corrigida para coincidir com o artigo (q09, praia_grande_02, grau 1 para 2); a justificativa textual original foi preservada e merece revisão pelo grupo. A leitura dos qrels no Colab funcionou com latin1.

---

<!-- estado-R:inicio -->
## Estado do R ao fim da sessão
*gerado por `anexar_estado()` em 2026-11-24 23:41 · R version 4.6.1 (2026-06-24) · motor08 v2 2026-10-22 · não edite à mão*

### Objetos

| objeto | tipo | tamanho | valor / amostra |
|---|---|---|---|
| `ap_grupo` | numeric, nomeado | 10 | q01 1, q02 1, q03 1, q04 1, q05 1, q06 1, ... |
| `avgdl_grupo` | numeric | 1 | 77.21 |
| `cfg$limpar` | logical | 1 | TRUE |
| `cfg$acentos` | character | 1 | manter |
| `cfg$stopwords` | character | 0 |  |
| `cfg$k1` | numeric | 1 | 1.2 |
| `cfg$b` | numeric | 1 | 0.75 |
| `cfg$limiar` | numeric | 1 | 2 |
| `cfg$prf_k` | numeric | 1 | 0 |
| `cfg$rocchio` | numeric, nomeado | 3 | a 1, b 0.75, g 0.15 |
| `cfg$modelo` | character | 1 | bm25 |
| `cfg$lsa_k` | numeric | 1 | 2 |
| `cfg$rrf_c` | numeric | 1 | 60 |
| `consultas` | character, nomeado | 10 | q01 café museu santos, q02 forte artilharia canhões, q03 primeira vila fundada no Br..., q04 arquitetura vitrais benedit..., q05 saneamento canais saturnino..., q06 onde se negociava o café an..., ... |
| `corpus` | data.frame | 29 × 6 | colunas: id, pagina, titulo, texto, fonte, url |
| `dev` | character | 6 | q01, q02, q03, q04, q05, q06 |
| `dif_livre` | numeric, nomeado | 6 | q01.q01 0, q02.q02 0, q03.q03 0, q04.q04 0, q05.q05 0, q06.q06 0 |
| `dif_ord` | numeric, nomeado | 6 | q01.q01 0, q02.q02 0, q03.q03 -0.1667, q04.q04 0, q05.q05 0, q06.q06 0 |
| `dl_grupo` | numeric, nomeado | 29 | santos_01 60, santos_02 59, santos_03 100, santos_04 63, santos_05 97, santos_06 89, ... |
| `docs` | character, nomeado | 8 | d1 recuperacao de informacao o..., d2 o modelo de espaco vetorial..., d3 bm25 e um modelo probabilis..., d4 aprendizado estatistico fun..., d5 o indice invertido acelera ..., d6 embeddings capturam a seman..., ... |
| `docs_grupo` | character, nomeado | 29 | santos_01 Santos é um município brasi..., santos_02 Fundada em 1546 por Brás Cu..., santos_03 O principal cartão-postal d..., santos_04 No entanto, em 1531, devido..., santos_05 Em 1543, com o término da c..., santos_06 O saque do pirata Thomas Ca..., ... |
| `g` | numeric, nomeado | 8 | d1 1, d2 2, d3 2, d4 0, d5 0, d6 1, ... |
| `grade` | matrix | 4 × 5 | linhas: (sem nomes) \| colunas: w1, w2, w3, w4, ... |
| `idf_grupo` | numeric, nomeado | 1095 | abaix 2.996, abc 2.996, aboliçã 2.485, abolicion 2.996, abrang 2.996, abreu 2.996, ... |
| `ix$tokens` | list | 8 | elementos: d1, d2, d3, d4, d5, d6, d7, d8 |
| `ix$vocab` | character | 45 | a, acelera, aprendizado, avaliacao, bm25, busca, ... |
| `ix$tf` | matrix | 45 × 8 | linhas: a, acelera, aprendizado, ... \| colunas: d1, d2, d3, d4, ... |
| `ix$N` | integer | 1 | 8 |
| `ix$df` | numeric, nomeado | 45 | a 4, acelera 1, aprendizado 1, avaliacao 1, bm25 1, busca 2, ... |
| `ix$idf_tfidf` | numeric, nomeado | 45 | a 0.6931, acelera 2.079, aprendizado 2.079, avaliacao 2.079, bm25 2.079, busca 1.386, ... |
| `ix$w` | matrix | 45 × 8 | linhas: a, acelera, aprendizado, ... \| colunas: d1, d2, d3, d4, ... |
| `ix$wn` | matrix | 45 × 8 | linhas: a, acelera, aprendizado, ... \| colunas: d1, d2, d3, d4, ... |
| `ix$postings` | list | 45 | elementos: recuperacao, de, informacao, ordena, documentos, por, relevancia, o, ... |
| `ix$dl` | numeric, nomeado | 8 | d1 7, d2 9, d3 9, d4 6, d5 9, d6 8, ... |
| `ix$avgdl` | numeric | 1 | 8 |
| `ix$idf_bm25` | numeric, nomeado | 45 | a 0.6931, acelera 1.792, aprendizado 1.792, avaliacao 1.792, bm25 1.792, busca 1.281, ... |
| `MOTOR_VERSAO` | character | 1 | motor08 v2 2026-10-22 |
| `N_grupo` | integer | 1 | 29 |
| `nec` | data.frame | 10 × 3 | colunas: consulta, conjunto, texto_consulta |
| `nt_grupo` | numeric, nomeado | 1095 | abaix 1, abc 1, aboliçã 2, abolicion 1, abrang 1, abreu 1, ... |
| `pl` | numeric, nomeado | 8 | d1 1, d2 1, d3 0.5, d4 0, d5 0, d6 0, ... |
| `qc` | character | 2 | relevancia, documentos |
| `qr` | data.frame | 290 × 5 | colunas: consulta, documento, grau, origem, justificativa |
| `qrels$q01` | integer, nomeado | 29 | santos_01 0, santos_02 2, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q02` | integer, nomeado | 29 | santos_01 0, santos_02 0, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q03` | integer, nomeado | 29 | santos_01 0, santos_02 0, santos_03 0, santos_04 1, santos_05 0, santos_06 0, ... |
| `qrels$q04` | integer, nomeado | 29 | santos_01 0, santos_02 2, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q05` | integer, nomeado | 29 | santos_01 0, santos_02 0, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q06` | integer, nomeado | 29 | santos_01 0, santos_02 2, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q07` | integer, nomeado | 29 | santos_01 0, santos_02 0, santos_03 0, santos_04 0, santos_05 0, santos_06 2, ... |
| `qrels$q08` | integer, nomeado | 29 | santos_01 0, santos_02 0, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q09` | integer, nomeado | 29 | santos_01 0, santos_02 0, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `qrels$q10` | integer, nomeado | 29 | santos_01 1, santos_02 2, santos_03 0, santos_04 0, santos_05 1, santos_06 0, ... |
| `qt` | character | 3 | modelo, de, recuperacao |
| `qt2` | character | 3 | modelo, de, texto |
| `qv` | character | 3 | vetores, de, documentos |
| `rb` | numeric, nomeado | 8 | d3 1.873, d1 1.869, d2 1.687, d4 1.427, d8 0.519, d6 0.4925, ... |
| `rk_grupo$q01` | numeric, nomeado | 29 | santos_02 6.879, santos_08 2.509, santos_29 2.336, santos_33 2.049, santos_05 0.5537, santos_10 0.504, ... |
| `rk_grupo$q02` | numeric, nomeado | 29 | praia_grande_02 9.729, praia_grande_01 6.73, santos_01 0, santos_02 0, santos_03 0, santos_04 0, ... |
| `rk_grupo$q03` | numeric, nomeado | 29 | sao_vicente_01 5.08, sao_vicente_05 3.836, sao_vicente_03 3.715, santos_04 3.671, sao_vicente_06 3.645, santos_13 3.067, ... |
| `rk_grupo$q04` | numeric, nomeado | 29 | santos_02 6.631, santos_01 0, santos_03 0, santos_04 0, santos_05 0, santos_06 0, ... |
| `rk_grupo$q05` | numeric, nomeado | 29 | santos_09 12.32, santos_20 8.992, santos_18 5.379, sao_vicente_02 3.644, santos_01 0, santos_02 0, ... |
| `rk_grupo$q06` | numeric, nomeado | 29 | santos_02 9.524, santos_18 3.033, santos_13 2.649, sao_vicente_01 2.451, santos_08 2.087, santos_29 2.028, ... |
| `rk_grupo$q07` | numeric, nomeado | 29 | santos_18 3.187, sao_vicente_05 2.734, praia_grande_02 2.624, sao_vicente_04 2.406, sao_vicente_06 2.002, santos_01 0, ... |
| `rk_grupo$q08` | numeric, nomeado | 29 | sao_vicente_03 5.889, sao_vicente_01 4.766, santos_09 2.878, santos_07 2.672, sao_vicente_05 2.443, santos_04 2.422, ... |
| `rk_grupo$q09` | numeric, nomeado | 29 | santos_10 4.366, sao_vicente_03 4.034, santos_01 2.734, sao_vicente_01 2.196, santos_28 2.16, santos_17 1.635, ... |
| `rk_grupo$q10` | numeric, nomeado | 29 | santos_08 4.359, santos_01 3.897, santos_04 3.726, santos_02 3.564, santos_16 2.497, santos_09 2.469, ... |
| `rv` | numeric, nomeado | 8 | d2 2.833, d1 1.25, d6 1.186, d5 0.6594, d3 0.6542, d8 0.519, ... |
| `sc2` | numeric, nomeado | 8 | d1 0, d2 0, d3 0, d4 0, d5 0, d6 0, ... |
| `sc4` | numeric, nomeado | 8 | d1 0.3333, d2 0.25, d3 0, d4 0, d5 0, d6 0.3333, ... |
| `stopwords` | character | 73 | a, à, ao, aos, as, às, ... |
| `tab` | matrix | 8 × 5 | linhas: d1, d2, d3, ... \| colunas: w1, w2, w3, w4, ... |
| `tdm_grupo` | matrix | 1095 × 29 | linhas: abaix, abc, aboliçã, ... \| colunas: santos_01, santos_02, santos_03, santos_04, ... |
| `teste` | character | 4 | q07, q08, q09, q10 |
| `tokens_grupo$santos_01` | character | 60 | sant, municípi, brasileir, litoral, estad, sã, ... |
| `tokens_grupo$santos_02` | character | 59 | fund, brás, cub, send, cidad, antig, ... |
| `tokens_grupo$santos_03` | character | 100 | principal, cartã, postal, municípi, sã, set, ... |
| `tokens_grupo$santos_04` | character | 63 | entant, dev, decadent, negóci, coro, portugues, ... |
| `tokens_grupo$santos_05` | character | 97 | términ, construçã, capel, num, outeir, homenag, ... |
| `tokens_grupo$santos_06` | character | 89 | saqu, pirat, thom, cavendish, deu, orig, ... |
| `tokens_grupo$santos_07` | character | 64 | sant, elev, categor, cidad, janeir, assembl, ... |
| `tokens_grupo$santos_08` | character | 60 | econom, caf, brasil, represent, impuls, precedent, ... |
| `tokens_grupo$santos_09` | character | 110 | aboliçã, escravatur, vind, mã, obra, italian, ... |
| `tokens_grupo$santos_10` | character | 62 | sant, torn, definit, cidad, turíst, part, ... |
| `tokens_grupo$santos_12` | character | 72 | durant, déc, result, process, vind, déc, ... |
| `tokens_grupo$santos_13` | character | 86 | zon, noro, surg, após, necess, expansã, ... |
| `tokens_grupo$santos_16` | character | 48 | áre, influênc, econôm, port, concentr, produt, ... |
| `tokens_grupo$santos_17` | character | 65 | princip, pont, turíst, sant, além, pra, ... |
| `tokens_grupo$santos_18` | character | 97 | basic, red, urban, sant, compost, malh, ... |
| `tokens_grupo$santos_20` | character | 94 | can, sant, hoj, possu, cem, anos, ... |
| `tokens_grupo$santos_21` | character | 113 | carát, litorân, fat, ter, sid, construíd, ... |
| `tokens_grupo$santos_28` | character | 70 | sant, segund, cidad, país, ter, servic, ... |
| `tokens_grupo$santos_29` | character | 65 | cidad, possu, dois, acess, ferroviári, utiliz, ... |
| `tokens_grupo$santos_33` | character | 101 | sant, muit, utiliz, televisã, minisséri, coraçã, ... |
| `tokens_grupo$praia_grande_01` | character | 49 | part, inic, construçã, primeir, bat, segu, ... |
| `tokens_grupo$praia_grande_02` | character | 43 | durant, revolu, constitucional, guarniçã, fort, alinh, ... |
| `tokens_grupo$sao_vicente_01` | character | 102 | sã, vicent, marc, iníci, efet, coloniz, ... |
| `tokens_grupo$sao_vicente_02` | character | 85 | pib, bilhõ, rea, econom, bas, servic, ... |
| `tokens_grupo$sao_vicente_03` | character | 132 | sã, vicent, preserv, divers, síti, edifíci, ... |
| `tokens_grupo$sao_vicente_04` | character | 57 | primeir, déc, sécul, xvi, exist, onde, ... |
| `tokens_grupo$sao_vicente_05` | character | 60 | expediçã, lider, fidalg, português, martim, afons, ... |
| `tokens_grupo$sao_vicente_06` | character | 91 | guerr, iguap, ocorr, anos, regiã, sã, ... |
| `tokens_grupo$sao_vicente_07` | character | 45 | cristian, faz, present, cidad, seguint, form, ... |
| `vocab_grupo` | character | 1095 | abaix, abc, aboliçã, abolicion, abrang, abreu, ... |

### Funções definidas

`anexar_estado`, `ap`, `avaliar_grupo`, `bm25`, `bm25_doc`, `bm25_grupo`, `busca_AND`, `busca_booleana`, `cfg_aula`, `cosseno`, `dcg`, `docs_aula`, `estado`, `gabarito_aula`, `grade_grupo`, `idf_bm25`, `idf_classico`, `indice_invertido`, `kappa_cohen`, `kappa_matriz`, `ler_qrels`, `limpar`, `lsa`, `matriz_tf`, `metricas`, `montar`, `ndcg`, `norm_cols`, `precisao_k`, `preparar`, `prf`, `prox_livre`, `proximidade`, `ranking_bm25`, `ranking_cosseno`, `ranking_lsa`, `ranking_vetor`, `recall_k`, `relevancia`, `reordenar`, `rerank_grupo`, `residual`, `rocchio`, `rr`, `rrf`, `saturacao`, `sem_stop`, `stopwords_aula`, `tokenizar`, `tokenizar_limpar`, `vetor_consulta`
<!-- estado-R:fim -->

