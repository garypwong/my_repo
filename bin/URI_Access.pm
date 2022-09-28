=pod

=head1 NAME

URI_Access.pm - A library of utility subroutines for accessing URIs

=head1 SYNOPSIS

 $href  get_access_token($named_params_href);

=head1 DESCRIPTION

A library of utility subroutines for accessing URIs.  Currently, this library
only has one subroutine, but that may change in the future.

=cut

package URI_Access;

BEGIN {
    use parent Exporter;
    use vars qw{ @EXPORT_OK };
    push @EXPORT_OK, qw{
        get_access_token
    };
};

use strict;
use warnings;
use feature qw{ state };

use Data::Dumper;
use English qw{ -no_match_vars };
use Readonly;

=over 4

=item B<$href get_access_token($named_params_href)>

 Get our Access Token.

 params:
     $named_params_href:
         Optional scalar/href of named parameters, as follows:
         o api_key => $api_key:
           Optional scalar/string.  LenderX API Key.  Defaults to API Key sent via email.
         o api_secret => $api_secret:
           Optional scalar/string.  LenderX API Secret.  Defaults to API Secret sent via email.
         o url => $url:
           Optional scalar/string.  URL from which we fetch the access token.  Defaults to the
           URL sent via email.
 return:
     Scalar/href:
     o On success:
       { status => 1, access_token => $access_token }

     o On failure:
       { status => 0, message => $error_message }

=back

=cut

sub get_access_token {
    my ($named_params_href) = @_;
    $named_params_href //= {};

    my $api_key    = $named_params_href->{api_key};
    my $api_secret = $named_params_href->{api_secret};
    my $url        = $named_params_href->{url};

    state $access_token     = q{};
    state $expiration_epoch = 0;

    if ( length($access_token) && time() < $expiration_epoch ) {
        # if our access token is valid; i.e. hasn't expired
        return { status => 1, access_token => $access_token };
    }

    Readonly my $API_KEY         => $api_key    // 'OfEWree5ASNKyVl0DBYeGw';
    Readonly my $API_SECRET      => $api_secret // 'ux95H0XY5zZZxF5mAWzjHg';
    Readonly my $API_CREDENTIALS => $API_KEY . ':' . $API_SECRET;
    Readonly my $URL => $url // 'https://idp.sandbox1.lenderx-labs.com/oauth/access_token';
    my $cmd_str = join q{ },
        q{ curl -s -k -X POST },
        q{ --header 'Content-Type: application/x-www-form-urlencoded' },
        q{ --header 'Accept: application/json' },
        qq{ -u $API_CREDENTIALS },
        q{  -d 'grant_type=client_credentials' },
        $URL;
    
    my $response_str = qx{ $cmd_str };
    if ( $response_str =~ m{ "access_token" : " (.*?) "}xmsi ) {
	$access_token = $1;
    }

    if ( ! length $access_token ) {
	return { status => 1, message => $response_str };
    }

    my $expiration_int = 0;
    if ( $response_str =~ m{ "expires_in" : (\d*) }xmsi ) {
	$expiration_int = $1;
	$expiration_epoch = time() + $1;
    }
    
    return { status => 1, access_token => $access_token };
}

1;
