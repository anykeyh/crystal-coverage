# crystal-coverage
Coverage tool for Crystal lang

## Welcome

Before you start, you must understand this is a proof of concept. I'm not happy
with the current code implementation.

Lot of features and options will change in the future.

The code will probably be rebuilt almost from scratch

Note also than it hasn't yet been properly tested. Ironic, for a cover tool, isn't it? :-)
anyway, if you're bold enough to give a try, read the getting started below !

## Installation

Just add this line in your `shards.yml` file

```yaml
development_dependencies:
  coverage:
    github: anykeyh/crystal-coverage
```

Wait for the binary to compile. The binary will be build in `bin/crystal-coverage`

## Usage

```
crystal-coverage spec/myfile_spec1.cr spec/myfile_spec2.cr
```

Coverage file will be recreated after your software run on `coverage/` folder.

## Bugs

There's probably dozen of bugs. Please fill issues and PR are welcome.

The library will evolve, so don't hesitate to `shards update` and test with the
latest release before submitting an issue.

Due to some limitation, there's probably still a non-zero chance your code will
not compile with the coverage instrumentations.

In this case, you can give a look to the generated output using the `-p` argument:

```
crystal-coverage src/main.cr -p
```

When you fill issues, would be great to isolate the code which fail to load, so I
can add it to my code library and fix the library.

## Performances

The performances will slightly degrade using the coverage tool. Note the
software is executed without release flag.

To test in `--release` mode, you can do:

```
crystal-coverage src/main.cr -p | crystal eval --release
```

## How does it works?

It uses ASTNode parsing to inject coverage instrumentations and reflag the lines
of code using `#<loc ...>` directive

It covers only the relative files (e.g. require starting with `.`) inside your
project directory.

It then generate a report in the directory `/coverage/` relative to your project

## Planned features

- Binding with travis + coveralls
- 
