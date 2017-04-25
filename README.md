# auto-tag

Automatically create a release tag based on the date.

## Installation

```sh
git clone git@github.com:jwaldrip:auto-tag.git
cd auto-tag
shards build --release -o /usr/local/bin/auto-tag
```

## Usage

```sh
# Within a git repo
GITHUB_TOKEN=abc123 auto-tag
```

## Contributing

1. Fork it ( https://github.com/jwaldrip/auto-tag/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[jwaldrip]](https://github.com/[jwaldrip]) Jason Waldrip - creator, maintainer
