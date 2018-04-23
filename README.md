# crystal-coverage
Coverage tool for Crystal lang

## About it

This is a proof of concept, the code is shitty.

It uses ASTNode parsing to inject coverage instrumentations and reflag the lines
of code using `#<loc ...>` directive

It covers only the relative files (e.g. require starting with `.`)

Main objectives (in this order):

- Make it works with real life case
- Make it usable; ship a binary with the shard
- Integration of travis + coveralls == covering badges for crystal projects <3!
- Rewrite the code, making it more clear and concise; avoiding string concatenation, but use string builder