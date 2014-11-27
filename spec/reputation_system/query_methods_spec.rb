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
        expect(res).to eq([@question])
        expect(res[0].total_votes).not_to be_nil
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 5, @user)
        res = Question.with_reputation(:total_votes).where("total_votes > 4")
        expect(res).to eq([@question2])
      end

      it "should retain joins option" do
        res = Question.with_reputation(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        expect(res).to eq([@question])
        expect(res[0].user_name).to eq(@user.name)
      end

      it "should not retain select option" do
        res = Question.with_reputation(:total_votes).select("questions.id")
        expect(res).to eq([@question])
        expect(res[0].id).not_to be_nil
        expect {res[0].text}.not_to raise_error
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
        expect(res).to eq([@phrase])
        expect(res[0].maturity).to eq(3)
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
        expect(res.length).to eq(1)
        expect(res[0].total_votes).not_to be_nil
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 5, @user)
        res = Question.with_reputation_only(:total_votes).where("total_votes > 4")
        expect(res.length).to eq(1)
        expect(res[0].total_votes).to be > 4
      end

      it "should retain joins option" do
        res = Question.with_reputation_only(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        expect(res[0].user_name).to eq(@user.name)
      end

      it "should retain select option" do
        res = Question.with_reputation_only(:total_votes).select("questions.id")
        expect(res).to eq([@question])
        expect(res[0].id).not_to be_nil
        expect {res[0].text}.to raise_error
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
        expect(res.length).to eq(1)
        expect(res[0].maturity).to eq(3)
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
        expect(res).to eq([@question, @question2])
        expect(res[0].normalized_total_votes).to be_within(DELTA).of(0)
        expect(res[1].normalized_total_votes).to be_within(DELTA).of(1)
      end

      it "should not retain select option" do
        res = Question.with_normalized_reputation(:total_votes).select("questions.id")
        expect(res).to eq([@question])
        expect(res[0].id).not_to be_nil
        expect {res[0].text}.not_to raise_error
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 6, @user)
        res = Question.with_normalized_reputation(:total_votes).where("normalized_total_votes > 0.6")
        expect(res).to eq([@question2])
      end

      it "should retain joins option" do
        res = Question.with_normalized_reputation(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        expect(res).to eq([@question])
        expect(res[0].user_name).to eq(@user.name)
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
        expect(res).to eq([@phrase])
        expect(res[0].normalized_maturity).to be_within(DELTA).of(0)
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
        expect(res.length).to eq(2)
        expect(res[0].normalized_total_votes).to be_within(DELTA).of(0)
        expect(res[1].normalized_total_votes).to be_within(DELTA).of(1)
      end

      it "should not retain select option" do
        res = Question.with_normalized_reputation_only(:total_votes).select("questions.id")
        expect(res.length).to eq(1)
        expect(res[0].id).not_to be_nil
        expect {res[0].text}.to raise_error
      end

      it "should retain conditions option" do
        @question2 = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        @question2.add_evaluation(:total_votes, 6, @user)
        res = Question.with_normalized_reputation_only(:total_votes).where("normalized_total_votes > 0.6")
        expect(res.length).to eq(1)
        expect(res[0].normalized_total_votes).to be > 0.6
      end

      it "should retain joins option" do
        res = Question.with_normalized_reputation_only(:total_votes).
          select("questions.*, users.name AS user_name").
          joins("JOIN users ON questions.author_id = users.id")
        expect(res.length).to eq(1)
        expect(res[0].user_name).to eq(@user.name)
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
        expect(res.length).to eq(1)
        expect(res[0].normalized_maturity).to be_within(DELTA).of(0)
      end
    end
  end
end
