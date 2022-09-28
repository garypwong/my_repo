#!/usr/bin/env perl

=head1 NAME

event_exercise.pl - event coding and integrations development exercise

=head1 SYNOPSIS

 ./event_exercise.pl prefork

=head1 DESCRIPTION

 Event coding assignment for LenderX as part of the Technical Review interview
 round:

 Develop a small RESTful API wrapper application around their public Vendor API
 in the LenderX Sandbox environment.  This exercise is intended to assess
 the candidate's ability to peform integrations development.

 For details, see the Readme.md in the "doc" directory.

=cut

use strict;
use warnings;
use lib qw{ . };

use EventExercise;


