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

describe ReputationSystem::EvaluationMethods do

  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
    @answer = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => @question.id)
    @phrase = Phrase.create!(:text => "One")
  end

  context "Primary Reputation" do
    describe "#has_evaluation?" do
      it "should return false if it has not already been evaluated by a given source" do
        user = User.create! :name => 'katsuya'
        @question.add_evaluation(:total_votes, 3, user)
        expect(@question.has_evaluation?(:total_votes, @user)).to be false
      end
      it "should return true if it has been evaluated by a given source" do
        @question.add_evaluation(:total_votes, 3, @user)
        expect(@question.has_evaluation?(:total_votes, @user)).to be true
      end
      context "With Scopes" do
        it "should return false if it has not already been evaluated by a given source" do
          @phrase.add_evaluation(:difficulty_with_scope, 3, @user, :s1)
          expect(@phrase.has_evaluation?(:difficulty_with_scope, @user, :s2)).to be false
        end
        it "should return true if it has been evaluated by a given source" do
          @phrase.add_evaluation(:difficulty_with_scope, 3, @user, :s1)
          expect(@phrase.has_evaluation?(:difficulty_with_scope, @user, :s1)).to be true
        end
      end
    end

    describe "#evaluated_by" do
      it "should return an empty array if it is not evaluated by a given source" do
        expect(Question.evaluated_by(:total_votes, @user)).to eq([])
      end

      it "should return an array of targets evaluated by a given source" do
        user2 = User.create!(:name => 'katsuya')
        question2 = Question.create!(:text => 'Question 2', :author_id => @user.id)
        question3 = Question.create!(:text => 'Question 3', :author_id => @user.id)
        expect(@question.add_evaluation(:total_votes, 1, @user)).to be true
        expect(question2.add_evaluation(:total_votes, 2, user2)).to be true
        expect(question3.add_evaluation(:total_votes, 3, @user)).to be true
        expect(Question.evaluated_by(:total_votes, @user)).to eq([@question, question3])
        expect(Question.evaluated_by(:total_votes, user2)).to eq([question2])
      end

      context "With Scopes" do
        it "should return an array of targets evaluated by a given source on appropriate scope" do
          user2 = User.create!(:name => 'katsuya')
          phrase2 = Phrase.create!(:text => "Two")
          expect(@phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 3, user2, :s2)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 4, user2, :s3)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 1, user2, :s1)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 2, user2, :s2)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 3, @user, :s2)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 4, @user, :s3)).to be true
          expect(Phrase.evaluated_by(:difficulty_with_scope, @user, :s1)).to eq([@phrase])
          expect(Phrase.evaluated_by(:difficulty_with_scope, user2, :s1)).to eq([phrase2])
          expect(Phrase.evaluated_by(:difficulty_with_scope, @user, :s2)).to eq([@phrase, phrase2])
          expect(Phrase.evaluated_by(:difficulty_with_scope, user2, :s2)).to eq([@phrase, phrase2])
          expect(Phrase.evaluated_by(:difficulty_with_scope, @user, :s3)).to eq([phrase2])
          expect(Phrase.evaluated_by(:difficulty_with_scope, user2, :s3)).to eq([@phrase])
        end
      end
    end

    describe "#evaluation_by" do
      it "should return nil if it is not evaluated by a given source" do
        expect(@question.evaluation_by(:total_votes, @user)).to be nil
      end

      it "should return a value for an evaluation by a given source" do
        user2 = User.create!(:name => 'katsuya')
        question2 = Question.create!(:text => 'Question 2', :author_id => @user.id)
        expect(@question.add_evaluation(:total_votes, 1, @user)).to be true
        expect(question2.add_evaluation(:total_votes, 2, user2)).to be true
        expect(@question.evaluation_by(:total_votes, @user)).to eq(1)
        expect(question2.evaluation_by(:total_votes, user2)).to eq(2)
      end

      context "With Scopes" do
        it "should return a value for an evaluation by a given source on appropriate scope" do
          user2 = User.create!(:name => 'katsuya')
          phrase2 = Phrase.create!(:text => "Two")
          expect(@phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 3, user2, :s2)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 4, user2, :s3)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 1, user2, :s1)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 2, user2, :s2)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 3, @user, :s2)).to be true
          expect(phrase2.add_evaluation(:difficulty_with_scope, 4, @user, :s3)).to be true
          expect(@phrase.evaluation_by(:difficulty_with_scope, @user, :s1)).to eq(1)
          expect(@phrase.evaluation_by(:difficulty_with_scope, @user, :s2)).to eq(2)
          expect(@phrase.evaluation_by(:difficulty_with_scope, user2, :s2)).to eq(3)
          expect(@phrase.evaluation_by(:difficulty_with_scope, user2, :s3)).to eq(4)
          expect(phrase2.evaluation_by(:difficulty_with_scope, user2, :s1)).to eq(1)
          expect(phrase2.evaluation_by(:difficulty_with_scope, user2, :s2)).to eq(2)
          expect(phrase2.evaluation_by(:difficulty_with_scope, @user, :s2)).to eq(3)
          expect(phrase2.evaluation_by(:difficulty_with_scope, @user, :s3)).to eq(4)
        end
      end
    end

    describe "#evaluators_for" do
      it "should return an empty array if it is not evaluated for a given reputation" do
        expect(@question.evaluators_for(:total_votes)).to eq([])
      end

      it "should return an array of sources evaluated the target" do
        user2 = User.create!(:name => 'katsuya')
        question2 = Question.create!(:text => 'Question 2', :author_id => @user.id)
        expect(@question.add_evaluation(:total_votes, 1, @user)).to be true
        expect(question2.add_evaluation(:total_votes, 1, @user)).to be true
        expect(question2.add_evaluation(:total_votes, 2, user2)).to be true
        expect(@question.evaluators_for(:total_votes)).to eq([@user])
        expect(question2.evaluators_for(:total_votes)).to eq([@user, user2])
      end

      context "With Scopes" do
        it "should return an array of targets evaluated by a given source on appropriate scope" do
          user2 = User.create!(:name => 'katsuya')
          expect(@phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 3, user2, :s2)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 4, user2, :s3)).to be true
          expect(@phrase.evaluators_for(:difficulty_with_scope, :s1)).to eq([@user])
          expect(@phrase.evaluators_for(:difficulty_with_scope, :s2)).to eq([@user, user2])
          expect(@phrase.evaluators_for(:difficulty_with_scope, :s3)).to eq([user2])
        end
      end
    end

    describe "#add_evaluation" do
      it "should create evaluation in case of valid input" do
        expect(@question.add_evaluation(:total_votes, 1, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(1)
      end

      it "should raise exception if invalid reputation name is given" do
        expect { @question.add_evaluation(:invalid, 1, @user) }.to raise_error(ArgumentError)
      end

      it "should raise exception if the same source evaluates for the same target more than once" do
        @question.add_evaluation(:total_votes, 1, @user)
        expect { @question.add_evaluation(:total_votes, 1, @user) }.to raise_error
      end

      it "should not allow the same source to add an evaluation for the same target" do
        @question.add_evaluation(:total_votes, 1, @user)
        expect { @question.add_evaluation(:total_votes, 1, @user) }.to raise_error
      end

      it "should not raise exception if some association has not been initialized along during the propagation of reputation" do
        answer = Answer.create!
        expect { answer.add_evaluation(:avg_rating, 3, @user) }.not_to raise_error
      end

      context "with scopes" do
        it "should add evaluation on appropriate scope" do
          expect(@phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(1)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(2)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end

        it "should raise exception if invalid scope is given" do
          expect { @phrase.add_evaluation(:difficulty_with_scope, 1, :invalid_scope) }.to raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          expect { @phrase.add_evaluation(:difficulty_with_scope, 1) }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#add_or_update_evaluation" do
      it "should create evaluation if it does not exist" do
        expect(@question.add_or_update_evaluation(:total_votes, 1, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(1)
      end

      it "should update evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        expect(@question.add_or_update_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(2)
      end

      context "with scopes" do
        it "should add evaluation on appropriate scope if it does not exist" do
          expect(@phrase.add_or_update_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_or_update_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(1)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(2)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end

        it "should update evaluation on appropriate scope if it exists already" do
          expect(@phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.add_or_update_evaluation(:difficulty_with_scope, 3, @user, :s1)).to be true
          expect(@phrase.add_or_update_evaluation(:difficulty_with_scope, 5, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(3)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(5)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end
      end

      context "with STI" do
        it "should be able to update evaluation by an object of a class with sti" do
          @post = Post.create! :name => "Post1"
          @designer = Designer.create! :name => "John"
          @post.add_or_update_evaluation(:votes, 1, @designer)
          @post.add_or_update_evaluation(:votes, -1, @designer)
          expect(@post.reputation_for(:votes)).to eq(-1)
        end
      end
    end

    describe "#add_or_delete_evaluation" do
      it "should create evaluation if it does not exist" do
        expect(@question.add_or_delete_evaluation(:total_votes, 1, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(1)
      end

      it "should delete evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        expect(@question.add_or_delete_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(0)
      end

      context "with scopes" do
        it "should add evaluation on appropriate scope if it does not exist" do
          expect(@phrase.add_or_delete_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_or_delete_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(1)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(2)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end

        it "should delete evaluation on appropriate scope if it exists already" do
          expect(@phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)).to be true
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
          expect(@phrase.add_or_delete_evaluation(:difficulty_with_scope, 3, @user, :s1)).to be true
          expect(@phrase.add_or_delete_evaluation(:difficulty_with_scope, 5, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end
      end

      context "with STI" do
        it "should be able to update evaluation by an object of a class with sti" do
          @post = Post.create! :name => "Post1"
          @designer = Designer.create! :name => "John"
          @post.add_or_delete_evaluation(:votes, 1, @designer)
          expect(@post.reputation_for(:votes)).to eq(1)
          @post.add_or_delete_evaluation(:votes, -1, @designer)
          expect(@post.reputation_for(:votes)).to eq(0)
        end
      end
    end

    describe "#update_evaluation" do
      before :each do
        @question.add_evaluation(:total_votes, 1, @user)
      end

      it "should update evaluation in case of valid input" do
        expect(@question.update_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(2)
      end

      it "should raise exception if invalid reputation name is given" do
        expect { @question.update_evaluation(:invalid, 1, @user) }.to raise_error(ArgumentError)
      end

      it "should raise exception if invalid source is given" do
       expect { @question.update_evaluation(:total_votes, 1, @answer) }.to raise_error(ArgumentError)
      end

      it "should raise exception if evaluation does not exist" do
        expect { @answer.update_evaluation(:avg_rating, 1, @user) }.to raise_error
      end

      context "With Scopes" do
        before :each do
          expect(@phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)).to be true
        end

        it "should update evaluation on appropriate scope" do
          expect(@phrase.update_evaluation(:difficulty_with_scope, 5, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(5)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end

        it "should raise exception if invalid scope is given" do
          expect { @phrase.update_evaluation(:difficulty_with_scope, 5, @user, :invalid_scope) }.to raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          expect { @phrase.update_evaluation(:difficulty_with_scope, 5, @user) }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#delete_evaluation!" do
      before :each do
        @question.add_evaluation(:total_votes, 1, @user)
      end

      it "should delete evaluation in case of valid input" do
        @question.delete_evaluation!(:total_votes, @user)
        expect(@question.reputation_for(:total_votes)).to eq(0)
      end

      it "should raise exception if invalid reputation name is given" do
        expect { @question.delete_evaluation!(:invalid, @user) }.to raise_error(ArgumentError)
      end

      it "should raise exception if invalid source is given" do
       expect { @question.delete_evaluation!(:total_votes, @answer) }.to raise_error(ArgumentError)
      end

      it "should raise exception if evaluation does not exist" do
        expect { @answer.delete_evaluation!(:avg_rating, @user) }.to raise_error
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should delete evaluation on appropriate scope" do
          @phrase.delete_evaluation!(:difficulty_with_scope, @user, :s2)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end

        it "should raise exception if invalid scope is given" do
          expect { @phrase.delete_evaluation!(:difficulty_with_scope, @user, :invalid_scope) }.to raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          expect { @phrase.delete_evaluation!(:difficulty_with_scope, @user) }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#delete_evaluation" do
      before :each do
        @question.add_evaluation(:total_votes, 1, @user)
      end

      it "should delete evaluation in case of valid input" do
        expect(@question.delete_evaluation(:total_votes, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(0)
      end

      it "should raise exception if invalid reputation name is given" do
        expect { @question.delete_evaluation(:invalid, @user) }.to raise_error(ArgumentError)
      end

      it "should return false if evaluation does not exist" do
        expect(@answer.delete_evaluation(:avg_rating, @user)).to be false
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should delete evaluation on appropriate scope" do
          expect(@phrase.delete_evaluation(:difficulty_with_scope, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end

        it "should raise exception if invalid scope is given" do
          expect { @phrase.delete_evaluation(:difficulty_with_scope, @user, :invalid_scope) }.to raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          expect { @phrase.delete_evaluation(:difficulty_with_scope, @user) }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#increase_evaluation" do
      it "should add evaluation if it does not exist" do
        expect(@question.increase_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(2)
      end

      it "should increase evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        expect(@question.increase_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(3)
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should increase evaluation on appropriate scope" do
          expect(@phrase.increase_evaluation(:difficulty_with_scope, 5, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(7)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end
      end
    end

    describe "#decrease_evaluation" do
      it "should add evaluation if it does not exist" do
        expect(@question.decrease_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(-2)
      end

      it "should increase evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        expect(@question.decrease_evaluation(:total_votes, 2, @user)).to be true
        expect(@question.reputation_for(:total_votes)).to eq(-1)
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should decrease evaluation on appropriate scope" do
          expect(@phrase.decrease_evaluation(:difficulty_with_scope, 5, @user, :s2)).to be true
          expect(@phrase.reputation_for(:difficulty_with_scope, :s1)).to eq(0)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s2)).to eq(-3)
          expect(@phrase.reputation_for(:difficulty_with_scope, :s3)).to eq(0)
        end
      end
    end
  end

  context "Non-Primary Reputation with Gathering Aggregation" do
    context "With Scopes" do
      before :each do
        @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
        @trans_fr = Translation.create!(:text => "Homme", :user => @user, :locale => "fr", :phrase => @phrase)
      end

      describe "#add_evaluation" do
        it "should affect only reputations with relevant scope" do
          @trans_ja.add_evaluation(:votes, 1, @user)
          @trans_fr.add_evaluation(:votes, 2, @user)
          expect(@phrase.reputation_for(:maturity, :ja)).to eq(1)
          expect(@phrase.reputation_for(:maturity, :fr)).to eq(2)
        end
      end

      describe "#update_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_ja.update_evaluation(:votes, 3, @user)
          expect(@phrase.reputation_for(:maturity, :ja)).to eq(3)
          expect(@phrase.reputation_for(:maturity, :fr)).to eq(0)
        end
      end

      describe "#delete_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_ja.delete_evaluation!(:votes, @user)
          expect(@phrase.reputation_for(:maturity, :ja)).to eq(0)
          expect(@phrase.reputation_for(:maturity, :fr)).to eq(0)
        end
      end
    end
  end

  context "Non-Primary Reputation with Mixing Aggregation" do
    context "With Scopes" do
      before :each do
        @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
        @trans_fr = Translation.create!(:text => "Homme", :user => @user, :locale => "fr", :phrase => @phrase)
        @trans_de = Translation.create!(:text => "Ein", :user => @user, :locale => "de", :phrase => @phrase)
      end

      describe "#add_evaluation" do
        it "should affect only reputations with relevant scope" do
          @trans_ja.add_evaluation(:votes, 1, @user)
          expect(@phrase.reputation_for(:maturity_all)).to eq(1)
          @trans_fr.add_evaluation(:votes, 2, @user)
          expect(@phrase.reputation_for(:maturity_all)).to eq(3)
          @trans_de.add_evaluation(:votes, 3, @user)
          expect(@phrase.reputation_for(:maturity_all)).to eq(3)
          expect(@phrase.reputation_for(:maturity, :ja)).to eq(1)
          expect(@phrase.reputation_for(:maturity, :fr)).to eq(2)
          expect(@phrase.reputation_for(:maturity, :de)).to eq(3)
        end
      end

      describe "#update_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
          @trans_de.add_evaluation(:votes, 3, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_ja.update_evaluation(:votes, 3, @user)
          @trans_de.update_evaluation(:votes, 2, @user)
          expect(@phrase.reputation_for(:maturity_all)).to eq(3)
        end
      end

      describe "#delete_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
          @trans_de.add_evaluation(:votes, 3, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_de.delete_evaluation!(:votes, @user)
          expect(@phrase.reputation_for(:maturity_all)).to eq(1)
          @trans_ja.delete_evaluation!(:votes, @user)
          expect(@phrase.reputation_for(:maturity_all)).to eq(0)
        end
      end
    end
  end
end
