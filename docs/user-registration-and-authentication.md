# User Registration and Authentication

The Dustoff application requires authenticated users to perform most actions. We have primarily leaned on the Phoenix-provided `phx.gen.auth` to supply user registration and authentication features, with the notable change of removing the magic link log in and instead promoting email and password during registration. 

You should review existing docs to familiarize yourself with `phx.gen.auth`. The later parts of this document build on those designs.

- https://mikezornek.com/ (blog post forthcoming)
- https://hexdocs.pm/phoenix/1.8.0-rc.3/mix_phx_gen_auth.html
- https://hexdocs.pm/phoenix/1.8.0-rc.3/Mix.Tasks.Phx.Gen.Auth.html

## Registration form change

![Screenshot: Registration Form](images/registration-form.png)

Previously, this form asked for just `email`, and I expanded the form to ask for `password` and `password_confirmation`.

To manage the data on this form, I made a new changeset function in `Dustoff.Accounts.User.registration_changeset/2`.

Upon submitting a valid form `Dustoff.Accounts.User` entity is created, and the user is immediately logged in. No need to check their email. No need to deploy early experiments with a working transactional email service.

## Email verification change

In order to reduce friction, we allow users to register their accounts and immediately start using the app. We do not require them to verify the email identity they are providing, though that remains a feature of the `Accounts` context. 

In the future, we may gatekeep some features that are only available to accounts with a verified email. 

There is an issue to track finishing up the change email and email verification at: <https://github.com/zorn/dustoff/issues/12>

## Other changes

In addition to the removal of magic link log in, the main work you'll see in the [original PR](https://github.com/zorn/dustoff/pull/7) is the addition of typespecs to support the generated code.
