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

  context "Primary Reputation" do
    describe "#add_evaluation" do
      it "should create evaluation in case of valid input" do
        @question.add_evaluation(:total_votes, 1, @user)
        @question.reputation_value_for(:total_votes).should == 1
      end

      it "should raise exception if invalid reputation name is given" do
        lambda {@question.add_evaluation(:invalid, 1, @user)}.should raise_error(ArgumentError)
      end

      it "should raise exception if the same source evaluates for the same target more than once" do
        @question.add_evaluation(:total_votes, 1, @user)
        lambda{@question.add_evaluation(:total_votes, 1, @user)}.should raise_error
      end

      it "should not allow the same source to add an evaluation for the same target" do
        @question.add_evaluation(:total_votes, 1, @user)
        lambda{@question.add_evaluation(:total_votes, 1, @user)}.should raise_error
      end

      context "With Scopes" do
        it "should add evaluation on appropriate scope" do
          @phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 1
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 2
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end

        it "should raise exception if invalid scope is given" do
          lambda{@phrase.add_evaluation(:difficulty_with_scope, 1, :invalid_scope)}.should raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          lambda{@phrase.add_evaluation(:difficulty_with_scope, 1)}.should raise_error(ArgumentError)
        end
      end
    end

    describe "#add_or_update_evaluation" do
      it "should create evaluation if it does not exist" do
        @question.add_or_update_evaluation(:total_votes, 1, @user)
        @question.reputation_value_for(:total_votes).should == 1
      end

      it "should update evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        @question.add_or_update_evaluation(:total_votes, 2, @user)
        @question.reputation_value_for(:total_votes).should == 2
      end

      context "With Scopes" do
        it "should add evaluation on appropriate scope if it does not exist" do
          @phrase.add_or_update_evaluation(:difficulty_with_scope, 1, @user, :s1)
          @phrase.add_or_update_evaluation(:difficulty_with_scope, 2, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 1
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 2
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end

        it "should update evaluation on appropriate scope if it exists already" do
          @phrase.add_evaluation(:difficulty_with_scope, 1, @user, :s1)
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
          @phrase.add_or_update_evaluation(:difficulty_with_scope, 3, @user, :s1)
          @phrase.add_or_update_evaluation(:difficulty_with_scope, 5, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 3
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 5
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end
      end
    end

    describe "#update_evaluation" do
      before :each do
        @question.add_evaluation(:total_votes, 1, @user)
      end

      it "should update evaluation in case of valid input" do
        @question.update_evaluation(:total_votes, 2, @user)
        @question.reputation_value_for(:total_votes).should == 2
      end

      it "should raise exception if invalid reputation name is given" do
        lambda {@question.update_evaluation(:invalid, 1, @user)}.should raise_error(ArgumentError)
      end

      it "should raise exception if invalid source is given" do
       lambda {@question.update_evaluation(:total_votes, 1, @answer)}.should raise_error(ArgumentError)
      end

      it "should raise exception if evaluation does not exist" do
        lambda{@answer.update_evaluation(:avg_rating, 1, @user)}.should raise_error
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should update evaluation on appropriate scope" do
          @phrase.update_evaluation(:difficulty_with_scope, 5, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 5
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end

        it "should raise exception if invalid scope is given" do
          lambda{@phrase.update_evaluation(:difficulty_with_scope, 5, @user, :invalid_scope)}.should raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          lambda{@phrase.update_evaluation(:difficulty_with_scope, 5, @user)}.should raise_error(ArgumentError)
        end
      end
    end

    describe "#delete_evaluation!" do
      before :each do
        @question.add_evaluation(:total_votes, 1, @user)
      end

      it "should delete evaluation in case of valid input" do
        @question.delete_evaluation!(:total_votes, @user)
        @question.reputation_value_for(:total_votes).should == 0
      end

      it "should raise exception if invalid reputation name is given" do
        lambda {@question.delete_evaluation!(:invalid, @user)}.should raise_error(ArgumentError)
      end

      it "should raise exception if invalid source is given" do
       lambda {@question.delete_evaluation!(:total_votes, @answer)}.should raise_error(ArgumentError)
      end

      it "should raise exception if evaluation does not exist" do
        lambda{@answer.delete_evaluation!(:avg_rating, @user)}.should raise_error
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should delete evaluation on appropriate scope" do
          @phrase.delete_evaluation!(:difficulty_with_scope, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end

        it "should raise exception if invalid scope is given" do
          lambda{@phrase.delete_evaluation!(:difficulty_with_scope, @user, :invalid_scope)}.should raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          lambda{@phrase.delete_evaluation!(:difficulty_with_scope, @user)}.should raise_error(ArgumentError)
        end
      end
    end

    describe "#delete_evaluation" do
      before :each do
        @question.add_evaluation(:total_votes, 1, @user)
      end

      it "should delete evaluation in case of valid input" do
        @question.delete_evaluation(:total_votes, @user)
        @question.reputation_value_for(:total_votes).should == 0
      end

      it "should raise exception if invalid reputation name is given" do
        lambda {@question.delete_evaluation(:invalid, @user)}.should raise_error(ArgumentError)
      end

      it "should return nil if evaluation does not exist" do
        @answer.delete_evaluation(:avg_rating, @user).should be_nil
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should delete evaluation on appropriate scope" do
          @phrase.delete_evaluation(:difficulty_with_scope, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end

        it "should raise exception if invalid scope is given" do
          lambda{@phrase.delete_evaluation(:difficulty_with_scope, @user, :invalid_scope)}.should raise_error(ArgumentError)
        end

        it "should raise exception if scope is not given" do
          lambda{@phrase.delete_evaluation(:difficulty_with_scope, @user)}.should raise_error(ArgumentError)
        end
      end
    end

    describe "#increase_evaluation" do
      it "should add evaluation if it does not exist" do
        @question.increase_evaluation(:total_votes, 2, @user)
        @question.reputation_value_for(:total_votes).should == 2
      end

      it "should increase evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        @question.increase_evaluation(:total_votes, 2, @user)
        @question.reputation_value_for(:total_votes).should == 3
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should increase evaluation on appropriate scope" do
          @phrase.increase_evaluation(:difficulty_with_scope, 5, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == 7
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
        end
      end
    end

    describe "#decrease_evaluation" do
      it "should add evaluation if it does not exist" do
        @question.decrease_evaluation(:total_votes, 2, @user)
        @question.reputation_value_for(:total_votes).should == -2
      end

      it "should increase evaluation if it exists already" do
        @question.add_evaluation(:total_votes, 1, @user)
        @question.decrease_evaluation(:total_votes, 2, @user)
        @question.reputation_value_for(:total_votes).should == -1
      end

      context "With Scopes" do
        before :each do
          @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s2)
        end

        it "should increase evaluation on appropriate scope" do
          @phrase.decrease_evaluation(:difficulty_with_scope, 5, @user, :s2)
          @phrase.reputation_value_for(:difficulty_with_scope, :s1).should == 0
          @phrase.reputation_value_for(:difficulty_with_scope, :s2).should == -3
          @phrase.reputation_value_for(:difficulty_with_scope, :s3).should == 0
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
          @phrase.reputation_value_for(:maturity, :ja).should == 1
          @phrase.reputation_value_for(:maturity, :fr).should == 2
        end
      end

      describe "#update_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_ja.update_evaluation(:votes, 3, @user)
          @phrase.reputation_value_for(:maturity, :ja).should == 3
          @phrase.reputation_value_for(:maturity, :fr).should == 0
        end
      end

      describe "#delete_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_ja.delete_evaluation!(:votes, @user)
          @phrase.reputation_value_for(:maturity, :ja).should == 0
          @phrase.reputation_value_for(:maturity, :fr).should == 0
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
          @phrase.reputation_value_for(:maturity_all).should == 1
          @trans_fr.add_evaluation(:votes, 2, @user)
          @phrase.reputation_value_for(:maturity_all).should == 3
          @trans_de.add_evaluation(:votes, 3, @user)
          @phrase.reputation_value_for(:maturity_all).should == 3
          @phrase.reputation_value_for(:maturity, :ja).should == 1
          @phrase.reputation_value_for(:maturity, :fr).should == 2
          @phrase.reputation_value_for(:maturity, :de).should == 3
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
          @phrase.reputation_value_for(:maturity_all).should == 3
        end
      end

      describe "#delete_evaluation" do
        before :each do
          @trans_ja.add_evaluation(:votes, 1, @user)
          @trans_de.add_evaluation(:votes, 3, @user)
        end

        it "should affect only reputations with relevant scope" do
          @trans_de.delete_evaluation!(:votes, @user)
          @phrase.reputation_value_for(:maturity_all).should == 1
          @trans_ja.delete_evaluation!(:votes, @user)
          @phrase.reputation_value_for(:maturity_all).should == 0
        end
      end
    end
  end
end
