# CircuRead

CircuRead 是一个用于传递早期研究笔记的命令行协议。笔记通过私有 GitHub 交换仓库送到评阅人手中；每次递交都有稳定的 UUID，并保留笔记、路由信息、评阅文件和带签名的 Git 历史。

[English](README.md) | [中文](README_CN.md)

> 当前状态：实验性项目。建议只在互相信任的研究小组内使用，个人想法仓库与交换仓库都应保持私有，并在导入后检查每一处改动。

## 已实现的功能

- `circuread new` 创建 LaTeX 笔记和元数据。
- `circuread deliver` 为每一组作者与评阅人创建或复用一个私有交换仓库。
- 每次递交保存在 `deliveries/<uuid>/`，多次递交共享同一条 Git 历史。
- `circuread review` 单独编辑 `review.tex`，并要求使用签名提交。
- `circuread fetch` 将反馈导入 `.circuread/reviews/`，不会覆盖原笔记。
- `circuread route` 安全地修改评阅人列表，不把用户输入拼进 `yq` 表达式。
- `circuread doctor` 检查依赖、GitHub 登录、签名配置与仓库配置。

Git 签名可以让后续篡改变得可检测，但不能让 GitHub 仓库在物理意义上不可修改。

## 依赖

- Bash 4 或更高版本
- Git
- 已通过 `gh auth login` 登录的 [GitHub CLI](https://cli.github.com/)
- [mikefarah/yq](https://github.com/mikefarah/yq) 4.x
- Git 签名密钥。Git 支持 GPG 或 SSH 签名。

先检查环境：

```bash
circuread doctor
```

## 安装

```bash
git clone https://github.com/tongmd/CircuRead.git
cd CircuRead
install -m 0755 circuread "$HOME/.local/bin/circuread"
```

请确认 `$HOME/.local/bin` 已加入 `PATH`。也可以一次完成 CLI 安装与私有想法仓库初始化：

```bash
./bootstrap.sh 你的_GITHUB_用户名 ideas 交换仓库组织名
```

交换仓库所在的 GitHub organization 需要允许你创建私有仓库并邀请 collaborator。

## 配置已有仓库

在私人想法仓库根目录创建 `.circuread.yml`：

```yaml
me: alice
exchange_org: research-exchange
upstreams:
  - bob
```

创建一则笔记：

```bash
circuread new notes/topological-qubits
```

编辑 `notes/topological-qubits/note.tex` 与对应元数据：

```yaml
title: Topological Qubits
writer: alice
readers: []
push_to:
  - bob
  - clara
```

先在私人仓库中提交原始笔记，再递交：

```bash
git add notes/topological-qubits
git commit -S -m "Draft topological-qubits"
circuread deliver notes/topological-qubits/note.tex
```

命令会打印本次递交的 ID：

```text
delivery_id=7da3b87d-5e14-4be0-b882-04bc92f26ad7
```

交换仓库使用 `<作者>__to__<评阅人>` 命名，并始终复用 `main` 分支，因此后续递交不会产生互不相关的 Git 历史。

## 评阅

评阅人接受 GitHub 邀请、克隆交换仓库，然后运行：

```bash
circuread review deliveries/7da3b87d-5e14-4be0-b882-04bc92f26ad7
```

CircuRead 会用 `EDITOR` 打开 `review.tex`，完成后创建签名提交并推送。

## 拉取反馈

作者回到私人想法仓库运行：

```bash
circuread fetch 7da3b87d-5e14-4be0-b882-04bc92f26ad7
# 或导入所有可访问的递交
circuread fetch --all
```

反馈会保存到：

```text
.circuread/reviews/<递交 UUID>/<评阅人>/
```

CircuRead 会创建本地签名提交，但不会自动推送。请先检查 diff，再自行执行 `git push`。

## 命令

| 命令 | 作用 |
| --- | --- |
| `doctor` | 检查环境与仓库配置 |
| `new <目录>` | 创建笔记，但不自动提交 |
| `deliver <note.tex>` | 生成 UUID，并把签名副本送给评阅人 |
| `review <递交目录>` | 编辑、签名并推送 `review.tex` |
| `fetch <uuid\|--all>` | 导入反馈，但不替换原笔记 |
| `route <meta> add\|remove <用户>` | 安全修改 `push_to` |
| `sync` | 为 `upstreams` 中的评阅人准备交换仓库 |

旧的 `fetch_edges.sh` 与 `manage_edges.sh` 仍然保留，分别转发到 `fetch --all` 与 `sync`。

## 递交目录

```text
作者__to__评阅人/
└── deliveries/
    └── <uuid>/
        ├── delivery.yml
        ├── note.meta.yml
        ├── note.tex
        └── review.tex
```

## 验证签名

```bash
git log --show-signature --decorate --oneline
```

信任签名前，应通过其他渠道核对作者的公钥指纹。仓库管理员仍然可以改写 Git 历史；如果审计非常重要，应保留独立克隆或启用分支保护。

## 开发

```bash
bash tests/test_cli.sh
bash tests/test_exchange.sh
shellcheck circuread bootstrap.sh fetch_edges.sh manage_edges.sh tests/*.sh
```

CI 会执行相同的语法、行为与 ShellCheck 检查。

## 许可证

MIT © 2025–2026 CircuRead contributors
