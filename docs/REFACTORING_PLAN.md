# リファクタリング実装計画

3つの観点をそれぞれ独立したブランチで進める。ブランチは下から順に積み上げる
（後のブランチは前のブランチを含む）。各ブランチで「失敗するテストを書く → 実装 → テストが通る → ビルド」を繰り返す。

テストは `Packages/IrisEyeGlanceCore` に置いた Swift Package 内で Swift Testing を使い、
`swift test` で macOS 上で実行する。アプリ本体は `SYIris.framework` が arm64 実機専用のため、
シミュレータ上でホストするテストが実行できない。純粋ロジックをパッケージに切り出すことで
実機なしでテストできるようにする。

| 順 | ブランチ | 観点 |
|---|---|---|
| 1 | `refactor/app-config` | Info.plist とアプリケーション設定 |
| 2 | `refactor/detection-core` | 波形取得・判別のソースコードとファイル構造 |
| 3 | `refactor/ui` | 画面の操作性と UI |

---

## 1. `refactor/app-config` — Info.plist とアプリケーション設定

### テスト（`ProjectConfigurationTests`）
- Xcode は `GENERATE_INFOPLIST_FILE = YES` のとき Info.plist の単純なキーを `INFOPLIST_KEY_*` ビルド設定へ自動移行する。
  そのためテストは「ビルド設定 + Info.plist」をマージした実効値（`EffectiveInfoPlist`）を検証し、
  同じキーが両方に定義されていないことも確認する
- 実効値について以下を検証する
  - `NSCameraUsageDescription` が「プロフィール画像」ではなく、顔追跡と視線入力の用途を説明している
  - `UIRequiredDeviceCapabilities` が `arm64` と `front-facing-camera` を含み `armv7` を含まない
  - `UISupportedInterfaceOrientations` が縦向きのみ
  - `ITSAppUsesNonExemptEncryption` が `false`
  - `UIFileSharingEnabled` / `LSSupportsOpeningDocumentsInPlace` が `true`（CSV 取り出し用）
- `PrivacyInfo.xcprivacy` が存在し、UserDefaults の利用理由 `CA92.1` を宣言している
- `CameraConfiguration` が縦向き・ミラー・BGRA の設定値を返す

### 実装
- `INFOPLIST_KEY_*` ビルド設定を正とし、Info.plist にはビルド設定で表現できないキー
  （シーンマニフェスト、`UIFileSharingEnabled`）のみ残す。`PrivacyInfo.xcprivacy` を追加
- ビルド設定: `IPHONEOS_DEPLOYMENT_TARGET = 17.0`、`TARGETED_DEVICE_FAMILY = 1`、`SWIFT_STRICT_CONCURRENCY = complete`
- `Camera.swift` を `videoRotationAngle` / `CameraConfiguration` に移行（iOS 17 で `videoOrientation` が非推奨のため）
- ローカル Swift Package `IrisEyeGlanceCore` を作成し、アプリにリンク

---

## 2. `refactor/detection-core` — 波形取得・判別パイプライン

### テスト
- `FaceMeshIndex`: 虹彩・瞼・鼻のインデックスが既存の番号と一致する
- `LandmarkNormalizer`: 既存の定数で x が正規化され y は変わらない
- `DepthEstimator`: 既存の `caluclateDepth` と同じ値を返す
- `LowPassFilter`: 初回値はそのまま、`reset()` で初期化される
- `IrisSignal`（旧 `EyeData`）: 2フレーム差分と鼻基準差分の計算
- `ThresholdProvider`: depth とパラメータから旧 `ikichiDecision` と同じ閾値を返す
- `BlinkDetector`: 両瞼が閾値を超えて4フレーム以内に戻ると `.blink` を発火、長すぎるとリセット
- `WinkDetector`: 左右差分波形の負→正ピーク対で `.wink(.left)`、逆で `.wink(.right)`
- `EyeGlanceDetector`: 下向き→上向き面積ペアで方向 1〜4 を返す
- `GestureArbiter`: 直前の入力からの不応期中は検出しない
- `KeyboardLayout` / `InputRegionResolver` / `TextComposer`: 領域番号と母音番号から文字を返す
- `CSVRecorder`: ヘッダと行の列数が一致し、初回行が失われない
- `Calibrator`: 13ステップの状態遷移と閾値算出

### 実装（パッケージ構成）
```
Packages/IrisEyeGlanceCore/Sources/IrisEyeGlanceCore/
  Landmarks/   FaceMeshIndex, LandmarkNormalizer, FaceFrame
  Features/    DepthEstimator, LowPassFilter, IrisSignal, EyeFeatures, EyeFeatureExtractor
  Detection/   DetectionParameters, ThresholdProvider, GestureEvent, GestureDetector,
               BlinkDetector, WinkDetector, EyeGlanceDetector, GestureArbiter, EyeInputPipeline
  Input/       KeyboardLayout, InputRegionResolver, TextComposer
  Calibration/ Calibrator
  Recording/   CSVRecorder
```
- `ViewController` はパイプラインを呼び出して結果を UI に反映するだけにする
- 旧 `Discrimination/`, `Threshold.swift`, `Initialization.swift`, `EyeData.swift`, `Depth.swift`,
  `NormalizedLandmark.swift`, `Calibration.swift` を削除

---

## 3. `refactor/ui` — 画面の操作性と UI

### テスト
- `InputPanelGeometry`: パネル矩形とプリセットからセル矩形を計算し、点からセルを返す
- `GestureFeedback`: ジェスチャ→表示記号・アクセシビリティ文言
- `CalibrationPresentation`: 各ステップの指示文と進捗率
- `DebugSnapshot`: 表示用フォーマット

### 実装
- `Main.storyboard` を削除し、`SceneDelegate` が `MainViewController` を生成。画面は Auto Layout のコードで構築
- `InputPanelView`（`InputPanelLayoutModel` からグリッドをコード描画、PNG アセット削除）、
  `GlanceHintView`（選択セルの4方向の文字）、`CursorOverlayView`（レイヤー1枚を再利用）、
  `DebugOverlayView`（ツールバーの Debug ボタンまたは長押しで表示切替）、
  `CalibrationOverlayView`（指示文・注視記号・進捗バー）、`InputStatusView`（出題・入力・ジェスチャ・正答率）
- `SettingsViewController` を `UIStackView` で再構築し、説明文と「既定値に戻す」を追加
- `Camera` は専用キューでフレームを配信し、`CameraPreviewView` の `AVCaptureVideoPreviewLayer` でプレビュー
- `TrackerBridge` がカメラとトラッカーのデリゲートをメインアクターの外で受ける
- ハプティクス生成器を再利用、`SceneDelegate` がバックグラウンドでカメラを停止・復帰
- 主要要素に `accessibilityLabel`、ラベルは Dynamic Type 対応
