package Controller::VediDomanda;
use strict;
use warnings;
use CGI::Carp;
use Encode;
use POSIX;

use Lib::Renderer;
use Lib::Markup;
use Lib::Utils;
use Lib::Sanitize;
use Middleware::Session;
use Model::Question;
use Model::Answer;

sub handler {
	# Get parameters
	my ($req, $res) = @_;
	my @allAnswers;
	
	my $questionId;
	if ($req->attr("method") eq 'POST') {
		# Evita XPath injection
		$questionId = Lib::Sanitize::number($req->param('questionId'));
	} else {
		# Evita XPath injection
		$questionId = Lib::Sanitize::number($req->param("id"));
	}

	my $session = Middleware::Session::getSession($req);
	my $sessionEmail = "";
	if ($session) {
		$sessionEmail = $session->param("email");
	}

	# TODO ...

	if ($req->attr("method") eq 'POST' and Middleware::Authentication::isLogged($req)) {
		
		# controllo se è una richiesta di cambio di stato della domanda
		if ($req->param("status")) {
			my $question = Model::Question::getQuestionById($questionId);
			
			# se l'utente è l'autore della domanda
			if ($question->{author} eq $sessionEmail) {
				if ($req->param("status") eq 'opened') {
					Model::Question::setQuestionAsOpened($questionId);
				}
				elsif ($req->param("status") eq 'solved') {
					Model::Question::setQuestionAsSolved($questionId);
				}
			}
		}
		# controllo se il campo di inserimento della risposta non è vuoto
		elsif ($req->param("post-text")) {

			my $text = Lib::Sanitize::content($req->param("post-text"));

			# controllo che non si stia tentando di inserire una risposta ad una domanda chiusa
			if (Model::Question::getQuestionById($questionId)->{status} eq 'opened') {
				Model::Answer::insertAnswer($questionId, $text, $sessionEmail);
			}
		}

		# recupero tutte le risposte
		@allAnswers = Model::Answer::getAnswersByQuestionId($questionId);
	} else {
		# recupero tutte le risposte
		@allAnswers = Model::Answer::getAnswersByQuestionId($questionId);
	}

	# prendo le risposte per la pagina $req->param("page")
	my $answersPerPage = 9;
	# Evita XSS attack
	my $page = Lib::Sanitize::number($req->param("page"));

	if ($req->param("post-text")) {  # Se ho inserito una risposta mi aspetto di andare all'ultima pagina.
		$page = ceil(scalar(@allAnswers)/$answersPerPage);
	}

	if ($page eq "" or $page == 0) {
		$page = 1;
	}
	my $arrSize = @allAnswers;
	if (($page - 1) * $answersPerPage > $arrSize) {
		$page = ceil( $arrSize / $answersPerPage );
	}
	my @answers = splice(@allAnswers, ($page - 1) * $answersPerPage, $answersPerPage);

	# Execution
	my $data = {
		"logged" => Middleware::Authentication::isLogged($req),
		"session" => {
			"email" => $sessionEmail
		},
		"question" => Model::Question::getQuestionById($questionId),
		"answers" => \@answers,
		"totalAnswers" => $arrSize,
		"pageInfo" => {
			currentPageNumber => $page,
			totalPages => ceil( $arrSize / $answersPerPage )
		}
	};
	
	# Response
	$res->write(Lib::Renderer::render('vedi-domanda.html', $data));
}

1;