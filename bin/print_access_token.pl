#!/usr/bin/env perl

=head1 NAME

print_access_token.pl - print the access token granted by LenderX

=head1 SYNOPSIS

 ./print_access_token.pl

=head1 DESCRIPTION

Print the access token granted by LenderX.  I wrote this because it was tedious
using curl.

=cut

use strict;
use warnings;
use lib qw{ . };

use URI_Access qw{ get_access_token };

my $response_href = get_access_token();
if ( ! $response_href->{status} ) {
    die("Failed to fetch access token: $response_href->{message}");
}

my $access_token = $response_href->{access_token};
print "access_token:\n", $access_token, "\n";
