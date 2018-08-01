#!/bin/bash

Semver::validate() {
  # shellcheck disable=SC2064
  trap "$(shopt -p extglob)" RETURN
  shopt -s extglob

  declare normal=${1%%[+-]*}
  declare extra=${1:${#normal}}

  declare major=${normal%%.*}
  if [[ $major != +([0-9]) ]]; then echo "Semver::validate: invalid major: $major" >&2; return 1; fi
  normal=${normal:${#major}+1}
  declare minor=${normal%%.*}
  if [[ $minor != +([0-9]) ]]; then echo "Semver::validate: invalid minor: $minor" >&2; return 1; fi
  declare patch=${normal:${#minor}+1}
  if [[ $patch != +([0-9]) ]]; then echo "Semver::validate: invalid patch: $patch" >&2; return 1; fi

  declare -r ident="+([0-9A-Za-z-])"
  declare pre=${extra%%+*}
  declare pre_len=${#pre}
  if [[ $pre_len -gt 0 ]]; then
    pre=${pre#-}
    if [[ $pre != $ident*(.$ident) ]]; then echo "Semver::validate: invalid pre-release: $pre" >&2; return 1; fi
  fi
  declare build=${extra:pre_len}
  if [[ ${#build} -gt 0 ]]; then
    build=${build#+}
    if [[ $build != $ident*(.$ident) ]]; then echo "Semver::validate: invalid build metadata: $build" >&2; return 1; fi
  fi

  if [[ $2 ]]; then
    echo "$2=(${major@Q} ${minor@Q} ${patch@Q} ${pre@Q} ${build@Q})"
  else
    echo "$1"
  fi
}

Semver::compare() {
  declare -a x y
  eval "$(Semver::validate "$1" x)"
  eval "$(Semver::validate "$2" y)"

  declare x_i y_i i
  for i in 0 1 2; do
    x_i=${x[i]}; y_i=${y[i]}
    if [[ $x_i -eq $y_i ]]; then continue; fi
    if [[ $x_i -gt $y_i ]]; then echo 1; return; fi
    if [[ $x_i -lt $y_i ]]; then echo -1; return; fi
  done

  x_i=${x[3]}; y_i=${y[3]}
  if [[ -z $x_i && $y_i ]]; then echo 1; return; fi
  if [[ $x_i && -z $y_i ]]; then echo -1; return; fi

  declare -a x_pre; declare x_len
  declare -a y_pre; declare y_len
  IFS=. read -ra x_pre <<< "$x_i"; x_len=${#x_pre[@]}
  IFS=. read -ra y_pre <<< "$y_i"; y_len=${#y_pre[@]}

  if (( x_len > y_len )); then echo 1; return; fi
  if (( x_len < y_len )); then echo -1; return; fi

  for (( i=0; i < x_len; i++ )); do
    x_i=${x_pre[i]}; y_i=${y_pre[i]}
    if [[ $x_i = "$y_i" ]]; then continue; fi

    declare num_x num_y
    num_x=$([[ $x_i = +([0-9]) ]] && echo "$x_i")
    num_y=$([[ $y_i = +([0-9]) ]] && echo "$y_i")
    if [[ $num_x && $num_y ]]; then
      if [[ $x_i -gt $y_i ]]; then echo 1; return; fi
      if [[ $x_i -lt $y_i ]]; then echo -1; return; fi
    else
      if [[ $num_y ]]; then echo 1; return; fi
      if [[ $num_x ]]; then echo -1; return; fi
      if [[ $x_i > $y_i ]]; then echo 1; return; fi
      if [[ $x_i < $y_i ]]; then echo -1; return; fi
    fi
  done

  echo 0
}

Semver::is_prerelease() {
  declare -a ver; eval "$(Semver::validate "$1" ver)"
  [[ ${ver[3]} ]] && echo yes || echo no
}

Semver::pretty() {
  declare out="$1.$2.$3"
  [[ $4 ]] && out+="-$4"
  [[ $5 ]] && out+="+$5"
  echo "$out"
}

Semver::increment_major() {
  declare -a ver; eval "$(Semver::validate "$1" ver)"
  echo "$((ver[0]+1)).0.0"
}

Semver::increment_minor() {
  declare -a ver; eval "$(Semver::validate "$1" ver)"
  echo "${ver[0]}.$((ver[1]+1)).0"
}

Semver::increment_patch() {
  declare -a ver; eval "$(Semver::validate "$1" ver)"
  echo "${ver[0]}.${ver[1]}.$((ver[2]+1))"
}

Semver::set_pre() {
  declare -r ident="+([0-9A-Za-z-])"
  if [[ $2 != ?($ident*(.$ident)) ]]; then echo "Semver::set_pre: invalid pre-release: $2" >&2; return 1; fi
  declare -a ver; eval "$(Semver::validate "$1" ver)"
  Semver::pretty "${ver[0]}" "${ver[1]}" "${ver[2]}" "$2" "${ver[4]}"
}

Semver::set_build() {
  declare -r ident="+([0-9A-Za-z-])"
  if [[ $2 != ?($ident*(.$ident)) ]]; then echo "Semver::set_build: invalid build metadata: $2" >&2; return 1; fi
  declare -a ver; eval "$(Semver::validate "$1" ver)"
  Semver::pretty "${ver[0]}" "${ver[1]}" "${ver[2]}" "${ver[3]}" "$2"
}
