## Active Record Reputation System  [![Build Status](https://secure.travis-ci.org/twitter/activerecord-reputation-system.png)](http://travis-ci.org/twitter/activerecord-reputation-system)

The Active Record Reputation System helps you discover more about your application and make better decisions. The Reputation System gem makes it easy to integrate reputation systems into Rails applications, decouple the system from the main application and provide guidelines for good design of reputation systems.

## Concept

In this gem, the reputation system is described as a network of reputations where updates are triggered by evaluations and reputation values are computed and propagated by the network. In this network, reputations with values directly computed from evaluations are called primary reputations and reputations with values indirectly computed from evaluations are called non-primary reputations. The following is an abstract view of a possible Reputation System:

![Alt text](./activerecord-reputation-system/raw/master/abs_rs.png "Abstract view of Reputation System")

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

## Usage Example

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
@answer.reputation_value_for(:avg_rating)
@question.reputation_value_for(:votes)
@user.reputation_value_for(:karma)
```

## Defining Reputation System

All reputations can be defined in their target ActiveRecord models like this:
```ruby
# Primary Reputation
has_reputation  :name,
        :source => source,
        :aggregated_by => process,
        :source_of => [{:reputation => name, :of => attribute}, ...],
        :init_value => initial_value

# Non Primary Reputation
has_reputation  :name,
        :source => [{:reputation => name, :of => attribute, :weight => weight}, ...],
        :aggregated_by => process,
        :source_of => [{:reputation => name, :of => attribute}, ...],
        :init_value => initial_value
```
* :name is the name of the reputation.
* :source is a source of the reputation. If it is primary reputation, it takes a class name as input. If it's a non-primary reputation, it takes one or more source definitions, which consist of:
** :reputation - name of reputation to be used as a source.
** :of - attribute name (It also accepts a proc as an argument) of the ActiveRecord model which has the source reputation. (default: :self)
** :weight (optional) - weight value to be used for aggregation (default: 1).
* :aggregated_by is a mathematical process to be used to aggregate reputation or evaluation values. The following processes are available (each value is weighted by a predefined weight):
** average - averages all values received.
** sum - sums up all the values received.
** product - multiplies all the values received.
* :source_of (optional) - just like active record association, you don't need to define this if a name can be derived from class name; otherwise if the reputation is used as a part of a source belonging to other reputations, you must define. It takes one or more source definitions, which consists of:
** :reputation - name of the reputation to be used as a source.
** :of - attribute name (It also accepts a proc as an argument) of the ActiveRecord model which has the source reputation. (default: :self)
* :init_value (optional) - initial reputation value assigned to new reputation. It is 0 for average and sum process and 1 for product by default.

## Evaluation
```ruby
# Adds an evaluation to the reputation with the specified name.
add_evaluation(reputation_name, evaluation_value, source)

# Updates an existing evaluation of the reputation with the specified name by the specified source.
update_evaluation(reputation_name, evaluation_value, source)

# Adds an evaluation to the reputation with the specified name if it exists; otherwise it updates the existing reputation.
add_or_update_evaluation(reputation_name, evaluation_value, source)

# Deletes an evaluation from the reputation with the specified name submitted by the specified source. It returns nil if it does not exist.
delete_evaluation(reputation_name, source)

# Deletes an evaluation from the reputation with the specified name submitted by specified source. Raises an exception if it does not exist.
delete_evaluation!(reputation_name, source)

# Checks if object has an evaluation submitted by specified source.
has_evaluation?(reputation_name, source)

```

## Reputation
```ruby
# Returns the reputation value of the reputation with the given name.
reputation_value_for(reputation_name)

# Returns the reputation rank of the reputation with the given name.
rank_for(reputation_name)

# Returns the normalized reputation value of the reputation with the given name. The normalization is computed using the following equation (assuming linear distribution):
# normalized_value = (x - min) / (max - min) if max - min&nbsp;﻿is not 0
# normalized_value = 1 if max - min is 0
normalized_reputation_value_for(reputation_name)

# Activates all reputations in the record. Active reputations are used when computing ranks or normalized reputation values.
activate_all_reputations

# Deactivates all reputations in the record. Inactive reputations are not used when computing ranks or normalized reputation values.
deactivate_all_reputations

# Checks if reputation is active.
reputations_activated?(reputation_name)
```

## Querying with Reputation
```ruby
# Includes the specified reputation value for the given name via a normal Active Record find query.
ActiveRecord::Base.find_with_reputation(reputation_name, find_scope, options)
# For example:
User.find_with_reputation(:maturity, :all, {:select => "id", :conditions => ["maturity > ?", 3], :order => "maturity"})

# Includes the specified normalized reputation value for the given name via a normal Active Record find query.
ActiveRecord::Base.find_with_normalized_reputation(reputation_name, find_options)
# For example:
User.find_with_normalized_reputation(:maturity, :all, {:select => "id", :conditions => ["maturity > ?", 3], :order => "maturity"})

# Includes the specified reputation value for the given name via a normal Active Record count query.
ActiveRecord::Base.count_with_reputation(reputation_name, find_options)

# This method returns a SQL statement rather than a query result.
ActiveRecord::Base.find_with_reputation_sql(reputation_name, find_options)
```

## Advanced Topics
### Scope
Reputations can have different scopes to provide additional context.

For example, let's say `question` has a reputation called `difficulty`.  You might want to keep track of that reputation by country, such that each question has a different difficulty rating in each country.

Scopes can be defined like this:
```ruby
has_reputation :difficulty,
    ...
    :scopes => [:country1, :country2, ...]
```
Once scopes are defined, evaluations can be added in the context of defined scopes:
```ruby
add_evaluation(:reputation_name, value, source, :scope)
# For example:
@question.add_evaluation(:difficulty, 1, @user, :country2)
```
Also, reputations can be accessed in the context of scopes:
```ruby
reputation_value_for(:reputation_name, :scope)
# For example:
@question.reputation_value_for(:difficulty, :country2)
```
To use a scoped reputation as a source in another reputation, try this:
```ruby
has_reputation :rep1,
    :source => {:reputation => :rep2, :scope => :scope1}
    ...
has_reputation :rep2,
    ...
    :scopes => [:scope1, :scope2, ...],
    :source_of => {:reputation => :rep1, :defined_for_scope => [:scope1]}
```
To execute an Active Record query using a scoped reputation, try this:
```ruby
ActiveRecord::Base.find_with_reputation(:reputation_name, :scope, :find_options)
# For example:
Question.find_with_reputation(:difficulty, :country1, :all, {:select => "id", :conditions => ["maturity > ?", 3], :order => "maturity"})

```
There are a few more helper methods available for scopes:
```ruby
# Allows you to add a scope dynamically.
add_scope_for(reputation_name, scope)
# For example:
Question.add_scope_for(:difficulty, :country3)

# Returns true if the reputation has scopes.
has_scopes?(reputation_name)
# For example:
Question.has_scopes?(:difficulty)

# Returns true if the reputation has a given scope.
has_scope?(reputation_name, scope)
# For example:
Question.has_scope?(:difficulty, :country1)

# Checks if a scoped evaluation has been submitted by specified source.
has_evaluation?(:reputation_name, source, :scope)
# For example:
Question.has_evaluation?(:difficulty, current_user, :country1)
```

### Performance

For applications with large data set, computation of reputation values can be expensive. Therefore, it is common to perform the computation asynchronously (in batch). If you wish to asynchronously compute reputation values, I strongly recommend you to use [collectiveidea's Delayed Job](https://github.com/collectiveidea/delayed_job). For example:

```ruby
class User < ActiveRecord
  has_reputation :karma,
    :source => :user,
    :aggregated_by => :sum

  handle_asynchronously :add_evaluation
  handle_asynchronously :update_evaluation
  handle_asynchronously :delete_evaluation
end
```

### Reflect Past Data

If you wish to reflect past data into new reputation system, I recommend you write a script which simulates all evaluations that would have happened in the past. You probably want to use [collectiveidea's Delayed Job](https://github.com/collectiveidea/delayed_job) to enqueue those past evaluation tasks first and then new ongoing evaluation task so that evaluations are performed in proper time sequence.

## Running Tests

`rake` should do the trick. Tests are written in RSpec.

## Versioning

For transparency and insight into our release cycle, releases will be numbered with the follow format:

`<major>.<minor>.<patch>`

And constructed with the following guidelines:

* Breaking backwards compatibility bumps the major
* New additions without breaking backwards compatibility bumps the minor
* Bug fixes and misc changes bump the patch

For more information on semantic versioning, please visit http://semver.org/.

## Authors

* Katsuya Noguchi: http://github.com/katsuyan
* Inspired by ["Building Web Reputation Systems" by Randy Farmer and Bryce Glass](http://shop.oreilly.com/product/9780596159801.do)

## License

Copyright 2012 Twitter, Inc.

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
