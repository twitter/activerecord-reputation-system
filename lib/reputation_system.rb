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

require 'reputation_system/base'
require 'reputation_system/query_methods'
require 'reputation_system/finder_methods'
require 'reputation_system/query_builder'
require 'reputation_system/evaluation_methods'
require 'reputation_system/network'
require 'reputation_system/reputation_methods'
require 'reputation_system/scope_methods'
require 'reputation_system/models/evaluation'
require 'reputation_system/models/reputation'
require 'reputation_system/models/reputation_message'

ActiveRecord::Base.send(:include, ReputationSystem::Base)
