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

describe ReputationSystem::Evaluation do
  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'What is Twitter?', :author_id => @user.id)
  end

  context "Validation" do
    before :each do
      @attributes = {:reputation_name => 'total_votes', :source => @user, :target => @question, :value => 1}
    end
    it "should not be able to create an evaluation from given source if it has already evaluated the same reputation of the target" do
      ReputationSystem::Evaluation.create!(@attributes)
      expect {ReputationSystem::Evaluation.create!(@attributes)}.to raise_error
    end
  end

  context "Callback" do
    describe "#set_source_type_for_sti" do
      it "should assign source class name as source type if not STI" do
        question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
        question.add_evaluation(:total_votes, 5, @user)
        evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(:total_votes, @user, question)
        expect(evaluation.source_type).to eq(@user.class.name)
      end
      it "should assign source's ancestors class name where reputation is declared if STI" do
        designer = Designer.create! :name => 'hiro'
        programmer = Programmer.create! :name => 'katsuya'
        programmer.add_evaluation(:leadership, 1, designer)
        evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(:leadership, designer, programmer)
        expect(evaluation.source_type).to eq(Person.name)
      end
    end
  end

  context "Association" do
    it "should delete associated reputation message" do
      @question.add_evaluation(:total_votes, 5, @user)
      evaluation = ReputationSystem::Evaluation.find_by_reputation_name_and_source_and_target(:total_votes, @user, @question)
      expect(ReputationSystem::ReputationMessage.find_by_sender_id_and_sender_type(evaluation.id, evaluation.class.name)).not_to be_nil
      @question.delete_evaluation(:total_votes, @user)
      expect(ReputationSystem::ReputationMessage.find_by_sender_id_and_sender_type(evaluation.id, evaluation.class.name)).to be_nil
    end
  end

  context "Additional Data" do
    it "should have data as a serialized field" do
      @attributes = {:reputation_name => 'total_votes', :source => @user, :target => @question, :value => 1}
      e = ReputationSystem::Evaluation.create!(@attributes)
      expect(e.data).to be_a(Hash)
    end
  end
end
