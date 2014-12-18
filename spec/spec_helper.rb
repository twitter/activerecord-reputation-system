##
#  Copyright 2012 Twitter, Inc
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##

require 'active_record'
require 'database_cleaner'
require 'sqlite3'
require 'reputation_system'

DELTA = 0.000001

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :rs_evaluations do |t|
    t.string      :reputation_name
    t.references  :source, :polymorphic => true
    t.references  :target, :polymorphic => true
    t.float       :value, :default => 0
    t.text        :data
    t.timestamps
  end

  add_index :rs_evaluations, :reputation_name
  add_index :rs_evaluations, [:target_id, :target_type]
  add_index :rs_evaluations, [:source_id, :source_type]

  create_table :rs_reputations do |t|
    t.string      :reputation_name
    t.float       :value, :default => 0
    t.string      :aggregated_by
    t.references  :target, :polymorphic => true
    t.boolean     :active, :default => true
    t.text        :data
    t.timestamps
  end

  add_index :rs_reputations, :reputation_name
  add_index :rs_reputations, [:target_id, :target_type]

  create_table :rs_reputation_messages do |t|
    t.references  :sender, :polymorphic => true
    t.integer     :receiver_id
    t.float       :weight, :default => 1
    t.timestamps
  end

  add_index :rs_reputation_messages, [:sender_id, :sender_type]
  add_index :rs_reputation_messages, :receiver_id

  create_table :users do |t|
    t.string :name
    t.timestamps
  end

  create_table :answers do |t|
    t.integer :author_id
    t.integer :question_id
    t.string :text
    t.timestamps
  end

  create_table :questions do |t|
    t.integer :author_id
    t.string :text
    t.timestamps
  end

  create_table :phrases do |t|
    t.string :text
    t.timestamps
  end

  create_table :translations do |t|
    t.integer :user_id
    t.integer :phrase_id
    t.string  :text
    t.string  :locale
    t.timestamps
  end

  create_table :people do |t|
    t.string :name
    t.string :type
    t.timestamps
  end

  create_table :posts do |t|
    t.string :name
    t.timestamps
  end
end

class User < ActiveRecord::Base
  has_many :answers, :foreign_key => 'author_id', :class_name => 'Answer'
  has_many :questions, :foreign_key => 'author_id', :class_name => 'Question'

  has_reputation :karma,
    :source => [
      { :reputation => :question_karma },
      { :reputation => :answer_karma, :weight => 0.2 }],
    :aggregated_by => :product

  has_reputation :question_karma,
    :source => { :reputation => :total_votes, :of => :questions },
    :aggregated_by => :sum

  has_reputation :answer_karma,
    :source => { :reputation => :weighted_avg_rating, :of => :answers },
    :aggregated_by => :average

  has_reputation :custom_rating,
    :source => { :reputation => :custom_rating, :of => :answers },
    :aggregated_by => :custom_rating

  def custom_process
    123
  end
end

class Question < ActiveRecord::Base
  belongs_to :author, :class_name => 'User'
  has_many :answers

  has_reputation :total_votes,
    :source => :user,
    :source_of => { :reputation => :question_karma, :of => :author }

  has_reputation :difficulty,
    :source => :user,
    :aggregated_by => :average
end

class Answer < ActiveRecord::Base
  belongs_to :author, :class_name => 'User'
  belongs_to :question

  has_reputation :weighted_avg_rating,
    :source => [
      { :reputation => :avg_rating },
      { :reputation => :difficulty, :of => :question }],
    :aggregated_by => :product,
    :source_of => { :reputation => :answer_karma, :of => :author }

  has_reputation :avg_rating,
    :source => :user,
    :aggregated_by => :average

  has_reputation :custom_rating,
    :source => :user,
    :aggregated_by => :custom_aggregation,
    :source_of => { :reputation => :custom_rating, :of => :author }

  def custom_aggregation(*args)
    rep, source, weight = args[0..2]
    # rep, source, weight
    if args.length === 3
      rep.value + weight * source.value * 10
    # rep, source, weight, oldValue, newSize
    elsif args.length === 5
      oldValue, newSize = args[3..4]
      rep.value + (source.value - oldValue) * 10
    end
  end
end

class Phrase < ActiveRecord::Base
  has_many :translations do
    def for(locale)
      self.where(:locale => locale.to_s).to_a
    end
  end

  has_reputation :maturity_all,
    :source => [
      { :reputation => :maturity, :of => :self, :scope => :ja },
      { :reputation => :maturity, :of => :self, :scope => :fr }],
    :aggregated_by => :sum

  has_reputation :maturity,
    :source => { :reputation => :votes, :of => lambda {|this, s| this.translations.for(s)} },
    :aggregated_by => :sum,
    :scopes => [:ja, :fr, :de],
    :source_of => { :reputation => :maturity_all, :of => :self, :defined_for_scope => [:ja, :fr] }

  has_reputation :maturity_of_all_translations,
    :source => { :reputation => :votes, :of => :translations },
    :aggregated_by => :sum,
    :scopes => [:ja, :fr, :de]

  has_reputation :difficulty_with_scope,
    :source => :user,
    :aggregated_by => :average,
    :scopes => [:s1, :s2, :s3]
end

class Translation < ActiveRecord::Base
  belongs_to :user
  belongs_to :phrase

  has_reputation :votes,
    :source => :user,
    :aggregated_by => :sum,
    :source_of => [
      { :reputation => :maturity, :of => :phrase, :scope => :locale},
      { :reputation => :maturity_of_all_translations, :of => :phrase, :scope => :locale}
    ]
end

# For STI Specs

class Person < ActiveRecord::Base
  has_reputation :leadership,
    :source => :person,
    :aggregated_by => :sum
end

class Programmer < Person
end

class Designer < Person
end

class Post < ActiveRecord::Base
  belongs_to :person

  has_reputation :votes,
    :source => :person
end
