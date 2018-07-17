1,7d
/^<\/table>$/ {
  N
  /\n<br\/>$/ {
    N
    /<table class="Nm">$/d
    t table-nm-break
    P; D
    :table-nm-break
  }
  t table-break
  P; D
  :table-break
}
s/&#x2018;\(<code class="Li">\)/\1/g
s/\(<\/code>\)&#x2019;/\1/g
s/<a\( class="Xr" title="Xr"\)>\([^<]*\)<\/a>/<b\1>\2<\/b>/g
/^\s*<dt class="It-tag">&#x00A0;<\/dt>$/ {
  N
  /\n\s*<dd class="It-tag">&#x00A0;<\/dd>$/d
}
s/^<h1\( class="Sh" title="Sh"[^>]*\)>\(.*\)<\/h1>$/<h2\1>\2<\/h2>/g
s/^<pre class="Li">$/\n```/g
s/^<\/pre>$/```\n/g
/^<h1 class="Sh" title="Sh"[^>]*>/ {
  b find-h1-first
  : find-h1
  N
  : find-h1-first
  s/<h1\( class="Sh" title="Sh"[^>]*\)>\(.*\)<\/h1>/<h2\1>\2<\/h2>/g
  t find-h1-break
  b find-h1
  : find-h1-break
}
