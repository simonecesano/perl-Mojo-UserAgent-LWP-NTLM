package Mojo::UserAgent::LWP::NTLM;

use Mojo::Base qw/Mojo::UserAgent::LWP/;

has ['user', 'password'];

use Mojo::Message::Response;

use Data::Dump qw/dump/;
use Authen::NTLM;

sub request {
     my $self = shift;
    
    $self->conn_cache({ total_capacity => 2 });

    $self->credentials(undef, undef, $self->user, $self->password);

    my $res = $self->SUPER::request(@_);

    if ($res->code eq '401' && $res->headers->header('www-authenticate') =~ /NTLM/) {
	ntlmv2(2);
	ntlm_user($self->user);
	ntlm_password($self->password);

	my $auth_value = "NTLM " . ntlm();
	
	$self->request_cache->header('Authorization' => $auth_value);
	my $res = $self->SUPER::request($self->request_cache);

	($auth_value) = (grep { /NTLM/ } split /\, /, $res->headers->header('www-authenticate'));
	$auth_value =~ s/^NTLM //;

	$auth_value = "NTLM " . ntlm($auth_value);

	$self->request_cache->header('Authorization' => $auth_value);
	$res = $self->SUPER::request($self->request_cache);

	ntlm_reset();
	
	return $res;
    }
    return $res;
}

1;
