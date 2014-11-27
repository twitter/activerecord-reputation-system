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

describe ReputationSystem::ReputationMessage do
  before(:each) do
    @user = User.create!(:name => 'jack')
    @rep1 = ReputationSystem::Reputation.create!(:reputation_name => "karma1", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
    @rep2 = ReputationSystem::Reputation.create!(:reputation_name => "karma2", :target_id => @user.id, :target_type => @user.class.to_s, :aggregated_by => 'sum')
  end

  context "Validation" do
    it "should not be able to create a message from given sender if it has already sent one to the same receiver" do
      expect(ReputationSystem::ReputationMessage.create(:sender => @rep1, :receiver => @rep2)).to be_valid
      expect(ReputationSystem::ReputationMessage.create(:sender => @rep1, :receiver => @rep2)).not_to be_valid
    end

    it "should have raise error if sender is neither ReputationSystem::Evaluation and ReputationSystem::Reputation" do
      expect(ReputationSystem::ReputationMessage.create(:sender => @user, :receiver => @rep2).errors[:sender]).not_to be_nil
    end
  end

  context "Association" do
    it "should delete associated sender if it is evaluation" do
      question = Question.create!(:text => 'What is Twitter?', :author_id => @user.id)
      question.add_evaluation(:total_votes, 5, @user)
      evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(:total_votes, @user, question)
      m = ReputationSystem::ReputationMessage.find_by_sender_id_and_sender_type(evaluation.id, evaluation.class.name)
      m.destroy
      expect { evaluation.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
