package Controller::ErrorNotFound;
use strict;
use warnings;
use CGI::Carp;
use Lib::Renderer;

sub handler {
	# Get parameters
	my ($request) = @_;
	
	# Execution
	my $data = {
		"query" => $request->query(),
		"path" => $request->path(),
		"parameters" => $request->parameters()
	};
	
	# Response
	return Lib::Renderer::render('notfound.html', $data);
}

1;