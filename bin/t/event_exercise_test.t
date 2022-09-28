#!/usr/bin/env perl

# DESCRIPTION:
# Semi-automated regression test for my webapp.  It is semi-automated because
# you must manually feed this script the "ngrok base URL".  See below for
# details.
#
# USAGE:
# ./event_exercise_test.t NGROK_BASE_URL
#
# NGROK_BASE_URL:
# o Required argument
# o This is the URL assigned to you when you run ngrok.  The NGROK_BASE_URL
#   should look something like this:
#   https://b947-172-58-60-222.ngrok.io

use strict;
use warnings;

use Test::Mojo;
use Test::More;

#### ngrok related (this is not robust):
# should look something like this:
# https://b947-172-58-60-222.ngrok.io
my $ngrok_base_url = $ARGV[0];
ok( length($ngrok_base_url) > 10 && $ngrok_base_url =~ m{ \A https:// .*? \. ngrok \.io \z }xms,
    "ngrok base URL looks plausible: $ngrok_base_url");

#### get our access token:
chomp( my $access_token = get_access_token() );
ok( length($access_token) > 10, 'got access token' );

#### run our regression test suites:
my $test_obj = Test::Mojo->new();

# The "test order" takes a bit of time; so we set a super-conservative
# inactivity timeout:
$test_obj->ua->inactivity_timeout(3600);

get_list_subscriptions_t();
post_subscribe_t();
delete_subscription_by_ID_t();
delete_ALL_subscriptions_t();
post_test_order_t();
put_subscribe_to_events_t();

done_testing();

# Test "PUT subscribe to Events (replace)" in the "mojo" collection.
sub put_subscribe_to_events_t {
    #### 1. Start from a clean slate; remove all event subscriptions.
    #### 2. Subscribe to *MULTIPLE* events; i.e. generate multiple event
    ####    subscriptions.
    #### 3. Execute and test "DEL ALL subscriptions".  This is our *REAL* test;
    ####    most/all other tests are incidental.
    #### 4. Get our list of event subscriptions.

    #### step 1 (all tests here are incidental):
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );

    #### step 2 (all tests here are incidental):
    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Assigned' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Accepted' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Rushed' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    #### step 3 (all tests here are *REAL*):
    $test_obj->put_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [
                'Event.Appraisal.Order.Accepted',
                'Event.Appraisal.Order.Rushed'
            ],
            'url' => $ngrok_base_url . '/acknowledge/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/url')
     ->json_is('/events' => ['Event.Appraisal.Order.Accepted', 'Event.Appraisal.Order.Rushed']);
}

# Test "POST test order" in the "mojo" collection.
sub post_test_order_t {
    #### 1. Start from a clean slate; remove all event subscriptions.
    #### 2. Subscribe to the Order Assignment event.
    #### 3. Get our list of event subscriptions.
    #### 4. Execute and test "POST test order".  This is our *REAL* test;
    ####    most/all other tests are incidental.

    #### step 1 (all tests here are incidental):
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );

    #### step 2 (all tests here are incidental):
    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Assigned' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    #### step 3 (all tests here are incidental):
    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ "event_subscription_id" : \d+ }xmsi )
     ->content_like( qr{ "events" : \[ "Event.Appraisal.Order.Assigned" \] }xmsi );

    #### step 4 (all tests here are *REAL*):
    $test_obj->post_ok(
        $ngrok_base_url . '/test/order',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(201)
     ->json_has('/order_id'); # this is one of the most important, if not most important, field
}

# Test "DEL delete ALL subscriptions" in the "mojo" collection.
sub delete_ALL_subscriptions_t {
    #### 1. Start from a clean slate; remove all event subscriptions.
    #### 2. Subscribe to *MULTIPLE* events; i.e. generate multiple event
    ####    subscriptions.
    #### 3. Execute and test "DEL ALL subscriptions".  This is our *REAL* test;
    ####    most/all other tests are incidental.
    #### 4. Get our list of event subscriptions.

    #### step 1 (all tests here are incidental):
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );

    #### step 2 (all tests here are incidental):
    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Assigned' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Accepted' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Rushed' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    #### step 3 (all tests here are *REAL*):
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );
}

# Test "DEL delete subscription by ID" in the "mojo" collection.
sub delete_subscription_by_ID_t {
    #### 1. Start from a clean slate; remove all event subscriptions.
    #### 2. Subscribe to the Order Assignment Event.
    #### 3. Get our list of event subscriptions.
    #### 4. Execute and test "DEL delete subscription by ID".  This is our
    ####    *REAL* test; most/all other tests are incidental.
    #### 5. Get our list of event subscriptions (again).  Should be the
    ####    empty list.

    #### step 1 (all tests here are incidental):
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );

    #### step 2 (all tests here are incidental):
    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Assigned' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    #### step 3 (all tests here are incidental):
    my $response = $test_obj->ua->get(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->result;

    ok($response->code() =~ m{ 20\d }xmsi, 'status code =~ 20X');

    my $body_str = $response->body;
    like($body_str,
         qr{ "events" : \[ "Event.Appraisal.Order.Assigned" \] }xmsi,
         q{ events: ["Event.Appraisal.Order.Assigned"] },
    );
    
    my $event_subscription_id;
    if ( $body_str =~ m{ "event_subscription_id" : (\d+) }xmsi ) {
        $event_subscription_id = $1;
    }
    ok( defined $event_subscription_id, "captured event_subscription_id: $event_subscription_id" );

    #### step 4 (all tests here are *REAL*):
    $test_obj->delete_ok(
        $ngrok_base_url . "/event/subscription/$event_subscription_id",
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->json_is("/event_subscription_id" => $event_subscription_id )
     ->json_is("/is_deleted" => 1 );
    
    #### step 5 (all tests here are *REAL*; it's like a double-check on the previous step):
    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );
}

# Test "POST subscribe to Order Assignment (append)" in the "mojo" collection.
sub post_subscribe_t {
    #### 1. Start from a clean slate; remove all event subscriptions.
    #### 2. Execute and test "POST subscribe to Order Assignment (append).  This
    ####    is our *REAL* test; most/all other tests are incidental.
    #### 3. Then, test "GET list subscriptions".

    #### step 1 (all tests here are incidental):
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );

    #### step 2 (all tests here are *REAL*):
    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Assigned' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    #### step 3 (all tests here are *REAL*; it's like a double-check on the previous step):
    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ "event_subscription_id" : \d+ }xmsi )
     ->content_like( qr{ "events" : \[ "Event.Appraisal.Order.Assigned" \] }xmsi );
}
    
# Test "GET list subscriptions" in the "mojo" collection.
sub get_list_subscriptions_t {
    #### 1. Start from a clean slate; remove all event subscriptions.
    #### 2. Subscribe to the Order Assignment Event.
    #### 3. Then, execute and test "GET list subscriptions".  This is our *REAL*
    ####    test; most/all other tests are incidental.

    #### step 1:
    # this test is incidental:
    $test_obj->delete_ok(
        $ngrok_base_url . '/event/subscription_all',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s* success }xmsi );

    # this tests "GET list subscriptions" so it is a *REAL* test
    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ \A \s*
                         \[ \]
                         \s* \z }xmsi );

    #### step 2 (all tests here are incidental):
    $test_obj->post_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
        json => {
            'events' => [ 'Event.Appraisal.Order.Assigned' ],
            'url'    => $ngrok_base_url . '/acknowledgement/event'
        }
    )->status_is(201)
     ->json_has('/event_subscription_id')
     ->json_has('/events');

    #### step 3 (all tests here are *REAL*):
    $test_obj->get_ok(
        $ngrok_base_url . '/event/subscription',
        { Authorization => 'Bearer ' . $access_token },
    )->status_is(200)
     ->content_like( qr{ "event_subscription_id" : \d+ }xmsi )
     ->content_like( qr{ "events" : \[ "Event.Appraisal.Order.Assigned" \] }xmsi );
}

sub get_access_token {
    my $cmd_result_str = qx{ cd ../ && ./print_access_token.pl };

    if ( $cmd_result_str =~ m{ access_token: \s+ (.*) \z }xmsi ) {
	return $1;
    }

    BAIL_OUT("Failed to extract access token from command result string: <$cmd_result_str>");
}
