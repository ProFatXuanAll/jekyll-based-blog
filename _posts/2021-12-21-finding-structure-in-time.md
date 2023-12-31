---
layout: ML-note
title: "Finding Structure in Time"
date: 2021-12-21 18:47:00 +0800
categories: [
  Text Modeling,
]
tags: [
  RNN,
  Elman Net,
  model architecture,
  neural network,
]
author: [
  Jeffrey L. Elman,
]
---

|-|-|
|目標|提出 Elman Net|
|作者|Jeffrey L. Elman|
|期刊/會議名稱|Cognitive Science|
|發表時間|1990|
|論文連結|<https://onlinelibrary.wiley.com/doi/abs/10.1207/s15516709cog1402_1>|

## 重點

- 世界上的語言以文字在句中的順序可以區分成兩種
  - Fixed word-order：文字的順序是有規則的，例如英文
    - 需要考慮語法結構（syntactic structure）、謂詞（[predicate][predicate]）語意限制（[selective restrictions][selective-restrictions]）、次範疇化（[subcategorization][subcategorization]）、論元（[valency][valency]）、對話（discourse）等
    - Chomsky 認為文字順序非線性（linear order），雖然人類只能觀測到線性順序，但大腦會自動轉換成非線性順序進行理解
  - Free word-order：文字的順序替換規則較為自由，但不完全隨機
- 在此論文之前的語言學研究認為所有語句都可以轉換成語法樹（syntactic tree），但不特別探討時間順序問題
  - 作者認為在 parsing 任務仍然表現很差的情況下，此一假設不太適當
- 在此論文之前的研究中，大多數的研究嘗試以 RNN 模型解決時間序列問題通常是隨著時間增加輸入維度
- 作者提出 Elman Net，使用隱藏層的計算結果進行回饋，就是現在常見的 RNN 架構
  - [PyTorch 的 RNN][PyTorch-RNN] 模型就是基於 Elman Net 進行實作
- 作者評估語言模型（language model）的方法不是困惑度（perplexity），而是期望值最大化（expectation maximization）
  - 也許現在（2021）年的 pre-train model 該考慮一下期望值最大化的評估手段
- 根據實驗結果，作者認為以 **distributed representation** 表達**語言**能夠同時學會**字符**（**token**）與**種類**（**type**）的知識
  - 傳統 symbolic systems 需要手動定義字符與種類的差異
  - Distributed representation 比 symbolic systems 還要強大

## 以空間代表時間產生的問題

若時間序列 $x = x_1, \dots, x_T$，$T$ 為該序列的長度，則常見的時間序列處理方法為將每個時間的 $x_t$ 的輸入以一個維度作為代表，因此輸入維度就會與序列長度 $T$ 相同。

以上的架構可以想成空間資訊描述時間資訊，但此方法有不少問題

- 模型一定要在取得所有輸入後才能計算，除了跟人類的行為不太一樣以外，模型**沒有辦法自己知道什麼時候已經取得所有輸入**
- **輸入維度固定**代表訓練的過程必須要選擇**最長**的輸入序列作為模型輸入維度，除了**浪費計算資源**以外，在測試時**過長的輸入就無法被處理**
- 輸入架構同時隱含**距離關係**，因此無法辨別**相對時間差**的觀念
  - 當兩個輸入序列只有**時間差上的差異**，則直接將完整輸入序列丟進模型會導致模型無法區分相對時間的差異
  - 例如：`011100000` 與 `000111000` 兩個序列，時間差為 $2$，但以向量直接表達時兩者的歐式距離為 $2$，此距離差異可能代表完全無關的資料

## Elman Net

<a name="paper-fig-1"></a>

圖 1：Elman Net 架構。
圖片來源：[論文][論文]。

![圖 1](https://i.imgur.com/0kJih5k.png)

提出的架構概念如下

- 模型共有三層：輸入層 + 隱藏層 + 輸出層
- 序列資料按照時間依序輸入至模型
- 隱藏層會再作為下個時間點的輸入回饋到隱藏層
  - 回饋的隱藏層額外稱為 **Context Units**，由於所有的隱藏單元都會回饋，因此 Context Units 與隱藏單元的個數一樣多
  - 回饋的方法是全連接
  - Context Units 初始值設定為 $0.5$，理由是作者採用的啟發函數（activation function）數值範圍落在 $[0, 1]$ 之間（論文沒寫但應該是 sigmoid）
- 最佳化的方法就是 BPTT

## 實驗 1：序列版 XOR

### 任務定義

傳統的兩層神經網路（輸入層 + 輸出層）是無法解決 XOR 問題，一定要額外使用隱藏層才有辦法解決。

輸入只會是由 2 bits 組成的序列 $\set{00, 01, 10, 11}$，當輸入為 $\set{00, 11}$ 時輸出為 $0$，輸入為 $\set{01, 10}$ 時輸出為 $1$。

序列版的 XOR 任務就是將 $N$ 組 XOR 的輸入輸出串接在一起（三個 bits 為一組），總共長度為 $3N$ bits，目標為在輸入一個 bit 之後預測下個 bit。

- 神經網路每個時間點收到的訊號就只有 $1$ 個 bit
- 實驗所採用的 $N = 1000$，即輸入序列由 $3000$ bits 所組成
- 最佳化目標為最小平方差（MSE）
- 以 $N = 3$ 為例，XOR 序列可以是 $110011101$
  - 第一跟第二個 bits 為 $11$，因此第三個 bit 為 $0$；第四跟第五個 bits 為 $01$，因此第六個 bit 為 $1$；第七跟第八個 bits 為 $10$，因此第三個 bit 為 $1$。
  - 第一個 bit 無法預測第二個 bit（是 $0$ 或 $1$ 的機率為 $50\%$），但第二個 bit 必須要透過第一個 bit 的資訊預測第三個 bit

### Elman Net 架構

|參數|數值（或範圍）|備註|
|-|-|-|
|輸入層維度|$1$|一次只有 $1$ 個 bit 輸入|
|隱藏層維度|$2$||
|輸出層維度|$1$|一次只有 $1$ 個 bit 輸出|

### 實驗結果

<a name="paper-fig-2"></a>

圖 2：序列版 XOR 實驗分析。
圖片來源：[論文][論文]。

![圖 2](https://i.imgur.com/Fs6mGLJ.png)

- 模型在無法預測時誤差較高，可以預測時誤差較低，見[圖 2](#paper-fig-2)
  - 圖中的實驗結果只分析前 $12$ 個 bits，以 $1200$ 次實驗結果平均
  - 至少要訓練 $600$ 次才可以達成上述結果
  - 論文沒有著明最佳化所採用的學習率（learning rate）
- 兩個隱藏單元在看到不同輸入 pattern 時維持開啟（接近 $1$）
  - 當輸入都是由 $\set{000, 110}$ 組成時，其中一個隱藏單元維持開啟
  - 當輸入都是由 $\set{011, 101}$ 組成時，另外一個隱藏單元維持開啟
  - 與單純使用全連接層解決 XOR 的作法觀察到的隱藏單元現象不同，說明架構不同時對於類似的任務可以有不同的解法

## 實驗 2：字母序列

### 任務定義

<a name="paper-table-1"></a>

表 1：字母向量表達法與其意義。
表格來源：[論文][論文]。

|字母|consonant|vowel|interrupted|high|back|voiced|
|-|-|-|-|-|-|-|
|`b`|`1`|`0`|`1`|`0`|`0`|`1`|
|`d`|`1`|`0`|`1`|`1`|`0`|`1`|
|`g`|`1`|`0`|`1`|`0`|`1`|`1`|
|`a`|`0`|`1`|`0`|`0`|`1`|`1`|
|`i`|`0`|`1`|`0`|`1`|`0`|`1`|
|`u`|`0`|`1`|`0`|`1`|`1`|`1`|

- 一個序列由 $6$ 個不同的字母組成，每個字母由 $6$ 個 bits 作為代表，細節請見[表 1](#paper-table-1)
- 首先由子音 `bdg` 生成總長度為 $1000$ 的隨機序列，接著將子音依照以下規則進行替換，產生的最終序列作為模型輸入
  - `b` 換成 `ba`
  - `d` 換成 `dii`
  - `g` 換成 `guuu`
- 每個時間點輸入一個字母（6 bits），預測下一個時間點的字母
  - 子音無法預測
  - 當子音出現時母音可以預測
  - 最後一個時間點的輸入預測目標是第一個時間點的輸入
- 最佳化目標為最小平方差（MSE）
- 在同一個輸入序列（長度 $> 1000$）上總共訓練 $200$ 次，測試時使用不同的序列（產生方法相同）進行測試

### Elman Net 架構

|參數|數值（或範圍）|備註|
|-|-|-|
|輸入層維度|$6$|一個字母有 $6$ 個 bits|
|隱藏層維度|$20$||
|輸出層維度|$6$|一個字母有 $6$ 個 bits|

### 實驗結果

<a name="paper-fig-3"></a>

圖 3：字母序列輸出 $6$ 個 bits 的平均誤差實驗結果。
圖片來源：[論文][論文]。

![圖 3](https://i.imgur.com/yLHWxfr.png)

<a name="paper-fig-4"></a>

圖 4：字母序列輸出第 $1$ 個 bit 的誤差實驗結果。
圖片來源：[論文][論文]。

![圖 4](https://i.imgur.com/BvnBbEV.png)

<a name="paper-fig-5"></a>

圖 5：字母序列輸出第 $4$ 個 bit 的誤差實驗結果。
圖片來源：[論文][論文]。

![圖 5](https://i.imgur.com/U1U1joV.png)

- 模型的平均誤差在無法預測時較高，可以預測時較低，見[圖 3](#paper-fig-3)
- 第 $1$ 個 bit 的規則是完全可以預測的
  - 模型必須根據子音的類別（與第 $1, 4, 5$ 個 bits 有關）預測母音的個數
  - 第 $1$ 個 bit 的預測誤差較低（見[圖 4](#paper-fig-4)）說明模型能夠達成任務
- 第 $4$ 個 bit 只能預測母音，無法預測子音
  - 模型必須根據子音的類別（與第 $1, 4, 5$ 個 bits 有關）預測母音的個數
  - 由於子音出現無規則，因此第 $4$ 個 bit 的預測誤差稍微高一點，見[圖 5](#paper-fig-5)

## 實驗 3：字母層級語言模型

<a name="paper-table-2"></a>

表 2：字母向量表達法，每個字母以 $5$ bits 編碼。
表格來源：[論文][論文]。

|字母|bit|字母|bit|字母|bit|
|-|-|-|-|-|-|
|`a`|`00001`|`b`|`00010`|`c`|`00011`|
|`d`|`00100`|`e`|`00101`|`f`|`00110`|
|`g`|`00111`|`h`|`01000`|`i`|`01001`|
|`j`|`01010`|`k`|`01011`|`l`|`01100`|
|`m`|`01101`|`n`|`01110`|`o`|`01111`|
|`p`|`10000`|`q`|`10001`|`r`|`10010`|
|`s`|`10011`|`t`|`10100`|`u`|`10101`|
|`v`|`10110`|`w`|`10111`|`x`|`11000`|
|`y`|`11001`|`z`|`11010`|||

- 使用簡單的單字（word）層級語言模型產生文字
  - 可以產生的單字共有 $15$ 種
  - 總共產生 $200$ 個句子，長度不一
  - 每個句子包含最少 $4$ 個單字，最多 $9$ 個單字
- 所有產生的句子串接在一起，產生總長為 $1270$ 個單字的序列，共由 $4963$ 個字母（letter）組成
  - 由於英文只有 $26$ 個字母，因此每個字母以 $5$ bits 表達
- 模型的任務為根據已經接收到的字母預測下個時間點的字母，即字母層級語言模型（letter-level language model）
- 總共訓練 $10$ 次，最佳化目標為最小平方差（MSE）

### Elman Net 架構

|參數|數值（或範圍）|備註|
|-|-|-|
|輸入層維度|$5$|一個字母有 $5$ 個 bits|
|隱藏層維度|$20$||
|輸出層維度|$5$|一個字母有 $5$ 個 bits|

### 實驗結果

<a name="paper-fig-6"></a>

圖 6：字母層級語言模型預測誤差，圖中只顯示一部份字母語言序列（many years ago a boy and girl lived by the sea they played happily m）。
圖片來源：[論文][論文]。

![圖 6](https://i.imgur.com/nVD0jMO.png)

- 模型誤差在出現新的單字時較高，在預測單字字母時較低，見[圖 6](#paper-fig-6)
- 大多數時可以依靠誤差進行斷字（當誤差相對上升時就可以斷字），但仍有部份單字不是用此規則
  - 例如 they 的 y 誤差上升
  - 在部份實驗（不包含在[圖 6](#paper-fig-6)）中發現常見的單字序列有可能被當成可以連續預測的片段，導致誤差持續下降而無法斷字，作者認為此概念就像小孩在學習俗諺（idioms）一樣把俗諺當成單字使用
- 作者認為不能只使用此模型進行斷字，必須同時考慮前後文，就如同語音辨識一樣
  - Elman Net 只是展示簡單的 RNN 能夠學到部份斷字的知識

## 實驗 4：單字層級語言模型

<a name="paper-fig-7"></a>

圖 7：單字層級語言模型所使用的單字種類，共有 $13$ 種，只考慮名詞與動詞。
圖片來源：[論文][論文]。

![圖 7](https://i.imgur.com/Dv9knWh.png)

<a name="paper-fig-8"></a>

圖 8：字母層級語言模型訓練資料生成模版。
圖片來源：[論文][論文]。

![圖 8](https://i.imgur.com/dko5W1S.png)

<a name="paper-fig-9"></a>

圖 9：部份訓練資料範例。
圖片來源：[論文][論文]。

![圖 9](https://i.imgur.com/ByfVIn0.png)

- 使用[圖 7](#paper-fig-7) 的單字與[圖 8](#paper-fig-8) 的模版生成訓練資料
  - 每筆訓練資料只會包含 $2 \sim 3$ 個字
  - 共有 $13$ 個不同類別的名詞與動詞，總共有 $29$ 個不同的單字
  - 部份動詞會跨類別，例如 `break` 屬於破壞動詞 `VERB-DESTORY` 但也同時屬於及物動詞 `VERB-TRAN`（transitive）
- 總共產生 $10000$ 筆訓練資料，每筆資料必須符合[圖 8](#paper-fig-8) 的模版（selective restrictions），最後所有資料串接在一起形成長度為 $27354$ 的文字序列
  - 每筆資料中的字由 $31$ bits 的 one-hot vector 代表
  - $31$ bits 的理由是後續的實驗會繼續使用相同的架構
  - 總 bits 數為 $27354 \times 31 = 853554$
  - 部份訓練資料範例請見[圖 9](#paper-fig-9)
- 模型的任務為根據已經接收到的單字預測下個時間點的單字，即單字層級語言模型（word-level language model）
  - 句子之間無明顯分割，模型無法預測下個句子的開頭
  - 在句子中由於接續的動詞與名詞都有多個選項，模型也無法準確預測
  - 但接續的單字仍然有固定的規則，模型必須學會該規則在輸入序列中的**期望值**
  - 因此訓練目標是 one-hot vector 的最小平方差（MSE），預測目標是期望值的 MSE
- 期望值的計算方法如下
  - 句子開頭的期望值為：句子開頭的出現次數除以 $10000$（總共有 $10000$ 個句子）
  - 中間動詞的期望值為：中間動詞出現次數除以相同開頭名詞的出現次數
  - 結尾名詞的期望值為：結尾名詞出現次數除以相同開頭名詞 + 動詞的出現次數
- 總共訓練 $6$ 次
  - 每次訓練的結尾會接續訓練的開始
  - 評估方法為方均根差（Root Mean Square Error，RMSE）
  - RMSE 計算對象可以是 one-hot vector 或期望值

### Elman Net 架構

|參數|數值（或範圍）|備註|
|-|-|-|
|輸入層維度|$31$|一個單字有 $31$ 個 bits|
|隱藏層維度|$150$||
|輸出層維度|$31$|一個單字有 $31$ 個 bits|

### 實驗結果

- 訓練後模型輸出與真實答案（one-hot vector）之間的 RMSE 為 $0.88$
  - 作者發現由於輸出數字絕大部份為 $0$（sparse），因此模型很快就學會將輸出降為 $0$
  - 模型的起始誤差為 $15.5$，最終誤差接近 $1$，在所有輸出都接近 $0$ 的狀況下作者認為 RMSE 為 $0.88$ 並不是什麼了不起的事
- 訓練後模型輸出與期望值之間的 RMSE 為 $0.053$，標準差為 $0.1$
- 由於模型的輸出加總並不為 $1$（不像現代（2021）都有使用 softmax），因此使用 cosine similarity 評估
  - 與期望值之間的 cosine similarity 為 $1$ 時仍然有可能 RMSE 不為 $0$
  - 與期望值之間的平均 cosine similarity 為 $0.916$，標準差為 $0.123$
- 不論是 RMSE 或 cosine similarity，模型表現都不錯
  - 由於輸入彼此正交，模型只能透過共同出現統計次數（co-occurrence statistics）進行學習
  - 模型有可能透過 co-occurrence 學會單字種類這種泛化能力（generalization），因此作者接下來對單字種類進行分析

### 分析 4-1：隱藏單元的群集

<a name="paper-fig-10"></a>

圖 10：群集分析結果。
圖片來源：[論文][論文]。

![圖 10](https://i.imgur.com/7WnWsXM.png)

- 將每個時間點產生所得的隱藏單元儲存起來
  - 總共儲存 $27354 \times 150$ bits
  - 注意是隱藏單元不是輸出單元
- 將**相同單字**產生的隱藏單元加起來取平均，並將結果進行群集（clustering）分析
  - 作者沒說群集分析採用什麼演算法與距離函數（metric）
- 主要的群集以詞性區分，見[圖 10](#paper-fig-10)
  - 動詞的主要群集以及物動詞（transitive）、不及物動詞（intransitive）或兩者皆可進行區分
  - 名詞的主要群集以可動物（animates）與不可動物（inanimate）進行區分
    - 可動物的主要群集以人類（human）與非人類（nonhuman）進行區分
    - 不可動物的主要群集以可破壞（breakable）、可實用（edibles）與非人類主詞（subjects of agentless ative verbs）進行區分
- 根據群集觀察結果可以推論模型學會以類別進行區分的泛化能力
  - 即使模型無法準確預測單字（任務本身的特性），但仍能學會泛化能力
  - 由於輸入並沒有給予類別資訊，並非如人類學習語言的過程，作者認為實驗結果非常有趣
  - 作者強調群集結果不是絕對正確，因為部份群集可以同時在距離空間（metric space）上被分成不同群集，但同時共享相同特性

### 分析 4-2：模型泛化能力

<a name="paper-fig-11"></a>

圖 11：模型泛化能力測試結果。
圖片來源：[論文][論文]。

![圖 11](https://i.imgur.com/Fs5W81y.png)

- 加入完全無意義的新字 `zog`，並以第 $30$ 個 bit 為 $1$ 的 one-hot vector 進行表達
  - 將所有 `man` 出現的位置都替換成 `zog`
  - 新的序列（$27354 \times 31$ 個 bits）直接輸入給模型，不做任何的訓練，並紀錄隱藏單元後進行與分析 4-1 相同的群集分析
- 根據實驗結果發現 `zog` 與 `man` 的表現接近，說明模型擁有泛化

### 分析 4-3：上下文感知能力

<a name="paper-fig-12"></a>

圖 12：模型泛化能力測試結果。
圖片來源：[論文][論文]。

![圖 12-1](https://i.imgur.com/RNwrZKv.png)
![圖 12-2](https://i.imgur.com/RIV0mL3.png)

- 由於分析 4-1 的結果是以隱藏層**平均**向量進行分析，而平均運算將前文的概念去除，因此無法判斷模型是否擁有上下文感知（context sensitive）能力
- 使用平均進行實驗在計算上是比較實際的，但真的要分析前後文內容只能依靠單筆資料的計算結果進行分析
  - 總共有 $27454$ 個 $150$ bits 的向量（包含 `zog`）
  - 由於種類過多無法視覺化，但概念與[圖 10](#paper-fig-10) 相同，只是群集同時考量前文
- [圖 10](#paper-fig-10) 證實模型學會了從 $29$ 種單字中找出類別資訊，[圖 12](#paper-fig-12) 證實模型能夠區分類似的前後文
  - 相同的單字在不同的前後文中會被分成不同的群集
    - 模型能夠區分單字出現在開頭與結尾
  - 意義相同的單字會出現類似的群集
- 根據實驗結果，作者認為以 **distributed representation** 表達**語言**能夠同時學會**字符**（**token**）與**種類**（**type**）的知識
  - 傳統 symbolic systems 需要手動定義字符與種類的差異
  - Distributed representation 比 symbolic systems 還要強大

[論文]: https://onlinelibrary.wiley.com/doi/abs/10.1207/s15516709cog1402_1
[PyTorch-RNN]: https://pytorch.org/docs/stable/generated/torch.nn.RNNCell.html
[predicate]: https://en.wikipedia.org/wiki/Predicate_(grammar)
[selective-restrictions]: https://en.wikipedia.org/wiki/Selection_(linguistics)
[subcategorization]: https://en.wikipedia.org/wiki/Subcategorization
[valency]: https://en.wikipedia.org/wiki/Valency_(linguistics)
