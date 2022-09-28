# Intro

This is the file hierarchy:
* bin
  Executables, libraries, regression test suites
* doc
  Documentation
* etc
  Things that don't belong in any of the other directory; e.g. postman
  collections and environments you can import.
* var
  Logs; the webapp logs to a log in this directory.

---

# Testing

## Testing via Test::Mojo/Test::More

To test my perl webapp via Test::Mojo/Test::More, do the following:

1. start ngrok:
   ngrok is included in the bin directory.  It has been compiled for linux; so
   you may use this binary, or you may use your own copy if you're on a
   non-linux platform:

   ngrok http 3000

   Note the NGROK_BASE_URL; you will need it in a later step.  The NGROK_BASE_URL
   is the URL assigned to you when you run ngrok.  It should look something like
   this:
   https://b947-172-58-60-222.ngrok.io

2. start my perl webapp:
   Note that I assume "." is in your PERLLIB and/or PERL5LIB environment
   variable.  If this is not the case, the do this first:

   export PERLLIB=.

   In the bin directory, execute the following:
   ./event_exercise.pl prefork

3. run the regression test suite:
   In the ./bin/t directory, run the following:

   ./event_exercise_test.t NGROK_BASE_URL

   This takes about 2 minutes to run to completion; please be patient.

## Testing via postman

To test my perl webapp using postman, do the following:

1. start ngrok:
   ngrok is included in the bin directory.  It has been compiled for linux, so
   you may use that or you may use your own copy if you're on a non-linux
   platform:

   ngrok http 3000

2. start my perl webapp:
   Note that I assume "." is in your PERLLIB and/or PERL5LIB environment
   variable.  If this is not the case, the do this first:

   export PERLLIB=.

   In the bin directory, execute the following:
   ./event_exercise.pl prefork

3. postman exports:
   I have exported the following via postman.  These can be found in the "etc"
   directory:
   o lenderx.postman_collection.json
     This is my "lenderx" collection.

   o mojo.postman_collection.json
     This is my "mojo" collection.

   o lenderx.postman_environment.json
     This is my "lenderx" environment.

4. postman setup overview:
   I did much of my testing with postman.  Here is overview of my setup:

   I have two collections, named as follows:
   o lenderx
   o mojo

   lenderx collection:
   This collection is used to test connectivity to LenderX's API, correct API
   usage, access token, etc.  I used this collection early in development, to
   ensure my infrastructure was sound.  Once I verified my foundation was
   solid, I no longer had the need to use this collection.  For completeness,
   however, here is an overview of this collection:

   o GET /me (check access token)
     This is intended to validate my authentication.

   o GET list subscriptions
     This is intended to fetch my event subscriptions.

   o POST subscribe to Order Assignment
     This is intended to subscribe to the following event:
     Event.Appraisal.Order.Assigned

   o DEL delete subscription by ID
     This is intended to remove an event subscription, by manually typing the
     subscription ID.

   o POST test order
     This is intended to trigger LenderX's test order generation.

   mojo collection:
   This collection is used to actually test my webapp/assignment.

   o GET /list subscriptions
     This tests my endpoint to fetch my event subscriptions.  It is a wrapper
     for the following LenderX API endpoint:

     GET https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription

     This assignment has a CRUD requirement, and this is intended to test the
     "Read" portion.

   o POST subscribe to Order Assignment (append)
     This tests my endpoint to subscribe to the following event:
     Event.Appraisal.Order.Assigned

     It is a wrapper for the following LenderX API endpoint:

     POST https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription

     This assignment has a CRUD requirement, and this is intended to test the
     "Update" portion.

   o DEL delete subscription by ID
     This tests my endpoint to remove an event subscription using its ID.

     It is a wrapper for the following LenderX API endpoint:

     DELETE https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription/{event_subscription_id}

     This assignment has a CRUD requirement, and this is intended to test the
     "Delete" portion.

   o DEL delete ALL subscriptions
     This tests my endpoint to remove all event subscriptions.

     It is a wrapper for the following LenderX API endpoints:

     GET https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription
     DELETE https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription/{event_subscription_id}

     This assignment has a CRUD requirement, and this is intended to test the
     "Delete" portion.

   o POST test order
     This tests my endpoint to generate a test order.  It also tests my
     postback/webhook.

     It is a wrapper for the following LenderX API endpoint:

     POST https://api.sandbox1.lenderx-labs.com/appraisal/test/order

     The endpoint for my postback/webhook is as follows:

     {{NGROK_BASE_URL}}/acknowledge/event

   o PUT subscribe to Events (replace)
     This is my endpoint that acts as a setter for my list of subscriptions.

     Note that LenderX provides an endpoint to append to my current list of
     subscriptions:
     POST https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription

     My endpoint is similar, except rather than appending to my current list,
     it sets/assigns my current list.

     My endpoint is a wrapper for the following LenderX API endpoints:

     GET https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription
     DELETE https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription/{event_subscription_id}
     POST https://api.sandbox1.lenderx-labs.com/appraisal/event/subscription

     This assignment has a CRUD requirement, and this is intended to test the
     "Update" portion.

5. postman environment:
   * My postman environment is labelled "lenderx".  It has the following variables:
     o ACCESS_TOKEN:
       This is the access token generated by LenderX.  The way I copy and paste
       the access token into postman is as follows:
       * In the bin directory, run the following command:
         ./print_access_token.pl
       * Copy the access token that is directed to STDOUT, and paste it into the
         postman ACCESS_TOKEN variable.

     o API_KEY:
       This is the API Key assigned to me by LenderX:
       OfEWree5ASNKyVl0DBYeGw

     o API_SECRET:
       This is the API Secret assigned to me by LenderX:
       ux95H0XY5zZZxF5mAWzjHg

     o NGROK_BASE_URL:
       This is the URL ngrok assigns to you when you executed "ngrok http 3000"
       in step 1.  Copy and paste that URL into postman.

       It should look something like this:
       https://a234-172-58-60-222.ngrok.io

     o NGROK_WEBHOOK_URL:
       This is the full canonical HTTP URL for my postback/webhook, generated
       with the use of ngrok.  It should look something like this:
       https://a234-172-58-60-222.ngrok.io/acknowledge/event

6. Testing via postman:
   o Use the following in the "mojo" collection to test the CRUD requirement:
     * GET list subscriptions
     * POST subscribe to Order Assignment (append)
     * DEL delete subscription ID
     * DEL delete ALL subscriptions
     * PUT subscribe to Events (replace)

   o Use the following to test the test order and postback/webhook:
     * POST test order

     Note that the endpoint for my postback/webhook writes to the following log:
     ./var/log/EventExercise.log
