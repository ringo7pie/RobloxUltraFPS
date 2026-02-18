# AGENTS.md — Pesto / Roblox プロジェクトルール

- 全て日本語で回答して下さい

- ファイル検索は rg を使って下さい

- 違うソースコードで、同じ定義をする避けてください。

- 拡張性がある方法で、実装してください。

- 変数、関数のコメントを日本語で書いて下さい。

- 日本語の変数も関数も使わないでください。

## オブジェクト思考で実装して下さい。
- オブジェクト思考で実装して下さい。
- 例1. プレイヤーのパラメータ、処理は、プレイヤーのスクリプトに実装して下さい。
- 例2. 敵キャラのパラメータ、処理は、敵キャラのスクリプトに実装して下さい。
- 例3. NPCキャラのパラメータ、処理は、NPCキャラのスクリプトに実装して下さい。

アマモの処理は、アマモのスクリプトでやるようにして下さい。
魚の処理は、魚のスクリプトでやるようにして下さい。

## Pesto ファイルレイアウト (重要)
- Roblox スクリプトインスタンスは、スクリプト名と一致する名前のディレクトリとして保存されます。
- 例1: `StarterPlayer/StarterPlayerScripts/PlaceAmamoMesh.client.lua/__Source__.luau`
このスクリプトのパスとファイル名は、`StarterPlayer/StarterPlayerScripts/PlaceAmamoMesh.client.lua` となります。

- 例2: `StarterPlayer/StarterPlayerScripts/PlaceAmamoMesh.client.lua/__Properties__.yaml`
このファイルは、`StarterPlayer/StarterPlayerScripts/PlaceAmamoMesh.client.lua` の インスタンスのプロパティ/メタデータとなります。

- 例3: `ServerScriptService\AmamoFishSpawner.server.lua\__Source__.luau`
このスクリプトのパスとファイル名は、`ServerScriptService\AmamoFishSpawner.server.lua` となります。

- 例4: `ServerScriptService\AmamoMeshe\__Source__.luau`
このスクリプトのパスとファイル名は、`ServerScriptService\AmamoMeshe.lua` となります。

## 編集ルール
- Roblox スクリプトの修正を求められた場合は、必ず対応する `__Source__.luau` を編集してください。
- ディレクトリと同じ場所に、フラットな `.lua` ファイルを作成しないでください。
- 明示的に要求されない限り、ディレクトリ名（インスタンス名）は変更しないでください。

## ナビゲーションのヒント
- ユーザーが `X.lua` について言及している場合は、`X.lua/__Source__.luau` を見つけて編集します。
- ユーザーが `X.client.lua` について言及している場合は、`X.client.lua/__Source__.luau` を見つけて編集します。
- ユーザーが `X.server.lua` について言及している場合は、`X.server.lua/__Source__.luau` を見つけて編集します。
- ユーザーが `X.lua` について言及している場合は、`X/__Source__.luau` を見つけて編集します。
