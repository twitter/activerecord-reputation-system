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
        expect(@question.respond_to?(:add_evaluation)).to eq(true)
        expect(@answer.respond_to?(:add_evaluation)).to eq(true)
      end

      it "should not add 'add_evaluation' method to a model without primary reputation" do
        expect(@user.respond_to?(:add_evaluation)).to eq(false)
      end

      it "should add 'reputation_for' method to a model with reputation" do
        expect(@user.respond_to?(:reputation_for)).to eq(true)
        expect(@question.respond_to?(:reputation_for)).to eq(true)
      end

      it "should add 'normalized_reputation_for' method to a model with reputation" do
        expect(@user.respond_to?(:normalized_reputation_for)).to eq(true)
        expect(@question.respond_to?(:normalized_reputation_for)).to eq(true)
      end

      it "should delete reputations if target is deleted" do
        @question.add_evaluation(:total_votes, 5, @user)
        reputation_count = ReputationSystem::Reputation.count
        message_count = ReputationSystem::ReputationMessage.count
        @question.destroy
        expect(ReputationSystem::Reputation.count).to be < reputation_count
        expect(ReputationSystem::ReputationMessage.count).to be < message_count
      end
    end
  end

  context "Association" do
    describe "#reputations" do
      it "should define reputations association" do
        expect(@question.respond_to?(:reputations)).to eq(true)
      end
      it "should return all reputations for the target" do
        @question.add_evaluation(:total_votes, 2, @user)
        @question.add_evaluation(:difficulty, 2, @user)
        expect(@question.reputations.count).to eq(2)
      end
      describe "#for" do
        it "should return empty array if there is no reputation for the target" do
          expect(@question.reputations.for(:total_votes)).to eq([])
        end
        it "should return all reputations of the given type for the target" do
          @question.add_evaluation(:total_votes, 2, @user)
          @question.add_evaluation(:difficulty, 2, @user)
          expect(@question.reputations.for(:total_votes).count).to eq(1)
        end
      end
    end

    describe "#evaluations" do
      it "should define evaluations association" do
        expect(@question.respond_to?(:evaluations)).to eq(true)
      end
      it "should return all evaluations for the target" do
        @question.add_evaluation(:total_votes, 2, @user)
        @question.add_evaluation(:difficulty, 2, @user)
        expect(@question.evaluations.count).to eq(2)
      end
      describe "#for" do
        it "should return empty array if there is no evaluation for the target" do
          expect(@question.evaluations.for(:total_votes)).to eq([])
        end
        it "should return all evaluations of the given type for the target" do
          @question.add_evaluation(:total_votes, 2, @user)
          @question.add_evaluation(:difficulty, 2, @user)
          expect(@question.evaluations.for(:total_votes).count).to eq(1)
        end
      end
    end
  end
end
