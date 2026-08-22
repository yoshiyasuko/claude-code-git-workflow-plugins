# `/create-pr` のフロー

```mermaid
flowchart TD
    A[現在の状態を把握] --> B{mainブランチ?}
    B -- Yes --> C[ブランチ作成<br/>自律: 名前を自動生成<br/>interactive: 確認と名前入力]
    B -- No --> D
    C --> D
    C -. interactive で中止 .-> ABORT[処理中止]
    D{未コミット変更?}
    D -- Yes --> F["/commit 実行<br/>(skip-push skip-post-hooks)<br/>interactive 時は事前確認あり"]
    D -- No --> G
    F -. interactive で中止 .-> ABORT

    subgraph commit ["/commit 内部フロー"]
        F --> F1{skip-pre-hooks?}
        F1 -- No --> F2[🔵 pre-commit フック実行]
        F1 -- Yes --> F3
        F2 --> F3[変更の分割 & コミット作成]
    end

    F3 --> G[ベースブランチ確認<br/>自律: デフォルトブランチ<br/>interactive: ユーザー選択]
    G --> H{既存PRあり?}
    H -- Yes --> I[rebase & push<br/>PR タイトル・本文を更新]
    H -- No --> J[rebase & push<br/>PR 新規作成]
    I --> K{skip-post-hooks?}
    J --> K
    K -- No --> L[🟠 post-pr フック実行<br/>自律: Claude判断 / interactive: ユーザー確認]
    K -- Yes --> END[結果表示]
    L --> END

    style F2 fill:#dbeafe,stroke:#3b82f6
    style L fill:#fef3c7,stroke:#f59e0b
```

デフォルトは自律モード。`interactive` 引数を付けた場合のみ、ブランチ作成・コミット・ベースブランチ選択・post-pr フック実行の各ポイントでユーザー確認が入る（`interactive` は内部の `/commit` 呼び出しにも転送される）。

## フックの凡例

| 色 | フック | タイミング |
|----|--------|-----------|
| 🔵 青 | `pre-commit` | コミット前に自動実行（`/commit` の pre-commit と共通） |
| 🟠 橙 | `post-pr` | PR作成・更新後に実行（自律モードでは Claude が実行要否を判断、`interactive` 時はユーザー確認付き） |
