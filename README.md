## ActiveRecord Reputation System  [![Build Status](https://secure.travis-ci.org/twitter/activerecord-reputation-system.png)](http://travis-ci.org/twitter/activerecord-reputation-system) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/twitter/activerecord-reputation-system)

The Active Record Reputation System helps you discover more about your application and make better decisions. The Reputation System gem makes it easy to integrate reputation systems into Rails applications, decouple the system from the main application and provide guidelines for good design of reputation systems.

## Installation

Add to Gemfile:

```ruby
gem 'activerecord-reputation-system', :require => 'reputation_system'
```

Run:

```ruby
bundle install
rails generate reputation_system
rake db:migrate
```

* Please do the installation on every upgrade as it may include new migration files.

## Quick Start 

Let's say we want to keep track of user karma in Q&A site where user karma is sum of questioning skill and answering skill. Questioning skill is sum of votes for user's questions and Answering skill is sum of average rating of user's answers. This can be defined as follow:
```ruby
class User < ActiveRecord::Base
  has_many :answers
  has_many :questions

  has_reputation :karma,
      :source => [
          { :reputation => :questioning_skill, :weight => 0.8 },
          { :reputation => :answering_skill }],
      :aggregated_by => :sum

  has_reputation :questioning_skill,
      :source => { :reputation => :votes, :of => :questions },
      :aggregated_by => :sum

  has_reputation :answering_skill,
      :source => { :reputation => :avg_rating, :of => :answers },
      :aggregated_by => :sum
end

class Answer < ActiveRecord::Base
  belongs_to :user, :as => :author

  has_reputation :avg_rating,
      :source => :user,
      :aggregated_by => :average,
      :source_of => [{ :reputation => :answering_skill, :of => :author }]
end


class Question < ActiveRecord::Base
  belongs_to :user

  has_reputation :votes,
      :source => :user,
      :aggregated_by => :sum
end
```

Once reputation system is defined, evaluations for answers and questions can be added as follow:
```ruby
@answer.add_evaluation(:avg_rating, 3, @user)
@question.add_evaluation(:votes, 1, @user)
```

Reputation value can be accessed as follow:
```ruby
@answer.reptuation_for(:avg_rating)
@question.reptuation_for(:votes)
@user.reptuation_for(:karma)
```

## Documentation

Please refer [Wiki](https://github.com/twitter/activerecord-reputation-system/wiki) for available APIs.

## Authors

* [Katsuya Noguchi](http://github.com/katsuyan)([@kn](https://twitter.com/kn))
* Inspired by ["Building Web Reputation Systems" by Randy Farmer and Bryce Glass](http://shop.oreilly.com/product/9780596159801.do)

## Contributors

1. [NARKOZ (Nihad Abbasov)](https://github.com/NARKOZ) - 4 commits
2. [elitheeli (Eli Fox-Epstein)](https://github.com/elitheeli) - 1 commit
3. [amrnt (Amr Tamimi)](https://github.com/amrnt) - 1 commit

## Related Links

* RailsCasts: http://railscasts.com/episodes/364-active-record-reputation-system

## Versioning

For transparency and insight into our release cycle, releases will be numbered with the follow format:

`<major>.<minor>.<patch>`

And constructed with the following guidelines:

* Breaking backwards compatibility bumps the major
* New additions without breaking backwards compatibility bumps the minor
* Bug fixes and misc changes bump the patch

For more information on semantic versioning, please visit http://semver.org/.

## License

Copyright 2012 Twitter, Inc.

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
