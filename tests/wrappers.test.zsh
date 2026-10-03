# pushd / popd wrappers

prepare_a_b() { # PWD=~/a, then pushd ~/b quietly: PWD=~/b, stack=(~/a)
  mkdir -p $HOME/a $HOME/b
  builtin cd $HOME/a
  builtin pushd -q $HOME/b
}

test_popd_prints_table_after_popping() {
  prepare_a_b
  popd > $HOME/out
  assert_eq $HOME/a $PWD
  assert_eq '╭───┬──────╮
│ # │ path │
├───┼──────┤
│ 0 │ ~/a  │
╰───┴──────╯' "$(<$HOME/out)"
}

test_popd_q_pops_without_output() {
  prepare_a_b
  popd -q > $HOME/out
  assert_eq $HOME/a $PWD
  assert_eq '' "$(<$HOME/out)"
}

test_popd_on_empty_stack_fails_without_table() {
  dirstack=()
  popd > $HOME/out 2> $HOME/err
  local st=$?
  (( st != 0 )) || fail 'expected non-zero status'
  assert_eq '' "$(<$HOME/out)"
  assert_contains "$(<$HOME/err)" 'directory stack empty'
}

test_pushd_prints_table_after_pushing() {
  mkdir -p $HOME/a $HOME/b
  builtin cd $HOME/a
  pushd $HOME/b > $HOME/out
  assert_eq $HOME/b $PWD
  local out=$(<$HOME/out)
  assert_contains "$out" '│ 0 │ ~/b  │'
  assert_contains "$out" '│ 1 │ ~/a  │'
}

test_pushd_with_combined_q_flag_prints_nothing() {
  mkdir -p $HOME/a $HOME/b
  builtin cd $HOME/a
  pushd -qP $HOME/b > $HOME/out
  assert_eq $HOME/b $PWD
  assert_eq '' "$(<$HOME/out)"
}

test_q_after_double_dash_is_a_directory_name() {
  mkdir -p -- $HOME/-q
  pushd -- -q > $HOME/out
  assert_eq $HOME/-q $PWD
  assert_contains "$(<$HOME/out)" '│ 0 │ ~/-q │'
}

test_pushd_to_missing_dir_fails_without_table() {
  pushd $HOME/missing > $HOME/out 2> /dev/null
  local st=$?
  (( st != 0 )) || fail 'expected non-zero status'
  assert_eq '' "$(<$HOME/out)"
}

test_wrappers_leave_pushd_silent_unset() {
  unsetopt pushd_silent
  prepare_a_b
  pushd $HOME/a > /dev/null
  popd > /dev/null
  [[ -o pushd_silent ]] && fail 'pushd_silent was left set'
  return 0
}

test_wrappers_leave_pushd_silent_set() {
  setopt pushd_silent
  prepare_a_b
  popd > /dev/null
  [[ -o pushd_silent ]] || fail 'pushd_silent was unset'
}

test_wrappers_keep_users_pushd_options() {
  setopt pushd_ignore_dups
  mkdir -p $HOME/a $HOME/b
  builtin cd $HOME/a
  pushd $HOME/b > /dev/null
  pushd $HOME/a > /dev/null
  assert_eq 1 ${#dirstack}
}

test_wrappers_run_chpwd_hooks() {
  mkdir -p $HOME/b
  record_chpwd() { print -r -- $PWD >> $HOME/hook }
  chpwd_functions+=(record_chpwd)
  pushd $HOME/b > /dev/null
  popd > /dev/null
  assert_eq "$HOME/b"$'\n'"$HOME" "$(<$HOME/hook)"
}
