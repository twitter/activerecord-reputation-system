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

describe ReputationSystem::ReputationMethods do

  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
    @answer = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => @question.id)
    @phrase = Phrase.create!(:text => "One")
  end

  context "Primary Reputation" do
    describe "#reputation_for" do
      it "should return 0 as a default" do
        expect(@question.reputation_for(:total_votes)).to eq(0)
      end

      it "should return appropriate value in case of valid input" do
        user2 = User.new(:name => 'dick')
        @question.add_evaluation(:total_votes, 1, @user)
        @question.add_evaluation(:total_votes, 1, user2)
        expect(@question.reputation_for(:total_votes)).to eq(2)
      end

      it "should raise exception if invalid reputation name is given" do
        expect {@question.reputation_for(:invalid)}.to raise_error(ArgumentError)
      end

      it "should raise exception if scope is given for reputation with no scopes" do
        expect {@question.reputation_for(:difficulty, :s1)}.to raise_error(ArgumentError)
      end

      it "should raise exception if scope is not given for reputation with scopes" do
        expect {@phrase.reputation_for(:difficulty_with_scope)}.to raise_error(ArgumentError)
      end
    end

    describe "#rank_for" do
      context "without scope" do
        before :each do
          @question.add_evaluation(:total_votes, 3, @user)
          @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
          @question2.add_evaluation(:total_votes, 5, @user)
        end

        it "should return rank properly" do
          expect(@question.rank_for(:total_votes)).to eq(2)
          expect(@question2.rank_for(:total_votes)).to eq(1)
        end
      end

      context "with scope" do
        before :each do
          @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
          @trans_ja.add_evaluation(:votes, 3, @user)
          @phrase2 = Phrase.create!(:text => "One")
          @trans_fr = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase2)
          @trans_fr.add_evaluation(:votes, 6, @user)
        end

        it "should return rank properly" do
          expect(@phrase.rank_for(:maturity, :ja)).to eq(2)
          expect(@phrase2.rank_for(:maturity, :ja)).to eq(1)
        end
      end
    end
  end

  context "Non-Primary Reputation with Gathering Aggregation" do
    describe "#reputation_for" do
      it "should always have correct updated value" do
        question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        expect(@user.reputation_for(:question_karma)).to eq(0)
        @question.add_evaluation(:total_votes, 1, @user)
        expect(@user.reputation_for(:question_karma)).to eq(1)
        question2.add_evaluation(:total_votes, 1, @user)
        expect(@user.reputation_for(:question_karma)).to eq(2)
      end
    end
  end

  context "Non-Primary Reputation with Mixing Aggregation" do
    describe "#reputation_for" do
      it "should always have correct updated value" do
        question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        question.add_evaluation(:difficulty, 1, @user)
        question2.add_evaluation(:difficulty, 2, @user)
        question.add_evaluation(:total_votes, 1, @user)
        question2.add_evaluation(:total_votes, 1, @user)
        answer = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => question.id)
        answer2 = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => question2.id)
        answer.add_evaluation(:avg_rating, 3, @user)
        answer2.add_evaluation(:avg_rating, 2, @user)
        expect(answer.reputation_for(:weighted_avg_rating)).to eq(3)
        expect(answer2.reputation_for(:weighted_avg_rating)).to eq(4)
        expect(@user.reputation_for(:answer_karma)).to be_within(DELTA).of(3.5)
        expect(@user.reputation_for(:question_karma)).to be_within(DELTA).of(2)
        expect(@user.reputation_for(:karma)).to be_within(DELTA).of(1.4)
      end
    end
  end

  context "Normalization" do
    describe "#normalized_reputation_for" do
      it "should return 0 as if there is no data" do
        expect(@question.normalized_reputation_for(:total_votes)).to eq(0)
      end

      it "should return appropriate value in case of valid input" do
        question2 = Question.create!(:text => 'Does this work too?', :author_id => @user.id)
        question3 = Question.create!(:text => 'Does this work too?', :author_id => @user.id)
        @question.add_evaluation(:total_votes, 1, @user)
        question2.add_evaluation(:total_votes, 2, @user)
        question3.add_evaluation(:total_votes, 3, @user)
        expect(@question.normalized_reputation_for(:total_votes)).to eq(0)
        expect(question2.normalized_reputation_for(:total_votes)).to eq(0.5)
        expect(question3.normalized_reputation_for(:total_votes)).to eq(1)
      end

      it "should raise exception if invalid reputation name is given" do
        expect {@question.normalized_reputation_for(:invalid)}.to raise_error(ArgumentError)
      end

      it "should raise exception if scope is given for reputation with no scopes" do
        expect {@question.normalized_reputation_for(:difficulty, :s1)}.to raise_error(ArgumentError)
      end

      it "should raise exception if scope is not given for reputation with scopes" do
        expect {@phrase.normalized_reputation_for(:difficulty_with_scope)}.to raise_error(ArgumentError)
      end
    end

    describe "#exclude_all_reputations_for_normalization" do
      it "should activate all reputation" do
        @question2 = Question.create!(:text => 'Does this work??', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 70, @user)
        @question.add_evaluation(:total_votes, 100, @user)
        @question.deactivate_all_reputations
        expect(ReputationSystem::Reputation.where(:reputation_name => 'total_votes', :active => true).maximum(:value)).to eq(70)
        @question.activate_all_reputations
        expect(ReputationSystem::Reputation.where(:reputation_name => 'total_votes', :active => true).maximum(:value)).to eq(100)
      end
    end
  end
end
