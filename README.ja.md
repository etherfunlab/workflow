# etherfunlab/workflow

**AI agent で開発するための教科書**

まず心得を説き、続いて心得から導いた規則と道具を渡します。

EtherFun Lab が、engineering の素養がある読者に向けて書きました。agent で開発する人、入門したばかりの vibe coder、若手の開発者、そして将来の同僚です。

他の言語：[README.md](README.md)（简体中文 · English）、[README.zh.md](README.zh.md)、[README.de.md](README.de.md)

## 使い方

次の一文を agent に送ってください：

```
https://github.com/etherfunlab/workflow を読んで、ADOPT.md に従って私の project に組み込んでください。
```

- **新規 project**：agent がどの module と雛形を使うか尋ね、変更一覧を挙げます。あなたが了承すると、まず `templates/base/` を敷き、選んだ雛形を重ね、そのあと module を導入します。
- **既存 project**：agent はまず、既存の CLAUDE.md、AGENTS.md、`.claude/`、git hook をすべて読みます。そのうえで、どの module と雛形を使うか、規則を中国語と英語のどちらにするか、skill を project 単位と user 単位のどちらに入れるか（module が skill を導入する場合のみ尋ねます）、任意の hook を入れるかを尋ねます。着手前に、変更するすべての file を一覧にして見せます。repo にすでにある同じ内容の規則は飛ばし、衝突する規則はあなたが選びます。
- **repo の外の規則**：新規でも既存でも同じです。agent は user 単位と親 directory の規則 file を読みます。ある規則がそこにしかなければ、飛ばすかそれでも導入するかを尋ねます。飛ばした場合、他の人がこの repo を clone したとき、あるいは端末や agent を替えたとき、その規則はありません。
- **更新**：導入後、repo に `.workflow.lock` ができ、導入した module と、対応する上流の commit が記録されます。この repo をもう一度 agent に渡すと、その commit から最新版までの上流の変更を拾い出し、module ごとに説明してくれます。あなたが了承した分だけ merge します。

Claude Code でしか使えない部分（hook、`.claude/rules/` の path 別の規則）は個別に明記してあります。Codex など他の agent は hook を飛ばし、path 別の規則は AGENTS.md に書き込みます。

## 能動的な雑音低減

多くの素人 vibe coder には、ある能力が欠けています。能動的な雑音低減、熱力学のたとえで言えば entropy を減らす力です。AI の出力を正す判断力がないまま、agent に一つの作業を延々と走らせ続ければ、context はいずれ雑音に埋もれます。

この repo は Claude の Constitutional AI の考え方に倣っています。先に原則を立て、理由を説明し、具体的な規則は原則から導きます。「心得早見表」の九か条が、ここでの原則です。

> 出典：Anthropic、[Claude's new constitution](https://www.anthropic.com/news/claude-new-constitution)（2026-01-22）。全文は [Claude's Constitution](https://www.anthropic.com/constitution)、手法の出典は [Constitutional AI: Harmlessness from AI Feedback](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback)（2022）。

## 規律

規律は広く認められた engineering の実践なので、そのまま従えば十分です。一つ目の表は [root directory の CLAUDE.md 雛形](templates/dev-root/README.en.md)の内容で、各 repo の一つ上の directory に置き、配下のすべての repo に効きます。二つ目の表は [engineering module](modules/engineering/README.en.md) が各 repo に導入するものです。

**repo 横断の規律**：

| 事実 | 一言で |
|---|---|
| 本番への経路は一つ、分析系の repo は読み取り専用 | どの repo も本番を調べるときは、用意済みの command を一つだけ通す。監査・報告・会計系の repo は読み取りのみで、製品を作る repo は参照も変更もできる。生の行は terminal にも報告にも出さず、集計は手元で行う |
| 公開 repo の対外規律 | 公開 repo の issue や PR に、非公開 repo 名・内部名称・本番の URL を出さない。実測の証拠は匿名化して示す |
| PR は一度に一つ | PR を並行させると内容が絡み合い、衝突解消の負担は人に回る。新しい PR を拒まれたら、止まって確認する |
| 数字に期間を付け、deploy で区切る | 報告の数字には必ず集計期間を明記する。deploy 一回が一つの era で、era をまたぐ数値は混ぜて計算しない |
| 呼び出し課金の API は一巡で止まる | 呼び出しごとに課金される外部 API は、自動で何巡も反復しない。再試行は同じ呼び出しの一時的な障害に限る |
| 見た目の判定は人間 | 見た目・組版・文面の調子に自動 assertion は書かない。候補を三つほどまとめて並べ、人が選ぶのを待って止まる。止まるのが正しい終点 |
| 調べてから聞く | bug 報告を受けたら、現象を復唱して確認を求めず、code と log から原因を探す。証拠が分岐するときだけ尋ね、尋ねるときは選択肢を付ける |
| commit の作法 | commit は英語の Conventional Commits。`.env` と secrets は絶対に commit しない。agent の shell は状態を持たないので、`conda run` のような単発の呼び出しを使い、activate は使わない |

**repo 内の engineering 姿勢**：

| 事実 | 一言で |
|---|---|
| KISS | 似た code が三箇所あるほうが、早すぎる抽象化より良い。まだ現れていない要求のために拡張点を残さない |
| 事実ごとに正本は一つ | 数値・状態・判定条件はそれぞれ一箇所に定め、残りはすべて派生させる |
| schema と API は source だけを正とする | schema は migration file、API は code を正とし、文書に副本を持たない |
| API は足す前に再利用 | API を足す前に、まず既存のものを探す。frontend と backend のどちらに置くか迷ったら、先に聞く |
| 調整で誤りは減らしても、零は追わない | 零に近づけようとするのは、この corpus の雑音に合わせ込むこと。指標が横ばいなのは課題ではない |
| branch でなく release を見る | 本番でどの版が動いているかは release 一覧で確認する。deploy の前に、rollback の経路を決めておく |
| regression は失敗集合で比べる | 失敗した test case の名前の集合を見る。件数は見ない |
| 契約が先 | 実装の前に API の契約を宣言する。生成された API 文書は成果物であり、正本ではない |
| foreign key は table 作成時に決める | 参照列には、その列を作る migration で foreign key を付ける。NULL 可否と ON DELETE は一緒に決める。すべての foreign key に index を付ける |
| 消すなら跡形もなく | 削除した code・設定・文書は、元の場所に墓標を残さない。説明が要るなら commit message に書く。changelog・migration・runbook は変更を通常どおり記録する。削除後に実際に戻されたものだけ、「再追加禁止：X、理由 Y」の一行を残す |

もう一つ、広く合意されたものではなく私たち独自の主張である規則があり、同じ engineering module で導入されます：**先に開けて、あとで絞る**。範囲・能力・権限はまず開放して走らせ、実際の上限と使われ方を見極めてから絞ります。絞るのは閾値（条件・段階・冷却期間・費用）であって、能力を取り外すことではありません。実測済みの fallback がないうちは、先回りして絞りません。開放する段階では、必ず計測値を残します。

## 心得早見表

| 心得 | 一言で |
|---|---|
| 制約が先 | まず枝刈り：design → spec → plan → impl。要求が明確なほど、上が歪んで下まで歪むことが減る |
| code が王様 | source code は agent にとって最高の説明書。code を「人間に読みやすい」形式に潰さない |
| repo 管理 | Git repo がそのまま memory と context の置き場。memory の同期は `.memory/` と hook 一つで足りる |
| 下手なら練習 | これらの判断は AI に代替できない。AI に教わってもよいが、地道に学ぶ |
| 正本は一つ | 権威文書は一か所にだけ置き、agent がどこを読むべきかを memory に書いておく |
| CLI が CLI を呼ぶ | Claude Code が運転席に座り、gh、codex、DB の CLI、fly を呼ぶ |
| API に目を光らせる | Claude Code はうっかり API を作る。memory で再利用を促し、人も見張る |
| まず壁打ち | 要件が固まらないときは、まず Web 版 LLM と議論して prompt を作り、それから brainstorming を走らせる |
| repo 間は issue で | repo をまたぐ問題は、agent が issue を立て、別の agent が読む |

## 各条の詳説

### 制約が先

枝刈りです。design → spec → plan → impl の流れは、常に守ります。要求を明確に出し、spec を詳細に書くほど、上が歪んで下まで歪むことが減ります。

### code が王様

source code は、agent に渡せる最高の説明書です。JSON や HTML の「code の可視化」を盲信してはいけません。agent はあなたよりずっとうまく code を読みます。人に分かるようにと code を「人間が読みやすい」形式に圧縮すると、かえって agent を誤らせます。

### repo 管理

Git repo は、memory と context の置き場として最高のものです。commit と PR の仕組みは、人間のチームの作業を助けるだけでなく、agent のチームをまとめるのにも向いています。memory を同期したいなら、repo 直下に `.memory/` を作り、post-hook を足すだけで済みます。別途 memory を管理する仕組みは要りません。

### 下手なら練習

言語の選択（Python、TS、Go、Rust）、architecture の選択（Vue、Flutter）、deploy の流れ（Docker、K8s）、design の規範、iteration の原則、作業の流れ（要件 → schema → API 契約 → backend → frontend → E2E MVP）、network 障害の切り分け、command line、外国語を読む力。これらの「判断」は AI に代替できません（ただし AI に教わることはできます）。地道に学んでください。情報 entropy を減らす見かけ倒しの小技を盲信してはいけません。

### 正本は一つ

権威文書は一か所にだけ置き、さらに memory に書いて、agent にどこを読むべきかを教えておきます。私は最初、spec、plan、milestone、schema、API をすべて入れた文書 repo を作りました。ところが、field の定義があちこちに散らばりました。文書 repo にあるもの、code にあるもの、各 project の repo 自身の `docs/` にあるもの。そこで次のように決めました。文書 repo に置くのは project 全体の overall spec と人が読むための文書だけ、spec は各 project 自身の `docs/superpowers/` に置く、schema 定義の正は `migration/*.sql` だけ、API 定義の正は code だけです。agent にまとめさせた Rust の用語対照表は、人が読むための文書にあたり、agent が Rust を書くときに何をしたのかを私が読み解く助けになります。

### CLI が CLI を呼ぶ

CLI 同士は互いに呼び出せます。たとえば Claude Code が運転席に座り、gh を呼んで PR と merge を管理し、codex を呼んで code を review させ、`supabase db query --linked` を呼んで DB を参照・更新し、fly を呼んで server の log を見る、といった具合です。

### API に目を光らせる

Claude Code は、うっかり新しい API を作ってしまうことがあります。既存の API を再利用するよう memory に書いておくだけでなく、自分でも気を配ってください。project が大きくなると、ある処理は frontend の middleware で確認すべきで、別の処理は backend の API が提供すべきになります。そのどちらをあなたが望んでいるのか、Claude Code が常に言い当てられるとは限りません。

### まず壁打ち

要件をどう実装するか決めかねるときは、superpowers や gstack のような skill を使うほかに、まず Web 版の LLM（ChatGPT、Grok など）と議論して prompt を作らせ、それを Claude Code に渡して brainstorming を走らせる手があります。素の言葉でいきなり詠唱するより、こちらのほうがずっと強いです。

### repo 間は issue で

GitHub の issue は本当に便利です。いまは repo をまたぐ問題が出ると、agent に issue を立てさせ、別の agent に読ませています。人間向けに設計された協働の仕組みは、agent が使ってもまったく同じようによく効きますし、私も追跡できます。

## 心得を落とし込んだ実践

| module | 解決すること | repo に導入されるもの |
|---|---|---|
| [writing](modules/writing/README.en.md) | 文章の規範、用語の規範、中国語の組版、文書単位の執筆憲法 | `.claude/rules/writing.md`（他の agent：AGENTS.md の一節）＋ repo 直下の `WRITING.md` |
| [checkup](modules/checkup/README.en.md) | 規則 file の定期点検 | skill `rules-checkup`、任意の更新通知 hook（Claude Code のみ） |
| [rules-files](modules/rules-files/README.en.md) | CLAUDE.md / AGENTS.md の書き方 | `.claude/rules/rules-files.md`（他の agent：AGENTS.md の一節） |
| [engineering](modules/engineering/README.en.md) | engineering の姿勢 | AGENTS.md の一節 |
| [carriers](modules/carriers/README.en.md) | 各文をどこに書くか | AGENTS.md の一節 |
| [memory](modules/memory/README.en.md) | agent の memory を repo に写す | AGENTS.md の一節、`.memory/README.md`、`.githooks/`、同期 hook（Claude Code のみ） |
| [review](modules/review/README.en.md) | 別の model 系列による code review | skill `codex-review` |
| [publish](modules/publish/README.en.md) | 成稿の仕上げ三工程 | skill `doc-publish`、`doc-fact-check`、`doc-polish`、`doc-review`、`precheck.sh` |
| [repo の雛形](#repo-の雛形) + [ADOPT](ADOPT.md) | project の骨組みと組み込みの手順 | 次の節を参照。加えて `.workflow.lock` |

## repo の雛形

新しい project は必ず先に `base` を敷き、その上に project の種類に応じた雛形を一つ重ねます。既存 project は、重ねる層だけを取り入れることもできます。

| 雛形 | 対象 | repo に導入されるもの |
|---|---|---|
| `base` | すべての新規 project | 索引型の AGENTS.md、`@AGENTS.md` の一行だけが入った CLAUDE.md、`docs/superpowers/` |
| [frontend](templates/frontend/README.en.md) | frontend の project | `DESIGN.md`、`FONTS.md`、`GRID.md`、`LOCALE.md`、`RELEASE.md`、AGENTS.md に merge される一節 |
| [dev-root](templates/dev-root/README.en.md) | 複数の repo を束ねる親 directory | 親 directory の CLAUDE.md（repo 横断の規律。自動で読み込まれるのは Claude Code のみ） |

## 補足 skill

EtherFun Lab が project を進める中で溜めた skill をいくつか、[`skills/`](skills/) に置いています。組み込みの際、agent はそれらを別枠で挙げるので、必要なものだけ導入してください。

| skill | 解決すること | 対象 |
|---|---|---|
| [zh-hant-converter](skills/zh-hant-converter/README.en.md) | 簡体字から繁体字への変換：内部向けは字形だけ、対外向けは語彙もまとめて置き換える | 深圳と香港にまたがるチーム |
| [ios-keyboard-page-shift](skills/ios-keyboard-page-shift/README.en.md) | iPhone で keyboard を閉じたあと画面が元に戻らない：まず層を切り分け、それから直す | mobile 向け Web page を作るチーム |
| [macos-disk-cleanup](skills/macos-disk-cleanup/README.en.md) | Mac の disk が満杯に近い：build 成果物と cache を、消してよいか一つずつ確認してから消す | Mac で開発する人 |

## 依存する上流

- [superpowers](https://github.com/obra/superpowers)：brainstorming → spec → plan → 実装の流れ
- [gstack](https://github.com/garrytan/gstack)：もう一つの Claude Code 向け skill 集
- [human-writing](https://github.com/Tao716/human-writing-skill)：中国語の推敲
- [humanizer](https://github.com/blader/humanizer)：英語の推敲
- [codex CLI](https://github.com/openai/codex)：review module
- [OpenCC](https://github.com/BYVoid/OpenCC)：zh-hant-converter

## License

MIT。[LICENSE](LICENSE) を参照してください。
