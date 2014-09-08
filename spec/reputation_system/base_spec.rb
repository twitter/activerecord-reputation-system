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

describe ReputationSystem::Base do

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

      it "should add 'reputation_for' method to a model with reputation" do
        @user.respond_to?(:reputation_for).should == true
        @question.respond_to?(:reputation_for).should == true
      end

      it "should add 'normalized_reputation_for' method to a model with reputation" do
        @user.respond_to?(:normalized_reputation_for).should == true
        @question.respond_to?(:normalized_reputation_for).should == true
      end

      it "should delete reputations if target is deleted" do
        @question.add_evaluation(:total_votes, 5, @user)
        reputation_count = ReputationSystem::Reputation.count
        message_count = ReputationSystem::ReputationMessage.count
        @question.destroy
        ReputationSystem::Reputation.count.should < reputation_count
        ReputationSystem::ReputationMessage.count.should < message_count
      end
    end
  end

  context "Association" do
    describe "#reputations" do
      it "should define reputations association" do
        @question.respond_to?(:reputations).should == true
      end
      it "should return all reputations for the target" do
        @question.add_evaluation(:total_votes, 2, @user)
        @question.add_evaluation(:difficulty, 2, @user)
        @question.reputations.count.should == 2
      end
      describe "#for" do
        it "should return empty array if there is no reputation for the target" do
          @question.reputations.for(:total_votes).should == []
        end
        it "should return all reputations of the given type for the target" do
          @question.add_evaluation(:total_votes, 2, @user)
          @question.add_evaluation(:difficulty, 2, @user)
          @question.reputations.for(:total_votes).count.should == 1
        end
      end
    end

    describe "#evaluations" do
      it "should define evaluations association" do
        @question.respond_to?(:evaluations).should == true
      end
      it "should return all evaluations for the target" do
        @question.add_evaluation(:total_votes, 2, @user)
        @question.add_evaluation(:difficulty, 2, @user)
        @question.evaluations.count.should == 2
      end
      describe "#for" do
        it "should return empty array if there is no evaluation for the target" do
          @question.evaluations.for(:total_votes).should == []
        end
        it "should return all evaluations of the given type for the target" do
          @question.add_evaluation(:total_votes, 2, @user)
          @question.add_evaluation(:difficulty, 2, @user)
          @question.evaluations.for(:total_votes).count.should == 1
        end
      end
    end
  end
end
