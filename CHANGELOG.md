* Fix a bug that raises exception when associations related reputation propageted has not been initialized at that time.

* Remove reputation_value_for and normalized_reputation_value_for methods.

* Add `evaluations` association for all evaluation targets.

* Set `:sum` as default for `aggregated_by` option.

* Rename models - RSReputation to ReputationSystem::Reputation, RSEvaluation to ReputationSystem::Evaluation and RSReputationMessage to ReputationSystem::ReputationMessage

## ActiveRecordReputationSystem 1.5.0 ##

* Add a support for STI.

* Add `reputation_for` and `normalized_reputation_for` methods that are shorten name of `reputation_value_for` and `normalized_reputation_value_for` methods.

## ActiveRecordReputationSystem 1.4.0 ##

* Add `with_normalized_reputation` and `with_normalized_reputation_only`.

* Add `with_reputation` and `with_reputation_only` methods.

## ActiveRecordReputationSystem 1.3.4 ##

* Fix name of a migration class again.

## ActiveRecordReputationSystem 1.3.3 ##

* Fix name of a migration class.

## ActiveRecordReputationSystem 1.3.2 ##

* Add migration files.

## ActiveRecordReputationSystem 1.3.1 ##

* Make index unique.

## ActiveRecordReputationSystem 1.3.0 ##

* Add `evaluated_by method`.

* Make evaluation methods return true on success.

## ActiveRecordReputationSystem 1.2.1 ##

* Fix index names to be able to `db:rollback` the migrations.

## ActiveRecordReputationSystem 1.2.0 ##

* Fix race conditions with uniqueness validations.

## ActiveRecordReputationSystem 1.1.0 ##

* Add `increase_evaluation` and `decrease_evaluation` methods.

* Fix `add_or_update_evaluation` bug when using scope.

* Fix README bugs.

## ActiveRecordReputationSystem 1.0.0 ##

* Open sourced to the world!

* Sanitize all sql statements in query.rb.

* Add validations for reputation messages.

* Rename spec gem.

* Overwrite existing reputation definitions instead of raising exceptions.

* Rename `reputation_system` to `reputation_system_active_record`.

* Support initial value.

* Support for default `source_of` attribute.

* Change gem name from `reputation-system` to `reputation_system`.

* No more active record models export upon reputation system generation.

* Remove rails init files.

* Major refactoring.

* Rename `normalize` to `active`.

* Fix Query bug.

* Remove `ExternalSource` support.

* Add `rank_for` method.

* Add count query interface.

* Organize Rakefile more nicely.

* Organize the gem more nicely.

* Add non strict version of `delete_evaluation` method.

* Fix rails 3.2 issue

* Stop using transaction.

* Really make ActiveRecord 3 compatible

* Make ActiveRecord 3 compatible

* Add a method to check if a reputation is included for normalization.

* Improve Generator.

* Allow reputation to be inactive so that it will not count into the normalized value.

* Destroy dependent reputations and reputation messages.

* Add method to output sql statement for querying.

* Add normalized value support for querying.

* Add scope support for querying.

* Removing dependencies.

* Fix `instance_exec` error.

* Add query interface.

* Use transaction for better performance.

* Fix a bug related to `add_or_update_evaluation`.

* Add normalized reputation value accessor.

* Rename all models for organization and for a patch to deal with bug in class caching.

* Add default value (:self) for `:of` attributes. Fix scope bug. Add support for non-array `:source_of` value.

* Add support for scoping reputations.

* Major redesign of the framework. Now supports "Multiple level" of reputation relationship.

* First Iteration with minimum capability. Only supporting "One level" of reputation relationship.
