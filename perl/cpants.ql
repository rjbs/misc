#!/usr/bin/perl
use Querylet;
use Querylet::Output::Text;
#use Querylet::CGI::Auto;

database: dbi:SQLite2:dbname=cpants.db

query:
	SELECT dist,
		k.extractable,
		k.extracts_nicely,
		k.has_buildtool,
		k.has_manifest,
		k.has_meta_yml,
		k.has_proper_version,
		k.has_readme,
		k.has_test_pod,
		k.has_test_pod_coverage,
		k.has_tests,
		k.has_version,
		k.is_prereq,
		k.no_cpants_errors,
		k.no_pod_errors,
		k.no_symlinks,
		k.proper_libs,
		k.use_strict
	FROM kwalitee k
	JOIN dist d ON k.distid = d.id
	WHERE d.author = ?
	ORDER BY dist

#input type:    auto
output format: text

input: cpanid

query parameter: uc($ARGV[0] || $input->{cpanid})

delete columns where:
	not(grep { ($_||'0') ne '1' } @values)

delete rows where:
	not(grep { ($_||0) == 0 } @$row{grep { $_!~ /dist|is_prereq/ } keys %$row})
