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

describe ReputationSystem::QueryMethods do

  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
    @answer = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => @question.id)
    @phrase = Phrase.create!(:text => "One")
  end

  describe "#with_reputation" do
    context "Without Scopes" do
      before :each do
        @question.add_evaluation(:total_votes, 3, @user)
      end

      it "should return result with given reputation" do
        res = Question.with_reputation(:total_votes)
        res.should == [@question]
        res[0].total_votes.should_not be_nil
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 5, @user)
        res = Question.with_reputation(:total_votes).where("total_votes > 4")
        res.should == [@question2]
      end

      it "should retain joins option" do
        res = Question.with_reputation(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        res.should == [@question]
        res[0].user_name.should == @user.name
      end

      it "should not retain select option" do
        res = Question.with_reputation(:total_votes).select("questions.id")
        res.should == [@question]
        res[0].id.should_not be_nil
        lambda {res[0].text}.should_not raise_error
      end
    end

    context "With Scopes" do
      before :each do
        @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
        @trans_ja.add_evaluation(:votes, 3, @user)
        @trans_fr = Translation.create!(:text => "Ichi", :user => @user, :locale => "fr", :phrase => @phrase)
        @trans_fr.add_evaluation(:votes, 6, @user)
      end

      it "should return result with given reputation" do
        res = Phrase.with_reputation(:maturity, :ja)
        res.should == [@phrase]
        res[0].maturity.should == 3
      end
    end
  end

  describe "#with_reputation_only" do
    context "Without Scopes" do
      before :each do
        @question.add_evaluation(:total_votes, 3, @user)
      end

      it "should return result with given reputation" do
        res = Question.with_reputation_only(:total_votes)
        res.length.should == 1
        res[0].total_votes.should_not be_nil
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 5, @user)
        res = Question.with_reputation_only(:total_votes).where("total_votes > 4")
        res.length.should == 1
        res[0].total_votes.should > 4
      end

      it "should retain joins option" do
        res = Question.with_reputation_only(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        res[0].user_name.should == @user.name
      end

      it "should retain select option" do
        res = Question.with_reputation_only(:total_votes).select("questions.id")
        res.should == [@question]
        res[0].id.should_not be_nil
        lambda {res[0].text}.should raise_error
      end
    end

    context "With Scopes" do
      before :each do
        @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
        @trans_ja.add_evaluation(:votes, 3, @user)
        @trans_fr = Translation.create!(:text => "Ichi", :user => @user, :locale => "fr", :phrase => @phrase)
        @trans_fr.add_evaluation(:votes, 6, @user)
      end

      it "should return result with given reputation" do
        res = Phrase.with_reputation_only(:maturity, :ja)
        res.length.should == 1
        res[0].maturity.should == 3
      end
    end
  end

  describe "#with_normalized_reputation" do
    context "Without Scopes" do
      before :each do
        @question.add_evaluation(:total_votes, 3, @user)
      end

      it "should return result with given normalized reputation" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 6, @user)
        res = Question.with_normalized_reputation(:total_votes)
        res.should == [@question, @question2]
        res[0].normalized_total_votes.should be_within(DELTA).of(0)
        res[1].normalized_total_votes.should be_within(DELTA).of(1)
      end

      it "should not retain select option" do
        res = Question.with_normalized_reputation(:total_votes).select("questions.id")
        res.should == [@question]
        res[0].id.should_not be_nil
        lambda {res[0].text}.should_not raise_error
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 6, @user)
        res = Question.with_normalized_reputation(:total_votes).where("normalized_total_votes > 0.6")
        res.should == [@question2]
      end

      it "should retain joins option" do
        res = Question.with_normalized_reputation(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        res.should == [@question]
        res[0].user_name.should == @user.name
      end
    end

    context "With Scopes" do
      before :each do
        @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
        @trans_ja.add_evaluation(:votes, 3, @user)
        @trans_fr = Translation.create!(:text => "Ichi", :user => @user, :locale => "fr", :phrase => @phrase)
        @trans_fr.add_evaluation(:votes, 6, @user)
      end

      it "should return result with given reputation" do
        res = Phrase.with_normalized_reputation(:maturity, :ja)
        res.should == [@phrase]
        res[0].normalized_maturity.should be_within(DELTA).of(0)
      end
    end
  end

  describe "#with_normalized_reputation_only" do
    context "Without Scopes" do
      before :each do
        @question.add_evaluation(:total_votes, 3, @user)
      end

      it "should return result with given normalized reputation" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 6, @user)
        res = Question.with_normalized_reputation_only(:total_votes)
        res.length.should == 2
        res[0].normalized_total_votes.should be_within(DELTA).of(0)
        res[1].normalized_total_votes.should be_within(DELTA).of(1)
      end

      it "should not retain select option" do
        res = Question.with_normalized_reputation_only(:total_votes).select("questions.id")
        res.length.should == 1
        res[0].id.should_not be_nil
        lambda {res[0].text}.should raise_error
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 6, @user)
        res = Question.with_normalized_reputation_only(:total_votes).where("normalized_total_votes > 0.6")
        res.length.should == 1
        res[0].normalized_total_votes.should > 0.6
      end

      it "should retain joins option" do
        res = Question.with_normalized_reputation_only(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        res.length.should == 1
        res[0].user_name.should == @user.name
      end
    end

    context "With Scopes" do
      before :each do
        @trans_ja = Translation.create!(:text => "Ichi", :user => @user, :locale => "ja", :phrase => @phrase)
        @trans_ja.add_evaluation(:votes, 3, @user)
        @trans_fr = Translation.create!(:text => "Ichi", :user => @user, :locale => "fr", :phrase => @phrase)
        @trans_fr.add_evaluation(:votes, 6, @user)
      end

      it "should return result with given reputation" do
        res = Phrase.with_normalized_reputation_only(:maturity, :ja)
        res.length.should == 1
        res[0].normalized_maturity.should be_within(DELTA).of(0)
      end
    end
  end
end
