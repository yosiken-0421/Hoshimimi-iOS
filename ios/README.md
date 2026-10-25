# ほしみみ商店街 — iOS / TestFlight 準備

このフォルダは SwiftUI と WKWebView を用いた iOS アプリのソースです。ゲームは `../dist` からアプリに同梱します。通信、ログイン、広告、課金は実装していません。WKWebView の標準永続データストアを使用します。アプリ削除時やOSによるデータ消去ではセーブが失われる可能性があります。

## 現時点の状態

- **TestFlight 登録済み・配布済みではありません。** この Linux 環境では Xcode による実機コンパイル、署名、インストールは検証していません。
- `com.example.hoshimimi.preview` はコンパイル用仮識別子です。Apple に登録した値ではありません。
- GitHub Actions の既定動作はシミュレータ向け未署名コンパイルです。成功しても iPhone にインストールできる IPA にはなりません。
- TestFlight 送信は手動起動時に指定し、必要な設定がすべて揃った場合だけ試行します。送信成功とテスターへの配布完了は別の状態です。

## Mac で開く

1. Xcode と XcodeGen をインストールする。
2. プロジェクトルートで `bash ios/prepare-web.sh` を実行する。
3. `cd ios` → `xcodegen generate` を実行し、`Hoshimimi.xcodeproj` を開く。
4. 自分の Apple Developer チームと、登録済みの固有 Bundle ID を設定する。
5. 実機で購入・自動経営・オフライン報酬・終了後再開・リセット確認をテストする。

## TestFlight 送信に必要なもの

Apple Developer Program の有効な契約、App Store Connect のアプリレコード、固有 Bundle ID、配布証明書とその秘密鍵、App Store 配布用プロビジョニングプロファイル、アップロード権限付き App Store Connect API キーが必要です。認証情報をチャットや公開リポジトリに貼らないでください。

GitHub リポジトリの Variables:

| 名前 | 内容 |
| --- | --- |
| `IOS_BUNDLE_ID` | Apple に登録した Bundle ID |
| `APPLE_TEAM_ID` | 自分の Developer Team ID |
| `IOS_PROFILE_NAME` | 配布用プロビジョニングプロファイルの正確な Name |

GitHub Actions Secrets:

| 名前 | 内容 |
| --- | --- |
| `IOS_DISTRIBUTION_P12_BASE64` | 秘密鍵を含む Apple Distribution 証明書 P12 の base64 |
| `IOS_DISTRIBUTION_P12_PASSWORD` | P12 のパスワード |
| `IOS_PROFILE_BASE64` | App Store 配布用プロファイルの base64 |
| `ASC_API_KEY_P8` | App Store Connect API の P8 本文 |
| `ASC_API_KEY_ID` | キー ID |
| `ASC_API_ISSUER_ID` | Issuer ID |

準備後、Actions の **iOS build and optional TestFlight upload** を手動起動し、送信項目を有効にします。既存アプリへ無断で同じ Bundle ID を流用せず、新規ゲーム用に登録してください。ビルド番号は Actions run number を使用するため、既存番号以下になる場合は調整が必要です。

送信後に Apple の処理・輸出コンプライアンス・テスト情報を確認し、TestFlight のビルドへテスターを割り当てます。外部テストは Apple のベータ審査が必要になる場合があります。

## リリース前の注意

- WebView で表示できるだけで Apple の審査通過が保証されるわけではありません。App Review Guidelines 4.2 の最低限の機能性に対し、ゲームとして十分な内容・独自性・完成度が必要です。
- 表示名「ほしみみ商店街」は仮称です。商標のクリアランスを実施したという意味ではありません。正式公開前に使用地域の商標を確認してください。
- 既存ゲームの画像、音楽、名称、文章、キャラクターをコピーしない設計です。法令適合を保証するものではありません。
- 個人情報を収集しない実装でも、Apple 側の App Privacy 回答と公開プライバシーポリシーなど、申請用情報を実装と一致させる必要があります。
- 実機での保存、オフライン収益、端末時計変更、画面端と回転、VoiceOver、電池消費を検証してから配布してください。

## セーブの持ち出し

Web側の `exportSave` メッセージを受け取り、JSON ファイルを iOS の共有シートへ渡す機能を実装しています。「ファイルに保存」などを選べます。共有先の完了後、一時ファイルを削除します。Safari の blob ダウンロードには依存しません。

復元は Web 側の `<input type="file">` を利用します。iOS 16 の WKWebView におけるファイル選択、選択後の JSON 読み込み、共有シートで保存したファイルの再読込は、実機で未検証です。配布前に保存→アプリ終了→復元まで確認してください。
