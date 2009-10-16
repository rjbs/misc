use CGI::Form::Table;
use strict;
use warnings;
my $form = CGI::Form::Table->new(
	prefix  => 'whatever',
	columns => [qw(who framed roger rabbit)],
	column_content => {
		who => CGI::Form::Table->_select([1,2],[2,3],[3,4])
	}
);

print "<html><head><title>form</title></head><body>";
print "<form>";
print $form->as_html;
print "</form>";
print "<script type='text/javascript'>";
print $form->javascript;
print "</script>";
print "</body></html>";
