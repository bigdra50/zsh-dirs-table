#!/usr/bin/env zsh
# Runs every test_* function in tests/*.test.zsh, each in its own `zsh -f`.
emulate -L zsh
setopt extended_glob

local root=${0:A:h:h}

# ${(m)#s} needs a UTF-8 locale. CI images differ: Ubuntu has C.UTF-8,
# macOS has en_US.UTF-8 and often no LANG at all.
local -a utf8=(${(f)"$(locale -a 2>/dev/null)"})
utf8=(${(M)utf8:#*.(#i)utf(-|)8})
local loc
for loc in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8 $utf8; do
  (( ${utf8[(Ie)$loc]} )) && break
done
if [[ -z $loc || ${utf8[(Ie)$loc]} -eq 0 ]]; then
  print -u2 'no UTF-8 locale found'
  exit 1
fi
export LC_ALL=$loc

local -a files=(${@:-$root/tests/*.test.zsh})
local file name out
integer pass=0 fail=0
for file in $files; do
  for name in ${(f)"$(grep -oE '^test_[a-zA-Z0-9_]+' $file)"}; do
    out=$(zsh -f -c '
      source "$1/tests/helpers.zsh"
      source "$1/zsh-dirs-table.plugin.zsh"
      source "$2"
      setup
      # At top level: a trap set inside setup() would fire when setup returns.
      trap 'rm -rf -- "$TEST_TMP"' EXIT
      "$3"
    ' _ $root $file $name 2>&1)
    if (( $? == 0 )); then
      (( pass++ ))
      print -r -- "ok    ${file:t:r:r} $name"
    else
      (( fail++ ))
      print -r -- "FAIL  ${file:t:r:r} $name"
      print -rl -- "${(@)${(@f)out}/#/      }"
    fi
  done
done

print -r -- "$pass passed, $fail failed"
(( fail == 0 ))
