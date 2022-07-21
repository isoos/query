## 2.0.0

**Breaking changes**
- `FieldScope.field`, `FieldCompareQuery.field` and `FieldCompareQuery.operator` are now a `TextQuery`.
- `field:<exp>` and `field <operator> <exp>`: `<exp>` can now be an empty string.
- `TextQuery.isExact` and `PhraseQuery.isExact` are removed. `PhraseQuery` is always exact and `TextQuery` never is.

**Updated**
- Added `SourcePosition` to `Query`, storing the `start` and `end` index of the matching input.

## 1.6.0

- Upgraded `petitparser` to `5.0.0`.

## 1.5.0

- Migrated to new `petitparser` API (`ref`).
- Deprecated non-public API `QueryParser`, use `QueryGrammarDefinition.build` instead.
- Fixed grammar issues [#6](https://github.com/isoos/query/pull/6) by [North101](https://github.com/North101).

## 1.4.0

- Migrated to null safety.

## 1.3.0

- nested groups
- `|` as alias for `OR`
- phrase search expression contain the separate words/phrases as a children list

Thanks to [edyu](https://github.com/edyu) on [#3](https://github.com/isoos/query/pull/3).

## 1.2.0

- Update sources to Dart 2.3 SDK and lints.

## 1.1.2

- More lints and checks in `analysis_options.yaml`.

## 1.1.1

- Support for new `petitparser` API.

## 1.1.0

- Support for non-ASCII characters in scope and words.

## 1.0.0

- Initial version.
