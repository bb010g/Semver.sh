#!/bin/bash

_valid() {
  echo "${1@Q}"
  local out
  out=$(Semver::validate "$1" out 2>&1)
  local ret=$?
  if [[ $ret -eq 0 ]]; then
    eval "$out"
    assertEquals "major" "$2" "${out[0]}"
    assertEquals "minor" "$3" "${out[1]}"
    assertEquals "patch" "$4" "${out[2]}"
    assertEquals "pre" "$5" "${out[3]}"
    assertEquals "build" "$6" "${out[4]}"
  else
    if [[ $out != Semver::validate:\ * ]]; then
      failNotEquals 'erroring function' 'Semver::validate' "${out%%:*}" 
    else
      out=${out#Semver::validate: }
      fail "error $ret unexpected:<$out>"
    fi
  fi
}
_invalid() {
  echo "${1@Q} -> ${2@Q}"
  local out
  out=$(Semver::validate "$1" out 2>&1)
  local ret=$?
  if [[ $ret -ne 1 ]]; then
    failNotEquals 'error code' 1 $ret
    fail "parse:<${out#out=}>"
  else
    if [[ $out != Semver::validate:\ * ]]; then
      failNotEquals 'erroring function' 'Semver::validate' "${out%%:*}" 
    else
      out=${out#Semver::validate: }
      assertEquals "error message" "$2" "$out"
    fi
  fi
}

test_validate() {
  echo 'valid:'
  _valid '1.0.0' '1' '0' '0' '' ''
  _valid '0.1.0' '0' '1' '0' '' ''
  _valid '11.11.11' '11' '11' '11' '' ''
  _valid '1.2.3-alpha' '1' '2' '3' 'alpha' ''
  _valid '1.2.3-alpha3' '1' '2' '3' 'alpha3' ''
  _valid '1.2.3-2.beta' '1' '2' '3' '2.beta' ''
  _valid '1.2.3+joe' '1' '2' '3' '' 'joe'
  _valid '1.2.3+yo.joe7' '1' '2' '3' '' 'yo.joe7'
  _valid '1.2.3-2.beta4+7joe.9' '1' '2' '3' '2.beta4' '7joe.9'

  echo 'invalid:'
  _invalid '1' 'invalid minor: '
  _invalid '1.0' 'invalid patch: '
  _invalid '.' 'invalid major: '
  _invalid '.0' 'invalid major: '
  _invalid '.0.' 'invalid major: '
  _invalid '1.0.' 'invalid patch: '
  _invalid '..' 'invalid major: '
  _invalid '1.2.3-' 'invalid pre-release: '
  _invalid '1.2.3-foo.' 'invalid pre-release: foo.'
  _invalid '1.2.3-.foo' 'invalid pre-release: .foo'
  _invalid $'1.2.3-\t' $'invalid pre-release: \t'
  _invalid $'1.2.3-a\tb' $'invalid pre-release: a\tb'
  _invalid '1.2.3+bar.' 'invalid build metadata: bar.'
  _invalid '1.2.3+.bar' 'invalid build metadata: .bar'
  _invalid '1.2.3-foo+bar.' 'invalid build metadata: bar.'
  _invalid '1.2.3-foo+.bar' 'invalid build metadata: .bar'
  _invalid '1.2.3+' 'invalid build metadata: '
  _invalid $'1.2.3+a\tb' $'invalid build metadata: a\tb'
  _invalid '1.2.3-+' 'invalid pre-release: '
  _invalid '1.2.3-.foo+.bar' 'invalid pre-release: .foo'
  _invalid '-foo' 'invalid major: '
  _invalid '+bar' 'invalid major: '
  _invalid '-foo+bar' 'invalid major: '
}

_compare() {
  local res
  if [[ $2 = '<' ]]; then res=-1
  elif [[ $2 = '=' ]]; then res=0
  elif [[ $2 = '>' ]]; then res=1
  else fail "unexpected op:<$2>"; fi
  echo "${1@Q} $2 ${3@Q}"
  local out out_flip
  out=$(Semver::compare "$1" "$3" 2>&1)
  local ret=$?
  out_flip=$(Semver::compare "$3" "$1" 2>&1)
  local ret_flip=$?
  if [[ $ret -eq 0 && $ret_flip -eq 0 ]]; then
    assertEquals "compare" "$res" "$out"
    assertEquals "compare (flip)" "$((-res))" "$out_flip"
  else
    if [[ $out != Semver::compare:\ * ]]; then
      failNotEquals 'erroring function' 'Semver::compare' "${out%%: *}" 
    elif [[ $ret -ne 0 ]]; then
      out=${out#Semver::compare: }
      fail "error $ret unexpected:<$out>"
    fi
    if [[ $out_flip != Semver::compare:\ * ]]; then
      failNotEquals 'erroring function (flip)' 'Semver::compare' "${out_flip%%:*}" 
    elif [[ $ret_flip -ne 0 ]]; then
      out_flip=${out_flip#Semver::compare: }
      fail "error $ret_flip unexpected:<$out_flip>"
    fi
  fi
}

test_compare() {
  # _compare also tests flipped, so keep lhs <= rhs
  _compare '1.2.3' '=' '1.2.3'
  _compare '1.2.3' '<' '2.0.0'
  _compare '1.2.3' '<' '2.3.4'
  _compare '1.2.3' '<' '1.3.4'
  _compare '1.2.3' '<' '1.2.4'

  _compare '11.22.33' '=' '11.22.33'
  _compare '11.22.33' '<' '22.33.44'
  _compare '11.22.33' '<' '11.33.44'
  _compare '11.22.33' '<' '11.22.44'

  _compare '1.2.03' '=' '1.2.3'
  _compare '1.2.3-04' '=' '1.2.3-4'
  _compare '1.2.3-a04' '<' '1.2.3-a4'

  _compare '1.2.3-a' '=' '1.2.3-a'
  _compare '1.2.3-a' '<' '1.2.3'
  _compare '1.2.3-a' '<' '1.2.3-b'
  _compare '1.2.3-b' '<' '1.2.3-a.a'
  _compare '1.2.3-bb' '<' '1.2.3-a.a'
  _compare '1.2.3-a0' '<' '1.2.3-a00'
  _compare '1.2.3-a01' '<' '1.2.3-a10'
  _compare '1.2.3-a010' '<' '1.2.3-a01b'
  _compare '1.2.3-01' '<' '1.2.3-010'
  _compare '1.2.3-5.a' '<' '1.2.3-5.b'

  _compare '1.2.3' '=' '1.2.3+bar'
  _compare '1.2.3+foo' '=' '1.2.3+bar'
  _compare '1.2.3-a' '=' '1.2.3-a+bar'
  _compare '1.2.3-a' '<' '1.2.3-b+bar'
  _compare '1.2.3-a+foo' '<' '1.2.3-b'
  _compare '1.2.3-a+foo.bar' '<' '1.2.3-b+bar'
}

_gen_Semver_eq() {
  local fun=$1 msg=$2
  local out=$'_'"$fun"$'() {\n'
  out+=$'  local i args expect\n'
  out+=$'  for ((i=1; i < $#; i++)); do args[i-1]=${!i}; done\n'
  out+=$'  expect=${!i}\n'
  out+=$'  echo "${@@Q}"\n'
  out+=$'  local out\n'
  out+=$'  out=$(Semver::'"$fun"$' "${args[@]}" 2>&1)\n'
  out+=$'  local ret=$?\n'
  out+=$'  if [[ $ret -eq 0 ]]; then\n'
  out+=$'    assertEquals '"${msg@Q}"$' "$expect" "$out"\n'
  out+=$'  else\n'
  out+=$'    if [[ $out != Semver::'"$fun"$':\\ * ]]; then\n'
  out+=$'      failNotEquals \'erroring function\' \'Semver::'"$fun"$'\' "${out%%:*}"\n'
  out+=$'    else\n'
  out+=$'      out=${out#Semver::'"$fun"$': }\n'
  out+=$'      fail "error $ret unexpected:<$out>"\n'
  out+=$'    fi\n'
  out+=$'  fi\n'
  out+=$'}\n'
  echo "$out"
}

_gen_Semver_fail() {
  local fun=$1 msg=$2
  local out=$'_'"$fun"$'_fail() {\n'
  out+=$'  local i args expect\n'
  out+=$'  for ((i=1; i < $#; i++)); do args[i-1]=${!i}; done\n'
  out+=$'  expect=${!i}\n'
  out+=$'  echo "${args[@]@Q} -> ${expect@Q}"\n'
  out+=$'  local out\n'
  out+=$'  out=$(Semver::'"$fun"$' "${args[@]}" 2>&1)\n'
  out+=$'  local ret=$?\n'
  out+=$'  if [[ $ret -eq 1 ]]; then\n'
  out+=$'    if [[ $out != Semver::'"$fun"$':\\ * ]]; then\n'
  out+=$'      failNotEquals \'erroring function\' \'Semver::'"$fun"$'\' "${out%%:*}"\n'
  out+=$'    else\n'
  out+=$'      out=${out#Semver::'"$fun"$': }\n'
  out+=$'      assertEquals "'"$msg"$' error message" "$expect" "$out"\n'
  out+=$'    fi\n'
  out+=$'  else\n'
  out+=$'    failNotEquals \'error code\' 1 $ret\n'
  out+=$'    fail "return:<$out>"\n'
  out+=$'  fi\n'
  out+=$'}\n'
  echo "$out"
}

eval "$(_gen_Semver_eq is_prerelease "is pre-release")"
eval "$(_gen_Semver_eq increment_major "inc major")"
eval "$(_gen_Semver_eq increment_patch "inc patch")"
eval "$(_gen_Semver_eq increment_minor "inc minor")"
eval "$(_gen_Semver_eq set_pre "set pre-release")"
eval "$(_gen_Semver_fail set_pre "set pre-release")"
eval "$(_gen_Semver_eq set_build "set build meta")"
eval "$(_gen_Semver_fail set_build "set build meta")"

test_is_prerelease() {
  _is_prerelease '1.0.0' 'no'
  _is_prerelease '0.1.0' 'no'
  _is_prerelease '1.2.3+foo' 'no'

  _is_prerelease '1.0.0-a' 'yes'
  _is_prerelease '0.1.0-a.b' 'yes'
  _is_prerelease '1.2.3-a.b+c.d' 'yes'
}

test_increment_major() {
  _increment_major '1.0.0' '2.0.0'
  _increment_major '1.2.3' '2.0.0'
  _increment_major '0.1.2' '1.0.0'
  _increment_major '11.22.33' '12.0.0'
  _increment_major '1.2.3-a' '2.0.0'
  _increment_major '1.2.3+b' '2.0.0'
  _increment_major '1.2.3-a+b' '2.0.0'
}

test_increment_minor() {
  _increment_minor '1.0.0' '1.1.0'
  _increment_minor '1.2.3' '1.3.0'
  _increment_minor '0.1.2' '0.2.0'
  _increment_minor '11.22.33' '11.23.0'
  _increment_minor '1.2.3-a' '1.3.0'
  _increment_minor '1.2.3+b' '1.3.0'
  _increment_minor '1.2.3-a+b' '1.3.0'
}

test_increment_patch() {
  _increment_patch '1.0.0' '1.0.1'
  _increment_patch '1.2.3' '1.2.4'
  _increment_patch '0.1.2' '0.1.3'
  _increment_patch '11.22.33' '11.22.34'
  _increment_patch '1.2.3-a' '1.2.4'
  _increment_patch '1.2.3+b' '1.2.4'
  _increment_patch '1.2.3-a+b' '1.2.4'
}

test_set_pre() {
  echo 'valid: '
  _set_pre '1.0.0' 'foo' '1.0.0-foo'
  _set_pre '1.0.0' 'foo.bar' '1.0.0-foo.bar'
  _set_pre '1.0.0-foo' '' '1.0.0'
  _set_pre '1.0.0+a' 'foo' '1.0.0-foo+a'
  _set_pre '1.0.0+a.b' 'foo.bar' '1.0.0-foo.bar+a.b'

  echo 'invalid: '
  _set_pre_fail '1.0.0' '.' 'invalid pre-release: .'
  _set_pre_fail '1.0.0' 'foo.' 'invalid pre-release: foo.'
  _set_pre_fail '1.0.0' '.foo' 'invalid pre-release: .foo'
  _set_pre_fail '1.0.0' '.foo.' 'invalid pre-release: .foo.'
  _set_pre_fail '1.0.0+bar' '.foo' 'invalid pre-release: .foo'
  _set_pre_fail '1.0.0' $'\t' $'invalid pre-release: \t'
  _set_pre_fail '1.0.0' $'a\tb' $'invalid pre-release: a\tb'
}

test_set_build() {
  echo 'valid: '
  _set_build '1.0.0' 'foo' '1.0.0+foo'
  _set_build '1.0.0' 'foo.bar' '1.0.0+foo.bar'
  _set_build '1.0.0+foo' '' '1.0.0'
  _set_build '1.0.0-a' 'foo' '1.0.0-a+foo'
  _set_build '1.0.0-a.b' 'foo.bar' '1.0.0-a.b+foo.bar'

  echo 'invalid: '
  _set_build_fail '1.0.0' '.' 'invalid build metadata: .'
  _set_build_fail '1.0.0' 'foo.' 'invalid build metadata: foo.'
  _set_build_fail '1.0.0' '.foo' 'invalid build metadata: .foo'
  _set_build_fail '1.0.0' '.foo.' 'invalid build metadata: .foo.'
  _set_build_fail '1.0.0-bar' '.foo' 'invalid build metadata: .foo'
  _set_build_fail '1.0.0' $'\t' $'invalid build metadata: \t'
  _set_build_fail '1.0.0' $'a\tb' $'invalid build metadata: a\tb'
}

oneTimeSetUp() {
  . ./Semver.sh
}

# wget https://github.com/kward/shunit2/raw/master/shunit2
. ./shunit2
