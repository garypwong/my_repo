# Description:
# Coding assignment for LenderX (for the Technical Review interview round):
# Develop a small RESTful API wrapper application around their public Vendor
# API in the LenderX Sandbox environment.
#
# Usage: see Readme.md

package EventExercise;

use feature qw{ state };

use Data::Dumper;
use English qw{ -no_match_vars };
use Mojo::Log;
use Mojo::UserAgent;
use Mojolicious::Lite -signatures;
use Readonly;

#my $webapp_log = Mojo::Log->new(path => '../var/log/EventExercise.log', level => 'warn');
my $webapp_log = Mojo::Log->new(path => '../var/log/EventExercise.log', level => 'debug');

Readonly my $BASE_URL              => 'https://api.sandbox1.lenderx-labs.com/appraisal';
Readonly my $GET_EVENTS_URL        => $BASE_URL . '/event/subscription';
Readonly my $SUBSCRIBE_EVENTS_URL  => $BASE_URL . '/event/subscription';
Readonly my $UNSUBSCRIBE_EVENT_URL => $BASE_URL . '/event/subscription';
Readonly my $TEST_ORDER_URL        => $BASE_URL . '/test/order';
    
# Wrapper for LenderX's endpoint to GET a list of all Events I am subscribed to.
get '/event/subscription' => sub ($mojo_controller) {
    #### get our list of subscribed events:
    my $user_agent = Mojo::UserAgent->new();
    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $lenderx_response = $user_agent->get(
        $GET_EVENTS_URL,
        { Authorization => $authorization_str },
    )->res();

    #### forward list of subscribed events to our client/requestor:
    my $client_response = $mojo_controller->res;
    $client_response->code($lenderx_response->code);
    $client_response->message($lenderx_response->message);
    $mojo_controller->render(text => $lenderx_response->body);
};

# Wrapper for LenderX's endpoint to subscribe to an Event or list of Events.
post '/event/subscription' => sub ($mojo_controller) {
    #### subscribe to Event(s):
    my $user_agent = Mojo::UserAgent->new();
    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $lenderx_response = $user_agent->post(
        $SUBSCRIBE_EVENTS_URL,
        { Authorization => $authorization_str },
        json => $mojo_controller->req->json, 
    )->res();

    #### forward/respond to our client/requestor:
    my $client_response = $mojo_controller->res;
    $client_response->code($lenderx_response->code);
    $client_response->message($lenderx_response->message);
    $mojo_controller->render(text => $lenderx_response->body);
};

# Wrapper for LenderX's endpoint to remove a subscription (by numeric ID).
del '/event/subscription/:event_subscription_id' => sub ($mojo_controller) {
    #### remove Event subscription; respond to our client/requestor:
    my $event_subscription_id = $mojo_controller->stash('event_subscription_id');

    my $user_agent = Mojo::UserAgent->new();
    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $lenderx_response = $user_agent->delete(
        $UNSUBSCRIBE_EVENT_URL . "/$event_subscription_id",
        { Authorization => $authorization_str },
    )->res();

    my $client_response = $mojo_controller->res;
    $client_response->code($lenderx_response->code);
    $client_response->message($lenderx_response->message);
    $mojo_controller->render(text => $lenderx_response->body);
};

# Unsubscribe from the given subscription IDs.
#
# params:
#     $event_subscription_ID_aref:
#         Scalar/aref of subscription IDs (integers) to unsubscribe from.
#     $authorization_str:
#         Scalar/string.  The Authorization header string, which should look something like this:
#         Bearer <access_token>
# return:
#     Scalar/aref of Mojo::Message::Response Objects -- result of subscription removal.
sub unsubscribe_from_IDs($event_subscription_ID_aref, $authorization_str) {
    my $response_aref = [];
    my $user_agent = Mojo::UserAgent->new();

    REMOVE_EVENT_SUBSCRIPTION:
    for my $event_subscription_id ( @{$event_subscription_ID_aref} ) {
        my $response = $user_agent->delete(
            $UNSUBSCRIBE_EVENT_URL . "/$event_subscription_id",
            { Authorization => $authorization_str },
        )->res();

        push @{$response_aref}, $response;
    }

    return $response_aref;
}

# Remove all event subscriptions.  Response is as follows:
#     o On success:
#       HTTP 200
#     o On failure:
#       HTTP 500
#     Body is empty in either case.
my $route = del '/event/subscription_all' => sub ($mojo_controller) {
    #### get all subscription IDs; unsubscribe all subscriptions:
    my $subscription_IDs_aref = get_subscription_IDs($mojo_controller);
    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $response_aref = unsubscribe_from_IDs($subscription_IDs_aref, $authorization_str);

    #### conditionally respond to our client/requestor with success/fail message:
    my $response = $mojo_controller->res();
    my @unsuccessful_response_ary = grep { $_->code() !~ m{ 20\d }xmsi } @{$response_aref};
    if ( @unsuccessful_response_ary ) {
        $response->code(500);
        $mojo_controller->render(text => 'Failed to unsubscribe all event subscriptions.  Please try again.');
        return;
    }

    $response->code(200);
    $mojo_controller->render(text => 'Success, you have unsubscribed from all event subscriptions.');
};

# Return a list of our subscription IDs.
#
# params:
#     $mojo_controller:
#         Mojolicious::Controller used to fetch our subscription IDs from LenderX.
# return:
#     Scalar/aref of integers.  Each integer is a subscription ID.
sub get_subscription_IDs($mojo_controller) {
    my $user_agent = Mojo::UserAgent->new();
    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $lenderx_response = $user_agent->get(
        $GET_EVENTS_URL,
        { Authorization => $authorization_str },
    )->res();

    my $code = $lenderx_response->code;
    if ( $code !~ m{ 20\d }xmsi ) {
        my $message = $lenderx_response->message;
        $webapp_log->warn("Failed to fetch event subscriptions: code/message: $code/$message");
        return [];
    }

    my $json_payload_aref = $lenderx_response->json;
    my @subscription_ID_ary = map { $_->{'event_subscription_id'} } @{$json_payload_aref};

    return \@subscription_ID_ary;
}

# Replace all subscriptions with the list of subscriptions provided.
# The request is exactly the same as LenderX's endpoint POST /event/subscription,
# except we expect PUT vice POST.  The response is the same as LenderX's endpoint
# POST /event/subscription.
#
# Note the difference between POST /event/subscription and PUT /event/subscription:
# o POST /event/subscription appends to our list of subscriptions.
# o PUT  /event/subscription replaces our list of subscriptions.
put '/event/subscription' => sub ($mojo_controller) {
    #### get all subscription IDs; unsubscribe all subscriptions:
    my $subscription_IDs_aref = get_subscription_IDs($mojo_controller);
    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $response_aref = unsubscribe_from_IDs($subscription_IDs_aref, $authorization_str);

    my @unsuccessful_response_ary = grep { $_->code() !~ m{ 20\d }xmsi } @{$response_aref};
    my $client_response = $mojo_controller->res();
    if ( @unsuccessful_response_ary ) {
	$client_response->code(500);
	$mojo_controller->render(
            json => {
                error => 'Sorry, failed to update event subscriptions.  Please try again.',
            },
        );
        return;
    }

    #### subscribe to Event(s); respond to our client/requestor:
    my $user_agent = Mojo::UserAgent->new();
    my $lenderx_response = $user_agent->post(
        $SUBSCRIBE_EVENTS_URL,
        { Authorization => $authorization_str },
        json => $mojo_controller->req->json,
     )->res();

    my $lenderx_code = $lenderx_response->code;
    $client_response->code($lenderx_code);
    $client_response->message($lenderx_response->message);
    $mojo_controller->render(text => $lenderx_response->body);
};

# Wrapper for LenderX's endpoint to generate a test order:
post 'test/order' => sub ($mojo_controller) {
    #### subscribe to Event(s); respond to our client/requestor:
    my $user_agent = Mojo::UserAgent->new();

    # The POST below can take a bit of time to process (well less than 30 seconds, however).
    # To prevent an "Inactivity timeout" error, set the timeout to an amount that is "overkill."
#    $user_agent->inactivity_timeout(3600);
    $mojo_controller->inactivity_timeout(3600);

    my $authorization_str = $mojo_controller->req->headers->authorization;
    my $lenderx_response = $user_agent->post(
        $TEST_ORDER_URL,
        { Authorization => $authorization_str },
        json => $mojo_controller->req->json,
     )->res();

    my $client_response = $mojo_controller->res;
    $client_response->code($lenderx_response->code);
    $client_response->message($lenderx_response->message);
    $mojo_controller->render(text => $lenderx_response->body);
};

# The postback/webhook portion of the exercise; i.e. when LenderX sends a notification
# that an order assignment event has occurred, it POSTs the message to this route/endpoint.
post 'acknowledgement/event' => sub ($mojo_controller) {
    my $response = $mojo_controller->res;
    $response->code(200);
    $response->message('OK');

    my $body_str = "Acknowledging triggered event\n";
    $mojo_controller->render(text => $body_str);
    $webapp_log->debug($body_str);
};

app->start();

1;
