# zsh-dirs-table: show the directory stack as a table after pushd and popd.
# https://github.com/bigdra50/zsh-dirs-table

# $dirstack lives in zsh/parameter, which a plain `zsh -f` does not load.
zmodload -F zsh/parameter p:dirstack

# Helpers return through $REPLY instead of $(...) so a render forks nothing.

# Fit $1 into display width $2 by cutting from the left; the tail of a path
# carries the directory name, so that is the part to keep.
_dirs_table_fit() {
  local s=$1
  integer w=$2 used=1 cw i
  if (( ${(m)#s} <= w )); then
    REPLY=$s
    return
  fi
  REPLY=''
  for (( i = ${#s}; i > 0; i-- )); do
    cw=${(m)#s[i]}
    (( used + cw > w )) && break
    REPLY=$s[i]$REPLY
    (( used += cw ))
  done
  REPLY="…$REPLY"
}

# Pad $1 to display width $2 ($3: l, r or c). The SGR sequence $4 wraps only
# the text, so underlines or backgrounds never spill into the padding.
_dirs_table_cell() {
  integer gap=$(( $2 - ${(m)#1} )) left=0
  (( gap < 0 )) && gap=0
  case $3 in
    r) left=gap ;;
    c) left=gap/2 ;;
  esac
  local text=$1
  [[ -n $4 ]] && text=$4$1$'\e[0m'
  REPLY=${(l:left:: :)}$text${(l:gap-left:: :)}
}

_dirs_table_use_color() {
  local mode
  zstyle -s ':dirs-table:' color mode || mode=auto
  case $mode in
    always) return 0 ;;
    never) return 1 ;;
    *) [[ -t 1 && -z $NO_COLOR ]] ;;
  esac
}

dirs-table() {
  emulate -L zsh
  local usage='usage: dirs-table [-a]'
  integer all=0
  while (( $# )); do
    case $1 in
      -a) all=1 ;;
      -h|--help) print -r -- $usage; return 0 ;;
      *) print -ru2 -- "dirs-table: unknown option: $1"; print -ru2 -- $usage; return 2 ;;
    esac
    shift
  done

  local -a paths=("${(D)PWD}")
  local d
  for d in $dirstack; do paths+=("${(D)d}"); done

  local max
  zstyle -s ':dirs-table:' max-rows max
  [[ $max == <-> ]] || max=10
  integer shown=${#paths} rest=0
  if (( ! all && max > 0 && shown > max )); then
    rest=$(( shown - max ))
    shown=max
  fi
  local more=''
  (( rest )) && more="$rest more"

  local last=$(( shown - 1 ))
  integer iw=${#last} pw=4
  for d in ${paths[1,shown]} $more; do
    (( ${(m)#d} > pw )) && pw=${(m)#d}
  done
  # A row is "│ " + index + " │ " + path + " │": 7 columns of frame.
  integer room=$(( ${COLUMNS:-80} - iw - 7 ))
  # Below 4 the table can no longer fit; keep it intact and let it overflow.
  (( room < 4 )) && room=4
  (( pw > room )) && pw=room

  local hdr='' num='' cur='' dim=''
  if _dirs_table_use_color; then
    hdr=$'\e[1;32m' num=$'\e[1;32m' cur=$'\e[1m' dim=$'\e[2m'
  fi

  local bi=${(l:iw+2::─:)} bp=${(l:pw+2::─:)} idx
  print -r -- "╭${bi}┬${bp}╮"
  _dirs_table_cell '#' $iw c $hdr; idx=$REPLY
  _dirs_table_cell path $pw c $hdr
  print -r -- "│ ${idx} │ ${REPLY} │"
  print -r -- "├${bi}┼${bp}┤"

  integer i
  local style=$cur
  for (( i = 1; i <= shown; i++ )); do
    _dirs_table_cell $(( i - 1 )) $iw r $num; idx=$REPLY
    _dirs_table_fit "$paths[i]" $pw
    _dirs_table_cell "$REPLY" $pw l "$style"
    style=''
    print -r -- "│ ${idx} │ ${REPLY} │"
  done
  if (( rest )); then
    _dirs_table_cell '…' $iw r $dim; idx=$REPLY
    _dirs_table_cell "$more" $pw l $dim
    print -r -- "│ ${idx} │ ${REPLY} │"
  fi
  print -r -- "╰${bi}┴${bp}╯"
}

# True when the arguments ask the builtin to be quiet (-q, also inside
# combined flags such as -qP). Arguments after -- are directory names.
_dirs_table_quiet() {
  emulate -L zsh
  setopt extended_glob
  local a
  for a in "$@"; do
    [[ $a == -- ]] && return 1
    [[ $a == -[qsLP]## && $a == *q* ]] && return 0
  done
  return 1
}

_dirs_table_run() { # builtin args...
  # No emulate -L here: the builtin must see the user's pushd_ignore_dups,
  # pushd_minus, pushd_to_home and similar options.
  # local_options would also undo any option a chpwd hook sets during the
  # builtin, so only pushd_silent is saved and restored.
  integer was_silent=0 st
  [[ -o pushd_silent ]] && was_silent=1
  setopt pushd_silent
  builtin "$@"
  st=$?
  (( was_silent )) || unsetopt pushd_silent
  (( st )) && return st
  shift
  _dirs_table_quiet "$@" || dirs-table
}

pushd() { _dirs_table_run pushd "$@" }
popd() { _dirs_table_run popd "$@" }
