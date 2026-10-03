# dirs-table: rendering

tty_output() { # command line, run with stdout attached to a pseudo terminal
  zmodload zsh/zpty
  # The end marker keeps `zpty -r` from blocking forever when $1 prints no table.
  zpty dt_tty "$1; print -r -- __DT_END__"
  local out
  zpty -r dt_tty out '*__DT_END__*'
  zpty -d dt_tty
  out=${out//$'\r'/}
  print -r -- "${out%__DT_END__*}"
}

test_renders_current_dir_and_stack() {
  mkdir -p $HOME/a; builtin cd $HOME/a
  dirstack=($HOME/b $HOME)
  assert_eq '╭───┬──────╮
│ # │ path │
├───┼──────┤
│ 0 │ ~/a  │
│ 1 │ ~/b  │
│ 2 │ ~    │
╰───┴──────╯' "$(dirs-table)"
}

test_uses_named_directories() {
  mkdir -p $HOME/work/projects/app
  hash -d proj=$HOME/work/projects
  builtin cd $HOME/work/projects/app
  dirstack=()
  assert_contains "$(dirs-table)" '│ 0 │ ~proj/app │'
}

test_aligns_full_width_characters() {
  mkdir -p $HOME/日本語のディレクトリ
  builtin cd $HOME/日本語のディレクトリ
  dirstack=($HOME $HOME/ascii-only-directory)
  local out=$(dirs-table)
  assert_aligned "$out"
  assert_contains "$out" '│ 0 │ ~/日本語のディレクトリ │'
}

test_keeps_paths_with_spaces_on_one_row() {
  mkdir -p "$HOME/Obsidian Vault"
  builtin cd "$HOME/Obsidian Vault"
  dirstack=($HOME)
  local out=$(dirs-table)
  assert_eq 2 $(count_rows "$out")
  assert_contains "$out" '│ 0 │ ~/Obsidian Vault │'
}

test_cuts_long_paths_from_the_left_to_fit_columns() {
  COLUMNS=30
  dirstack=($HOME/aaaaaaaaaa/bbbbbbbbbb/cccccccccc/target)
  local out=$(dirs-table)
  assert_aligned "$out"
  assert_eq 30 ${(m)#${${(@f)out}[1]}}
  assert_contains "$out" '│ 1 │ …bbb/cccccccccc/target │'
  assert_contains "$out" '│ 0 │ ~                      │'
}

test_keeps_working_when_columns_is_too_small() {
  COLUMNS=5
  dirstack=($HOME/aaaaaaaaaa/target)
  local out
  out=$(dirs-table) || fail "exit status $?"
  assert_aligned "$out"
  assert_contains "$out" '│ 0 │'
}

test_limits_rows_to_ten_and_reports_the_rest() {
  dirstack=($HOME/d{1..14})
  assert_eq '╭───┬────────╮
│ # │  path  │
├───┼────────┤
│ 0 │ ~      │
│ 1 │ ~/d1   │
│ 2 │ ~/d2   │
│ 3 │ ~/d3   │
│ 4 │ ~/d4   │
│ 5 │ ~/d5   │
│ 6 │ ~/d6   │
│ 7 │ ~/d7   │
│ 8 │ ~/d8   │
│ 9 │ ~/d9   │
│ … │ 5 more │
╰───┴────────╯' "$(dirs-table)"
}

test_max_rows_zstyle_sets_the_limit() {
  zstyle ':dirs-table:*' max-rows 3
  dirstack=($HOME/d{1..14})
  local out=$(dirs-table)
  assert_eq 3 $(count_rows "$out")
  assert_contains "$out" '│ … │ 12 more │'
}

test_max_rows_zero_means_no_limit() {
  zstyle ':dirs-table:*' max-rows 0
  dirstack=($HOME/d{1..14})
  local out=$(dirs-table)
  assert_eq 15 $(count_rows "$out")
  assert_not_contains "$out" 'more'
  assert_contains "$out" '│  0 │ ~     │'
  assert_contains "$out" '│ 14 │ ~/d14 │'
}

test_invalid_max_rows_falls_back_to_ten() {
  zstyle ':dirs-table:*' max-rows lots
  dirstack=($HOME/d{1..14})
  assert_eq 10 $(count_rows "$(dirs-table)")
}

test_all_flag_ignores_max_rows() {
  dirstack=($HOME/d{1..14})
  local out=$(dirs-table -a)
  assert_eq 15 $(count_rows "$out")
  assert_not_contains "$out" 'more'
}

test_unknown_option_fails_with_usage() {
  local err
  err=$(dirs-table -x 2>&1 >/dev/null)
  assert_eq 2 $?
  assert_contains "$err" 'usage: dirs-table [-a]'
}

test_does_not_change_directory_or_stack() {
  dirstack=($HOME/d1 $HOME/d2)
  dirs-table >/dev/null
  assert_eq $HOME $PWD
  assert_eq "$HOME/d1 $HOME/d2" "$dirstack"
}

test_no_color_when_piped_by_default() {
  dirstack=($HOME/b)
  assert_not_contains "$(dirs-table)" $'\e['
}

test_color_always_marks_header_index_and_current_row() {
  zstyle ':dirs-table:*' color always
  dirstack=($HOME/b)
  local out=$(dirs-table)
  assert_contains "$out" $'\e[1;32m#\e[0m'
  assert_contains "$out" $'│ \e[1;32m0\e[0m │ \e[1m~\e[0m'
  assert_contains "$out" $'│ \e[1;32m1\e[0m │ ~/b'
}

test_color_always_overrides_no_color() {
  zstyle ':dirs-table:*' color always
  NO_COLOR=1
  assert_contains "$(dirs-table)" $'\e['
}

test_color_auto_uses_color_on_a_terminal() {
  dirstack=($HOME/b)
  assert_contains "$(tty_output dirs-table)" $'\e[1;32m#\e[0m'
}

test_color_auto_respects_no_color_on_a_terminal() {
  export NO_COLOR=1
  assert_not_contains "$(tty_output dirs-table)" $'\e['
}

test_color_never_disables_color_on_a_terminal() {
  zstyle ':dirs-table:*' color never
  assert_not_contains "$(tty_output dirs-table)" $'\e['
}
