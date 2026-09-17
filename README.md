# Gleam ast-grep

This project shows off how to setup [ast-grep](https://github.com/ast-grep/ast-grep) with [Gleam](https://gleam.run/)
and concrete use cases that you can try out in your Gleam projects.

Setup is very easy. We setup a custom language with ast-grep using Gleam's [tree-sitter](https://github.com/gleam-lang/tree-sitter-gleam/) repository.

You can come a loong way with "just" `grep` and don't immediately have to opt for `ast-grep`. But I do think for larger structural changes,
linting rule distribution and not having to deal with regex edge cases it is worth exploring.

## Setup and Installation

[Install ast-grep](https://github.com/ast-grep/ast-grep#installation) for whatever platform you're on.

Then we build the Gleam parser from the tree sitter repository:

```bash
mkdir -p .ast-grep/parsers
git clone --depth 1 https://github.com/gleam-lang/tree-sitter-gleam .ast-grep/tree-sitter-gleam

# MacOS
tree-sitter build -o .ast-grep/parsers/gleam.dylib .ast-grep/tree-sitter-gleam

# Linux
tree-sitter build -o .ast-grep/parsers/gleam.so .ast-grep/tree-sitter-gleam
```

I have no idea how to anything on Windows, so I cannot tell you how to install that stuff on there.

Now we can configure `ast-grep` and create `sgconfig.yml`:

```yaml
# sgconfig.yml
ruleDirs: [rules]
customLanguages:
  gleam:
    # For MacOS, or gleam.so on Linux
    libraryPath: .ast-grep/parsers/gleam.dylib
    extensions: [gleam]
    # This is important for refactorings (read more on it below)
    expandoChar: z
```

On MacOS it's `dylib`

If you already have some rules setup in the `rules/` directory, you can run `ast-grep scan .` to run it on your project.

## Use Cases

### Linting

You can make linting rules very quickly with this setup. There is no official Gleam linter at the time of writing this, so my rules I will use are
purely from my own subjective preferences and not measures of better, worse or idiomatic Gleam code.

A lot of the rules I tried to implement come from the project [glinter](https://github.com/pairshaped/glinter), a linter for Gleam programs written in Gleam.

#### **[Result with `String` Error](./rules/result_string_error.yml)**

I would argue, that `String` are not very descriptive and a good model for your program apis. Ideally, you create a custom Error type for your
library or application. So you should not write code:

```gleam
pub fn wibble() -> Result(wisp.Response, String) {
  Error("User not found")
}
```

but instead:

```gleam
pub type AppError {
  UserNotFound
  DatabaseUnavailable
}

pub fn wibble() -> Result(wisp.Response, AppError) {
  Error(UserNotFound)
}
```

#### **[Boolean in Public API](./rules/bool_in_public_api.yml)**

`Bool` does not carry a lot of context. `True` or `False` means nothing, without more knowledge about the domain. In a function call
without a label, this can lead to very confusing code. So ideally you avoid them at all and replace it with a custom type, especially
in the public API of your application or library.

Checkout the rule here: [rules/bool_in_public_api.yml](./rules/bool_in_public_api.yml)

#### Example Output

[src/app.gleam](./src/app.gleam) contains some example code that triggers the [rules](./rules) setup in this repository.
Running `ast-grep scan .` gives us this output:

```console
~/daniellionel01/gleam-ast-grep $ ast-grep scan .
warning[explicit_parameter_types]: Add explicit types to all function parameters
   ┌─ src/app.gleam:12:1
   │
12 │ ╭ pub fn explicit_parameter_types(value) -> Int {
   │                                   -----
13 │ │   value
14 │ │ }
   │ ╰─^
   │
   = Gleam conventions recommend annotations for every module function.

warning[boolean_blindness]: Use a descriptive custom type instead of Bool in a public API
   ┌─ src/app.gleam:16:26
   │
16 │ ╭ pub fn boolean_blindness(enabled: Bool) -> Bool {
   │   ---                      ^^^^^^^^^^^^^
17 │ │   enabled
18 │ │ }
   │ ╰─'
   │
   = Keep Bool when two unnamed states are clear and cannot be confused.

warning[result_string_error]: Use a custom error type instead of String
   ┌─ src/app.gleam:8:1
   │
 8 │ ╭ pub fn stringly_typed_error() -> Result(Int, String) {
   │                                    -------------------
 9 │ │   Error("dummy error")
10 │ │ }
   │ ╰─^
   │
   = String errors cannot be pattern matched by callers.

warning[explicit_return_type]: Functions should have explicit return types
   ┌─ test/app_test.gleam:8:1
   │
 8 │ ╭ pub fn hello_world_test() {
   · │
13 │ │ }
   │ ╰─^
   │
   = This gives us more information in the AST for analysis.
```

### Refactors

`ast-grep` has a very cool interactive refactor tui that reminds me of snapshot testing with [birdie](https://github.com/giacomocavalieri/birdie).

![./images/interactive-refactoring.png]

Unfortunately at the time of writing this (September 2026), the grammar defined in the Gleam tree sitter
repository is not compatible with the metavariable capture syntax of `ast-grep` that is very important
for reliable rewrite rules.

This is because Gleam only allows lower cased names to be parsed, but `ast-grep` metavariables are uppercased.

So in this example rule:

```yaml
rule:
  pattern: api_client.fetch_user($CLIENT, $ID)
fix: "api_client.fetch_user_with_timeout($CLIENT, $ID, timeout: 5000)"
```

`$CLIENT` and `$ID` cannot be captured correctly.

This repository supplies a patch for the current Gleam tree sitter repository, that you can apply like this:

```bash
git -C .ast-grep/tree-sitter-gleam apply ../../patches/tree-sitter-gleam-metavariables.patch
(cd .ast-grep/tree-sitter-gleam && tree-sitter generate)
```

This repository also contains examples of potential refactorings of some dummy modules, that you can try out.

```bash
ast-grep scan --rule refactors/add_fetch_timeout.yml --interactive
ast-grep scan --rule refactors/introduce_mail_message.yml --interactive
ast-grep scan --rule refactors/replace_bool_status.yml --interactive
```

## Caveats

With `ast-grep` we can find a lot of useful patterns to look for in Gleam code. However there are many limitations going off purely the AST
of our programs and limit the amount of information we can extract. These are limitations of ast-grep itself and not Gleam specific.

One example is type information. `ast-grep` fundamentally does not get any extra information about the types in your program. For this function:

```gleam
pub fn wibble() {
  "wobble"
}
```

`ast-grep` cannot figure out what return type it has. However, if you always make sure to add explicit return types to your functions like so:

```gleam
pub fn wibble() -> String {
  "wobble"
}
```

Then `ast-grep` rules can actually work with that. A linting rule you can use to make sure all of your functions have explicit return types can
look like this:

```yaml
id: explicit_return_type
language: gleam
severity: warning
message: Add an explicit return type
rule:
  all:
    - kind: function
    - not:
        has:
          field: return_type
          kind: type
```

More gotchas are documented in Gleams [tree-sitter](https://github.com/gleam-lang/tree-sitter-gleam/) repository: https://github.com/gleam-lang/tree-sitter-gleam/#various-gotchas
