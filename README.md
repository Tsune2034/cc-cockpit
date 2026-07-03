# cc-cockpit

Claude Code用のstatusLineスクリプト。5時間/7日間のレート制限使用率と、コンテキストウィンドウ使用率を、色付きのゲージバーで表示します。

```
MAX  Opus  5h:███░░░░░  23%(21:30)  7d:██████░░  85%(7/6 6:00)  ctx:███░░░░░  45%
```

- 緑（〜49%）→ 黄（50〜79%）→ 赤（80%〜）で使用率を色分け
- 依存はPOSIX sh + `jq` のみ
- Claude Codeが渡すネイティブの `rate_limits` / `context_window` 値をそのまま使用（独自の推定計算は行わない）

## セットアップ

```sh
git clone https://github.com/Tsune2034/cc-cockpit.git
chmod +x cc-cockpit/cc-cockpit.sh
```

`~/.claude/settings.json` の `statusLine` に設定：

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh /path/to/cc-cockpit/cc-cockpit.sh"
  }
}
```

## 動作確認

```sh
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":45}}' | ./cc-cockpit.sh
```

## 謝辞

コンセプトは [claude-hud](https://github.com/jarrodwatts/claude-hud) を参考にしています（ソースコードの流用はなく、独立実装です）。

## License

MIT
