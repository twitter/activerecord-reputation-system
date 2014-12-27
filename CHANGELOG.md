# 3.0.1 (November 27, 2014)

  * Remove `protected_attributes` to fix a Rails 4 compatibility.

# 3.0.0 (October 7, 2014)

  * Add ability to set custom aggregation functions. (Caio Almeida)

  * Add serialized data field to evaluation and reputation models. (Caio Almeida)

  * Make ActiveRecord 4 compatible.

  * Drop Rails 3 and Ruby 1.8 support.

# 2.0.2 (December 1, 2012)

  * Fix a bug associated with `add_or_update_evaluation` method that happens when
    source uses STI.

# 2.0.1 (October 5, 2012)

  * Print out future deprecation warning for methods `with_reputation` and
    `with_normalized_reputation`.

  * Fix a finder related bug.

# 2.0.0 (October 5, 2012)

  * Deprecate `init_value` option.

  * Fix a average computation bug associated with deletes.

  * `delete_evaluation` returns false on failure, instead of nil.

  * Add `has_evaluation?` method.

  * Add auto-require `reputation_system`.

  * Add `evaluators_for` method.

  * Deprecate `reputation_value_for` and `normalized_reputation_value_for`
    methods.

  * Add `evaluations` association for all evaluation targets.

  * Set `:sum` as default for `aggregated_by` option.

  * Rename models - RSReputation to ReputationSystem::Reputation, RSEvaluation to
    ReputationSystem::Evaluation and RSReputationMessage to
    ReputationSystem::ReputationMessage

# 1.5.1 (October 4, 2012)

  * Fix a bug that raises exception when associations related reputation
    propageted has not been initialized at that time.

# 1.5.0 (September 15, 2012)

  * Add a support for STI.

  * Add `reputation_for` and `normalized_reputation_for` methods that are shorten
    name of `reputation_value_for` and `normalized_reputation_value_for` methods.

# 1.4.0 (September 10, 2012)

  * Add `with_normalized_reputation` and `with_normalized_reputation_only`.

  * Add `with_reputation` and `with_reputation_only` methods.

# 1.3.4 (August 9, 2012)

  * Fix name of a migration class again.

# 1.3.3 (August 8, 2012)

  * Fix name of a migration class.

# 1.3.2 (August 8, 2012)

  * Add migration files.

# 1.3.1 (August 8, 2012)

  * Make index unique.

# 1.3.0 (August 1, 2012)

  * Add `evaluated_by method`.

  * Make evaluation methods return true on success.

# 1.2.1 (July 14, 2012)

  * Fix index names to be able to `db:rollback` the migrations. (Amr Tamimi)

# 1.2.0 (June 12, 2012)

  * Fix race conditions with uniqueness validations.

# 1.1.0 (May 22, 2012)

  * Add `increase_evaluation` and `decrease_evaluation` methods.

  * Fix `add_or_update_evaluation` bug when using scope.

  * Fix README bugs. (Eli Fox-Epstein)

# 1.0.0 (May 17, 2012)

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

  * Allow reputation to be inactive so that it will not count into the normalized
    value.

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

  * Rename all models for organization and for a patch to deal with bug in class
    caching.

  * Add default value (:self) for `:of` attributes. Fix scope bug. Add support for
    non-array `:source_of` value.

  * Add support for scoping reputations.

  * Major redesign of the framework. Now supports "Multiple level" of reputation
    relationship.

  * First Iteration with minimum capability. Only supporting "One level" of
    reputation relationship.
