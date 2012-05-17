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

require 'spec_helper'

describe ActiveRecord::Base do

  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
    @answer = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => @question.id)
    @phrase = Phrase.create!(:text => "One")
  end

  describe "#normalized_reputation_value_for" do
    it "should return 0 as if there is no data" do
      @question.normalized_reputation_value_for(:total_votes).should == 0
    end

    it "should return appropriate value in case of valid input" do
      question2 = Question.create!(:text => 'Does this work too?', :author_id => @user.id)
      question3 = Question.create!(:text => 'Does this work too?', :author_id => @user.id)
      @question.add_evaluation(:total_votes, 1, @user)
      question2.add_evaluation(:total_votes, 2, @user)
      question3.add_evaluation(:total_votes, 3, @user)
      @question.normalized_reputation_value_for(:total_votes).should == 0
      question2.normalized_reputation_value_for(:total_votes).should == 0.5
      question3.normalized_reputation_value_for(:total_votes).should == 1
    end

    it "should raise exception if invalid reputation name is given" do
      lambda {@question.normalized_reputation_value_for(:invalid)}.should raise_error(ArgumentError)
    end

    it "should raise exception if scope is given for reputation with no scopes" do
      lambda {@question.normalized_reputation_value_for(:difficulty, :s1)}.should raise_error(ArgumentError)
    end

    it "should raise exception if scope is not given for reputation with scopes" do
      lambda {@phrase.normalized_reputation_value_for(:difficulty_with_scope)}.should raise_error(ArgumentError)
    end
  end

  describe "#exclude_all_reputations_for_normalization" do
    it "should activate all reputation" do
      @question2 = Question.create!(:text => 'Does this work??', :author_id => @user.id)
      @question2.add_evaluation(:total_votes, 70, @user)
      @question.add_evaluation(:total_votes, 100, @user)
      @question.deactivate_all_reputations
      RSReputation.maximum(:value, :conditions => {:reputation_name => 'total_votes', :active => true}).should == 70
      @question.activate_all_reputations
      RSReputation.maximum(:value, :conditions => {:reputation_name => 'total_votes', :active => true}).should == 100
    end
  end
end