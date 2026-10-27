# Parsers for model responses

A parser is a function that turns the raw text response of the backend
into a single value: a number, a category label, or `NA` if the response
cannot be interpreted. Parse failures are recorded in the run log and
reported as part of the validation (a response that cannot be parsed is
a failed measurement).

## Usage

``` r
parse_identity(text)

parse_number(decimal = ".")

parse_choice(levels, aliases = NULL, whole_word = FALSE)

parse_json_field(field)
```

## Arguments

- text:

  The raw response text (argument of the returned parser and of
  `parse_identity()`).

- decimal:

  Decimal mark for `parse_number()`.

- levels:

  For `parse_choice()`: the admissible labels, in the order that defines
  the ordinal scale. Matching is case-insensitive; the longest label
  occurring in the response wins, so that "likely pathogenic" is not
  matched as "pathogenic".

- aliases:

  Optional named list mapping additional strings to labels, e.g.
  `list("LP" = "Likely pathogenic")`.

- whole_word:

  If `TRUE`, split at non-alphanumeric characters and match complete
  word sequences, longest first. Matched words are consumed; different
  labels in one response give `NA`. Repeated matches of the same label
  are allowed. The default retains the substring parser.

- field:

  For `parse_json_field()`: the name of the field to extract from a JSON
  object in the response (the first `{...}` block is used).

## Value

A function with signature `function(text)` returning a length-one value.

## Examples

``` r
parse_number()("The IC50 is approximately 12.5 nM.")
#> [1] 12.5
parse_choice(c("Benign", "Likely benign", "VUS", "Likely pathogenic", "Pathogenic"))(
  "Classification: likely pathogenic (PS1, PM2)")
#> [1] "Likely pathogenic"
parse_json_field("class")('Result: {"class": "VUS", "criteria": ["PM2"]}')
#> [1] "VUS"
```
