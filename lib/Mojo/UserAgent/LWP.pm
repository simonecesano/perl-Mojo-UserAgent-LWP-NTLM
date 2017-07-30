package Mojo::UserAgent::LWP;


use Mojo::Base qw/LWP::UserAgent Mojo::UserAgent/;

has ['request_cache'];

has lwp => sub { LWP::UserAgent->new };


use Mojo::UserAgent::Transactor;

use Mojo::Message::Response;
use Data::Dump qw/dump/;

sub request {
    my $self = shift;
    my $res = $self->SUPER::request(@_);

    # print $self->lwp;
    
    # my $res = $self->lwp->request(@_);

    # print $res->as_string;
    
    my $msg = Mojo::Message::Response->new;
    
    $self->request_cache($res->request);
    
    $msg->parse($res->as_string);

    $msg->body($res->content);
    
    return $msg;
}

sub build_tx {
    my $self = shift;

    my $t = Mojo::UserAgent::Transactor->new;
    my $tx = $t->tx(@_);

    my $abs = $tx->req->url->to_abs->to_string;
    my $url = quotemeta($tx->req->url->path);
    
    my $r = HTTP::Request->parse( $tx->req->to_string =~ s/$url/$abs/r );
    my $res = $self->request($r);

    $tx->res($res);
    return $tx;
}

sub post { shift->build_tx(POST => @_) }

sub get  { shift->build_tx(GET => @_) }


1;
