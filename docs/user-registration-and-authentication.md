# User Registration and Authentication

While initialized on the Phoenix [`mix.gen.auth`](https://hexdocs.pm/phoenix/1.8.0-rc.3/mix_phx_gen_auth.html) generators this app prefers single email/password flow when it comes to user account registration.

## Change Email

A user can register a new account without immediatly verifing their email and continue to use the site.

(We should add a verify button.)

For security we did however stick to a flow where in if they want to change their email, they need to do so through an email link, and doing that help us reuse logic that once such a token is accepted we will delete the previously persisted `UserToken` entities based on the old email.
