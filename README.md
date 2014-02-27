# lita-travis

[![Build Status](https://travis-ci.org/jimmycuadra/lita-travis.png?branch=master)](https://travis-ci.org/jimmycuadra/lita-travis)
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

* `repos` (Hash) - A hash of repositories names and the chat rooms to post their notifications in. The keys should be strings in the format "github_username/repository_name" and the values should be either a string room name or an array of string room names. Default: `{}`.
* `default_rooms` (String, Array&lt;String&gt;) - A string room name or an array of string room names where notifications for repositories not explicitly specified in the `repos` hash should be sent. If `nil`, notifications for unknown repositories will be ignored. Default: `nil`.

### Example

``` ruby
Lita.configure do |config|
  config.handlers.travis.token = "abcdefg123"
  config.handlers.travis.repos = {
    "username/repo1" => "#repo1_team",
    "username/repo2" => ["#repo2_team", "#other_team"]
  }
  config.handlers.travis.default_rooms = "#engineering"
end
```

## Usage

Set the configuration attributes as described in the section above, and add the following to the `.travis.yml` file for each project you want to get build notifications for:

``` yml
notifications:
  webhooks:
    urls:
      - http://example.com/travis
```

Replace "example.com" with the hostname where your instance of Lita is running.

See Travis CI's [documentation on notifications](http://about.travis-ci.org/docs/user/notifications/) for additional options.

## License

[MIT](http://opensource.org/licenses/MIT)
