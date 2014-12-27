## ActiveRecord Reputation System  [![Build Status](https://travis-ci.org/twitter/activerecord-reputation-system.svg?branch=master)](https://travis-ci.org/twitter/activerecord-reputation-system) [![Code Climate](https://codeclimate.com/github/twitter/activerecord-reputation-system/badges/gpa.svg)](https://codeclimate.com/github/twitter/activerecord-reputation-system)

The Active Record Reputation System helps you build the reputation system for your Rails application. It allows Active Record to have reputations and get evaluated by other records. This gem allows you to:
* define reputations in easily readable way.
* integrate reputation systems into applications and decouple the system from the main application.
* discover more about your application and make better decisions.

## Installation

* If you are updating to version 2 from version older, you should check out [migration guide](https://github.com/twitter/activerecord-reputation-system/wiki/Migrate-to-Version-2.0).

* **For Rails 3 use versions 2.0.2 and older.**

Add to Gemfile:

```ruby
gem 'activerecord-reputation-system'
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
          { :reputation => :answering_skill }]

  has_reputation :questioning_skill,
      :source => { :reputation => :votes, :of => :questions }

  has_reputation :answering_skill,
      :source => { :reputation => :avg_rating, :of => :answers }
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
      :source => :user
end
```

Once reputation system is defined, evaluations for answers and questions can be added as follow:
```ruby
@answer.add_evaluation(:avg_rating, 3, @user)
@question.add_evaluation(:votes, 1, @user)
```

Reputation value can be accessed as follow:
```ruby
@answer.reputation_for(:avg_rating) #=> 3
@question.reputation_for(:votes) #=> 1
@user.reputation_for(:karma)
```

You can query for records using reputation value:
```ruby
User.find_with_reputation(:karma, :all, { :condition => 'karma > 10' })
```

You can get source records that have evaluated the target record:
```ruby
@question.evaluators_for(:votes) #=> [@user]
```

You can get target records that have been evaluated by a given source record:
```ruby
Question.evaluated_by(:votes, @user) #=> [@question]
```

To use a custom aggregation function you need to provide the name of the method
on the `:aggregated_by option`, and implement this method on the model.
On the example below, our aggregation function sums all values and multiply by ten:
```ruby
class Answer < ActiveRecord::Base
  belongs_to :author, :class_name => 'User'
  belongs_to :question

  has_reputation :custom_rating,
    :source => :user,
    :aggregated_by => :custom_aggregation

  def custom_aggregation(*args)
    rep, source, weight = args[0..2]

    # Ruby doesn't support method overloading, so let's handle parameters on a condition

    # For a new source, these are the input parameters:
    # rep, source, weight
    if args.length == 3
      rep.value + weight * source.value * 10

    # For an updated source, these are the input parameters:
    # rep, source, weight, oldValue, newSize
    elsif args.length == 5
      oldValue, newSize = args[3..4]
      rep.value + (source.value - oldValue) * 10
    end
  end
end
```

## Documentation

Please refer [Wiki](https://github.com/twitter/activerecord-reputation-system/wiki) for available APIs and more information.

## Authors

Katsuya Noguchi
* [http://twitter.com/kn](http://twitter.com/kn)
* [http://github.com/kn](http://github.com/kn)

## Related Links

* RailsCasts: http://railscasts.com/episodes/364-active-record-reputation-system
* Inspired by ["Building Web Reputation Systems" by Randy Farmer and Bryce Glass](http://shop.oreilly.com/product/9780596159801.do)

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
