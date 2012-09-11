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

describe RSReputation do
  before(:each) do
    @user = User.create!(:name => 'jack')
  end

  context "Validation" do
    it "should have value 0 by default in case of non product process" do
      r = RSReputation.create!(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
      r.value.should == 0
    end

    it "should be able to change value to 0 if process is not product process" do
      r = RSReputation.create!(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum', :value => 10)
      r.value = 0
      r.save!
      r.reload
      r.value.should == 0
    end

    it "should have value 1 by default in case of product process" do
      r = RSReputation.create!(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'product')
      r.value.should == 1
    end

    it "should be able to create reputation with process 'sum', 'average' and 'product'" do
      RSReputation.create(:reputation_name => "karma1", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum').should be_valid
      RSReputation.create(:reputation_name => "karma2", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'average').should be_valid
      RSReputation.create(:reputation_name => "karma3", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'product').should be_valid
    end

    it "should not be able to create reputation with process other than 'sum', 'average' and 'product'" do
      RSReputation.create(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'invalid').should_not be_valid
    end

    it "should not be able to create reputation of the same name for the same target" do
      RSReputation.create(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum').should be_valid
      RSReputation.create(:reputation_name => "karma", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum').should_not be_valid
    end
  end

  context "Association" do
    before :each do
      @question = Question.create!(:text => 'What is Twitter?', :author_id => @user.id)
      @question.add_evaluation(:total_votes, 5, @user)
    end

    it "should delete associated received messages" do
      rep = RSReputation.find_by_target_id_and_target_type(@question.id, 'Question')
      RSReputationMessage.find_by_receiver_id(rep.id).should_not be_nil
      rep.destroy
      RSReputationMessage.find_by_receiver_id(rep.id).should be_nil
    end

    it "should delete associated sent messages" do
      rep = RSReputation.find_by_target_id_and_target_type(@user.id, 'User')
      RSReputationMessage.find_by_sender_id_and_sender_type(rep.id, rep.class.name).should_not be_nil
      rep.destroy
      RSReputationMessage.find_by_sender_id_and_sender_type(rep.id, rep.class.name).should be_nil
    end
  end

  describe "#normalized_value" do
    before :each do
      @user2 = User.create!(:name => 'dick')
      @user3 = User.create!(:name => 'foo')
      question = Question.new(:text => "Does this work?", :author_id => @user.id)
      @r1 = RSReputation.create!(:reputation_name => "karma", :value => 2, :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
      @r2 = RSReputation.create!(:reputation_name => "karma", :value => 6, :target_id => @user2.id, :target_type => @user2.class.to_s, :aggregated_by => 'sum')
      @r3 = RSReputation.create!(:reputation_name => "karma", :value => 10, :target_id => @user3.id, :target_type => @user3.class.to_s, :aggregated_by => 'sum')
      @r4 = RSReputation.create!(:reputation_name => "karma", :value => 10, :target_id => question.id, :target_type => question.class.to_s, :aggregated_by => 'sum')
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

  describe "#contribution_value" do
    before :each do
      @user2 = User.create!(:name => 'dick')
      @user3 = User.create!(:name => 'foo')
      @user4 = User.create!(:name => 'bob')
      question = Question.new(:text => "Does this work?", :author_id => @user.id)
      @r1 = RSReputation.create!(:reputation_name => "karma", :value => 2, :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
      @r2 = RSReputation.create!(:reputation_name => "karma", :value => 6, :target_id => @user2.id, :target_type => @user2.class.to_s, :aggregated_by => 'sum')
      @r3 = RSReputation.create!(:reputation_name => "karma", :value => 6, :target_id => @user3.id, :target_type => @user3.class.to_s, :aggregated_by => 'sum')
      @r4 = RSReputation.create!(:reputation_name => "karma", :value => 10, :target_id => @user4.id, :target_type => @user4.class.to_s, :aggregated_by => 'sum')
      @r5 = RSReputation.create!(:reputation_name => "karma", :value => 10, :target_id => question.id, :target_type => question.class.to_s, :aggregated_by => 'sum')
    end

    it "should return correct contribution value" do
      @r1.contribution_value.should be_within(DELTA).of(2.to_f/24)
      @r2.contribution_value.should be_within(DELTA).of(14.to_f/24)
      @r3.contribution_value.should be_within(DELTA).of(14.to_f/24)
      @r4.contribution_value.should be_within(DELTA).of(1)
    end

    it "should return 0 if max and min are the same" do
      @r5.contribution_value.should be_within(DELTA).of(1)
    end
  end
end
