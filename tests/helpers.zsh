# Test helpers. Each test runs in a fresh `zsh -f`, so state never leaks.

setup() {
  TEST_TMP=$(mktemp -d)
  # Resolve symlinks (macOS /var -> /private/var) so $PWD matches what we build.
  TEST_TMP=${TEST_TMP:A}
  export HOME=$TEST_TMP/home
  mkdir -p $HOME
  builtin cd $HOME
  COLUMNS=80
}

fail() {
  print -r -- "$*"
  exit 1
}

assert_eq() { # expected actual
  [[ $1 == $2 ]] && return
  print -r -- '--- expected'
  print -r -- "$1"
  print -r -- '--- actual'
  print -r -- "$2"
  exit 1
}

assert_contains() { # haystack needle
  [[ $1 == *"$2"* ]] || fail "expected to contain: $2"$'\n'"in:"$'\n'"$1"
}

assert_not_contains() { # haystack needle
  [[ $1 != *"$2"* ]] || fail "expected not to contain: $2"$'\n'"in:"$'\n'"$1"
}

# Every line has the same display width (full-width chars count as 2).
assert_aligned() { # text
  local -a lines=("${(@f)1}")
  local line w=${(m)#lines[1]}
  for line in $lines; do
    (( ${(m)#line} == w )) || fail "misaligned ($w vs ${(m)#line}): $line"$'\n'"$1"
  done
}

# Number of table rows whose index column holds a number.
count_rows() { # text
  setopt local_options extended_glob
  local -a rows=(${(M)${(@f)1}:#│ #[0-9]## │*})
  print -r -- ${#rows}
}
