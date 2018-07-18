#!/usr/bin/env perl

use strict;
use warnings;
use utf8::all;

use HTML::TreeBuilder 5 -weak;

my $root = HTML::TreeBuilder->new();
$root->ignore_ignorable_whitespace(0);
$root->no_space_compacting(1);
$root->store_comments(1);
$root->warn(1);
$root->parse_file(*STDIN);
my $man = $root->guts();

sub is_spacer {
    my @c = shift->content_list();
    @c == 1 and $c[0] eq "\x{a0}"
}

for my $xr ($man->look_down(_tag => 'a', class => 'Xr')) {
    $xr->tag('b');
}
$man->look_down(_tag => 'table', class => 'head')->detach();
for my $h1 ($man->look_down(_tag => 'h1')) {
    $h1->tag('h2');
    $h1->look_down(_tag => 'a')->replace_with_content();
}
for my $dt ($man->look_down(
    _tag => 'dt',
    \&is_spacer,
)) {
    my $parent = $dt->parent();
    my @siblings = $parent->content_list();
    my $pindex = $dt->pindex();
    my $len = 1;
    while ($siblings[$pindex+$len] =~ /^\s*$/) { $len++; }
    my $el = $siblings[$pindex+$len];
    unless (ref($el) eq 'HTML::Element' and is_spacer($el)) {
        next;
    }
    while ($siblings[$pindex+$len] =~ /^\s*$/) { $len++; }
    while ($pindex > 0 and $siblings[$pindex-1] =~ /^\s*$/) { $pindex--; $len++; }
    $parent->splice_content($pindex, $len+1);
}
for my $nm ($man->look_down(_tag => 'table', class => 'Nm')) {
    next if (!defined $nm->parent());
    my $last_tag = 'table';
    my $parent = $nm->parent();
    my @siblings = $parent->content_list();
    my $pos = $nm->pindex()+1;
    my $len = 0;
    while ($len < scalar(@siblings)) {
        my $r = $siblings[$pos+$len];
        unless (ref($r) eq 'HTML::Element') {
            last if ($r !~ /^\s*$/);
            $len++;
            next;
        }
        my $tag = $r->tag();
        if ($tag eq 'table') {
            $nm->push_content($r->content_list());
            $len++;
        } elsif ($tag eq 'br' and $last_tag eq 'table') {
            $len++;
        } else {
            last;
        }
        $last_tag = $tag;
    }
    $parent->splice_content($pos, $len);
}
for my $code ($man->look_down(_tag => 'code', class => 'Li')) {
    my @siblings = $code->parent()->content_refs_list();
    my $i = $code->pindex();
    my $l = $siblings[$i-1];
    if ($l and !ref($$l)) {
        $$l =~ s/\x{2018}$//;
    }
    my $r = $siblings[$i+1];
    if ($r and !ref($$r)) {
        $$r =~ s/^\x{2019}//;
    }
}
for my $code_block ($man->look_down(_tag => 'div', class => 'Bd')) {
    my $pre = $code_block->look_down(_tag => 'pre', class => 'Li');
    my $content = "\n```" . $pre->as_text() . "```\n";
    my $literal = HTML::Element->new('~literal', 'text' => $content);
    $code_block->replace_with($literal);
}

print substr($man->as_HTML(undef, undef, {}), 5, -6);
