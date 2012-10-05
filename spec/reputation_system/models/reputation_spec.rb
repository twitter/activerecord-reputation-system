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

describe ReputationSystem::Reputation do
  before(:each) do
    @user = User.create!(:name => 'jack')
  end

  context "Validation" do
    it "should have value 0 by default in case of non product process" do
      r = ReputationSystem::Reputation.create!(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
      r.value.should == 0
    end

    it "should be able to change value to 0 if process is not product process" do
      r = ReputationSystem::Reputation.create!(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum', :value => 10)
      r.value = 0
      r.save!
      r.reload
      r.value.should == 0
    end

    it "should have value 1 by default in case of product process" do
      r = ReputationSystem::Reputation.create!(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'product')
      r.value.should == 1
    end

    it "should be able to create reputation with process 'sum', 'average' and 'product'" do
      ReputationSystem::Reputation.create(:reputation_name => "karma1", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum').should be_valid
      ReputationSystem::Reputation.create(:reputation_name => "karma2", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'average').should be_valid
      ReputationSystem::Reputation.create(:reputation_name => "karma3", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'product').should be_valid
    end

    it "should not be able to create reputation with process other than 'sum', 'average' and 'product'" do
      ReputationSystem::Reputation.create(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'invalid').should_not be_valid
    end

    it "should not be able to create reputation of the same name for the same target" do
      ReputationSystem::Reputation.create(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum').should be_valid
      ReputationSystem::Reputation.create(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum').should_not be_valid
    end
  end

  context "Callback" do
    describe "#set_target_type_for_sti" do
      it "should assign target class name as target type if not STI" do
        question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        question.add_evaluation(:total_votes, 5, @user)
        rep = ReputationSystem::Reputation.find_by_reputation_name_and_target(:total_votes, question)
        rep.target_type.should == question.class.name
      end
      it "should assign target's ancestors class name where reputation is declared if STI" do
        designer = Designer.create! :name => 'hiro'
        programmer = Programmer.create! :name => 'katsuya'
        programmer.add_evaluation(:leadership, 1, designer)
        rep = ReputationSystem::Reputation.find_by_reputation_name_and_target(:leadership, programmer)
        rep.target_type.should == Person.name
      end
    end
  end

  context "Association" do
    before :each do
      @question = Question.create!(:text => 'What is Twitter?', :author_id => @user.id)
      @question.add_evaluation(:total_votes, 5, @user)
    end

    it "should delete associated received messages" do
      rep = ReputationSystem::Reputation.find_by_target_id_and_target_type(@question.id, 'Question')
      ReputationSystem::ReputationMessage.find_by_receiver_id(rep.id).should_not be_nil
      rep.destroy
      ReputationSystem::ReputationMessage.find_by_receiver_id(rep.id).should be_nil
    end

    it "should delete associated sent messages" do
      rep = ReputationSystem::Reputation.find_by_target_id_and_target_type(@user.id, 'User')
      ReputationSystem::ReputationMessage.find_by_sender_id_and_sender_type(rep.id, rep.class.name).should_not be_nil
      rep.destroy
      ReputationSystem::ReputationMessage.find_by_sender_id_and_sender_type(rep.id, rep.class.name).should be_nil
    end
  end

  describe "#normalized_value" do
    before :each do
      @user2 = User.create!(:name => 'dick')
      @user3 = User.create!(:name => 'foo')
      question = Question.new(:text => "Does this work?", :author_id => @user.id)
      @r1 = ReputationSystem::Reputation.create!(:reputation_name => "karma", :value => 2, :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
      @r2 = ReputationSystem::Reputation.create!(:reputation_name => "karma", :value => 6, :target_id => @user2.id, :target_type => @user2.class.to_s, :aggregated_by => 'sum')
      @r3 = ReputationSystem::Reputation.create!(:reputation_name => "karma", :value => 10, :target_id => @user3.id, :target_type => @user3.class.to_s, :aggregated_by => 'sum')
      @r4 = ReputationSystem::Reputation.create!(:reputation_name => "karma", :value => 10, :target_id => question.id, :target_type => question.class.to_s, :aggregated_by => 'sum')
    end

    it "should return correct normalized value" do
      @r1.normalized_value.should be_within(DELTA).of(0)
      @r2.normalized_value.should be_within(DELTA).of(0.5)
      @r3.normalized_value.should be_within(DELTA).of(1)
    end

    it "should return 0 if max and min are the same" do
      @r4.normalized_value.should be_within(DELTA).of(0)
    end
  end

  describe "value propagation with average process" do
    it "should calculate average reputation even after evaluation is deleted" do
      user1 = User.create! :name => 'dick'
      user2 = User.create! :name => 'katsuya'
      answer = Answer.create!
      answer.add_evaluation(:avg_rating, 3, user1)
      answer.add_evaluation(:avg_rating, 2, user2)
      answer.reputation_for(:avg_rating).should be_within(DELTA).of(2.5)
      answer.delete_evaluation(:avg_rating, user1)
      answer.reputation_for(:avg_rating).should be_within(DELTA).of(2)
      answer.delete_evaluation(:avg_rating, user2)
      answer.reputation_for(:avg_rating).should be_within(DELTA).of(0)
      answer.add_evaluation(:avg_rating, 3, user1)
      answer.reputation_for(:avg_rating).should be_within(DELTA).of(3)
    end
  end
end
