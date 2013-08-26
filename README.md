# lita-travis

[![Build Status](https://travis-ci.org/jimmycuadra/lita-travis.png)](https://travis-ci.org/jimmycuadra/lita-travis)
[![Code Climate](https://codeclimate.com/github/jimmycuadra/lita-travis.png)](https://codeclimate.com/github/jimmycuadra/lita-travis)
[![Coverage Status](https://coveralls.io/repos/jimmycuadra/lita-travis/badge.png)](https://coveralls.io/r/jimmycuadra/lita-travis)

**lita-travis** is a [Lita](https://github.com/jimmycuadra/lita) handler for receiving notifications from [Travis CI](https://travis-ci.org/). When Travis is configured to post notifications to your Lita instance, Lita will announce the results of project builds in chat rooms of your choice.

## Installation

Add lita-travis to your Lita instance's Gemfile:

``` ruby
gem "lita-travis"
```

## Configuration

### Required attributes

* `token` (String) - Your Travis CI secret token, found on your profile page on the Travis website. Default: `nil`.

### Optional attributes

* `repos` (Hash) - A map of repositories to allow notifications for and the chat rooms to post them in. The keys should be strings in the format "github_username/repository_name" and the values should be either a string room name or an array of string room names. Default: `{}`.

### Example

``` ruby
Lita.configure do |config|
  config.handlers.travis.token = "abcdefg123"
  config.handlers.travis.repos = {
    "username/repo1" => "#someroom",
    "username/repo2" => ["#someroom", "#someotherroom"]
  }
end
```

## Usage

Set the configuration attributes as described in the section above, and add the following to the `.travis.yml` file for each project you want to get build notifications for:

``` yml
notifications:
  webhooks:
    urls:
      - http://your.lita.instance.example.com/travis
```

See Travis CI's [documentation on notifications](http://about.travis-ci.org/docs/user/notifications/) for additional options.

## License

[MIT](http://opensource.org/licenses/MIT)
