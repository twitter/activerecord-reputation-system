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

  context "Mixin" do
    describe "#has_reputation" do
      it "should add 'add_evaluation' method to a model with primary reputation" do
        @question.respond_to?(:add_evaluation).should == true
        @answer.respond_to?(:add_evaluation).should == true
      end

      it "should not add 'add_evaluation' method to a model without primary reputation" do
        @user.respond_to?(:add_evaluation).should == false
      end

      it "should add 'reputation_value_for' method to a model with reputation" do
        @user.respond_to?(:reputation_value_for).should == true
        @question.respond_to?(:reputation_value_for).should == true
      end

      it "should add 'normalized_reputation_value_for' method to a model with reputation" do
        @user.respond_to?(:normalized_reputation_value_for).should == true
        @question.respond_to?(:normalized_reputation_value_for).should == true
      end

      it "should delete reputations if target is deleted" do
        @question.add_evaluation(:total_votes, 5, @user)
        reputation_count = RSReputation.count
        message_count = RSReputationMessage.count
        @question.destroy
        RSReputation.count.should < reputation_count
        RSReputationMessage.count.should < message_count
      end

      it "should have declared default value if any" do
        @answer.reputation_value_for(:avg_rating).should == 1
      end

      it "should overwrite reputation definitions if the same reputation name is declared" do
        Answer.has_reputation(:avg_rating, :source => :user, :aggregated_by => :average, :init_value => 2)
        Answer.new.reputation_value_for(:avg_rating).should == 2
      end
    end
  end
end
