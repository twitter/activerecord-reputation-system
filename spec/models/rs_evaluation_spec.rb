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

describe RSEvaluation do
  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'What is Twitter?', :author_id => @user.id)
  end

  context "Validation" do
    before :each do
      @attributes = {:reputation_name => 'total_votes', :source => @user, :target => @question, :value => 1}
    end
    it "should not be able to create an evaluation from given source if it has already evaluated the same reputation of the target" do
      RSEvaluation.create!(@attributes)
      lambda {RSEvaluation.create!(@attributes)}.should raise_error
    end
  end

  context "Association" do
    it "should delete associated reputation message" do
      @question.add_evaluation(:total_votes, 5, @user)
      evaluation = RSEvaluation.find_by_reputation_name_and_source_and_target(:total_votes, @user, @question)
      RSReputationMessage.find_by_sender_id_and_sender_type(evaluation.id, evaluation.class.name).should_not be_nil
      @question.delete_evaluation(:total_votes, @user)
      RSReputationMessage.find_by_sender_id_and_sender_type(evaluation.id, evaluation.class.name).should be_nil
    end
  end
end
