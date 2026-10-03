# zsh-dirs-table

Show the zsh directory stack as a table after `pushd` and `popd`.

```
❯ popd
╭───┬──────────────────────────────────────────────────────────────────────╮
│ # │                                 path                                 │
├───┼──────────────────────────────────────────────────────────────────────┤
│ 0 │ ~/src/github.com/you/dotfiles                                        │
│ 1 │ ~/src/github.com/you/zsh-dirs-table                                  │
│ 2 │ …/github.com/you/notes/2026-07-31/コードレビュー支援ツールの運用設計 │
│ 3 │ /usr/local/share/zsh/site-functions                                  │
│ 4 │ …/github.com/someone/monorepo/packages/frontend/src/components/forms │
│ 5 │ ~/Downloads                                                          │
│ 6 │ /tmp                                                                 │
│ 7 │ ~/src/github.com/you                                                 │
│ 8 │ ~/.config/zsh                                                        │
│ 9 │ ~/src/github.com/you/blog/content/posts                              │
│ … │ 4 more                                                               │
╰───┴──────────────────────────────────────────────────────────────────────╯
```

By default zsh prints the whole stack on one line after `pushd` and `popd`.
With `auto_pushd` and a long history, that line wraps across the screen and has no indices.
This plugin replaces that line with a numbered table.

- Row `0` is the current directory and is shown in bold
- The `#` column matches `dirs -v`, so `cd ~3` goes to row 3
- Paths use `~` and named directories (`hash -d`)
- Paths wider than the terminal are cut from the left with `…`
- Full-width characters count as two columns, so CJK paths stay aligned

The table style is inspired by the `dirs` command in Nushell's standard library.

## Install

### sheldon

```toml
[plugins.zsh-dirs-table]
github = "bigdra50/zsh-dirs-table"
```

### zinit

```zsh
zinit light bigdra50/zsh-dirs-table
```

### Oh My Zsh

```zsh
git clone https://github.com/bigdra50/zsh-dirs-table \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-dirs-table
```

Then add `zsh-dirs-table` to `plugins=(...)` in `~/.zshrc`.

### Manual

```zsh
source /path/to/zsh-dirs-table/zsh-dirs-table.plugin.zsh
```

## Usage

| Command | Output |
| --- | --- |
| `pushd ...` / `popd ...` | Runs the builtin, then prints the table if it succeeded |
| `pushd -q ...` / `popd -q ...` | Runs the builtin quietly and prints nothing, like the builtin |
| `dirs-table` | Prints the table without changing directory |
| `dirs-table -a` | Prints every entry, ignoring `max-rows` |

When the stack has more entries than `max-rows`, the last row shows how many were left out, as in the example at the top.

## Configuration

```zsh
# Rows to show, including row 0. 0 means no limit. Default: 10
zstyle ':dirs-table:*' max-rows 10

# auto: color only when stdout is a terminal and NO_COLOR is unset (default)
# always: color even when piped or when NO_COLOR is set
# never: no color
zstyle ':dirs-table:*' color auto
```

## Behavior notes

- The builtin `dirs` is not changed, so scripts that read its output keep working
- The `pushd` and `popd` wrappers set `pushd_silent` only while they run; your own option is left as it is
- Other options such as `pushd_ignore_dups`, `pushd_minus` and `pushd_to_home` apply as usual
- `cd` with `auto_pushd` prints nothing, as before
- Box-drawing characters and `…` are East Asian Ambiguous width; a terminal set to treat them as wide will misalign the table

## Development

```zsh
zsh tests/run.zsh
```

Tests run each case in `zsh -f` with a temporary `HOME`.
There is no linter for zsh (ShellCheck does not support it), so CI checks syntax with `zsh -n` and runs the tests on Ubuntu and macOS.

## License

[MIT](LICENSE)
