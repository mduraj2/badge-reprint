# badge-reprint
This small app allows to users (SPVs) to reprint operators' login.
Unfortunately Perl is not the best tool for it from many different reasons. The biggest is security or its lack. The code in the app can be easily modified to bypass password (and other functions) + the password is visible while typing.
Maybe there will be time when this app becomes a web.
Below is the required structure of db:
user: p3user
db: general
table: oryxusers
columns: firstname, lastname, oryxlogin
