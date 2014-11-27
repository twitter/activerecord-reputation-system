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

describe ReputationSystem::ScopeMethods do

  before(:each) do
    @user = User.create!(:name => 'jack')
    @question = Question.create!(:text => 'Does this work?', :author_id => @user.id)
    @answer = Answer.create!(:text => 'Yes!', :author_id => @user.id, :question_id => @question.id)
    @phrase = Phrase.create!(:text => "One")
  end

  describe "#add_scope_for" do
    it "should add scope if the reputation has scopes defined" do
      Phrase.add_scope_for(:difficulty_with_scope, :s4)
      @phrase.add_evaluation(:difficulty_with_scope, 2, @user, :s4)
      expect(@phrase.reputation_for(:difficulty_with_scope, :s4)).to eq(2)
    end

    it "should raise exception if the scope already exist" do
      expect{Phrase.add_scope_for(:difficulty_with_scope, :s1)}.to raise_error(ArgumentError)
    end

    it "should raise exception if the reputation does not have scopes defined" do
      expect{Question.add_scope_for(:difficulty, :s1)}.to raise_error(ArgumentError)
    end
  end
end
