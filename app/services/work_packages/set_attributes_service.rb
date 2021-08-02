#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::SetAttributesService < ::BaseServices::SetAttributes
  include Attachments::SetReplacements

  private

  def set_attributes(attributes)
    set_attachments_attributes(attributes)
    set_static_attributes(attributes)

    model.change_by_system do
      set_default_attributes(attributes)
      update_project_dependent_attributes
    end

    set_custom_attributes(attributes)

    model.change_by_system do
      update_dates
      reassign_invalid_status_if_type_changed
      set_templated_description
    end
  end

  def set_static_attributes(attributes)
    assignable_attributes = attributes.select do |key, _|
      !CustomField.custom_field_attribute?(key) && work_package.respond_to?(key)
    end

    work_package.attributes = assignable_attributes
  end

  def set_default_attributes(attributes)
    return unless work_package.new_record?

    set_default_priority
    set_default_author
    set_default_status
    set_default_start_date(attributes)
    set_default_due_date(attributes)
  end

  def non_or_default_description?
    work_package.description.blank? || false
  end

  def set_default_author
    work_package.author ||= user
  end

  def set_default_status
    work_package.status ||= Status.default
  end

  def set_default_priority
    work_package.priority ||= IssuePriority.active.default
  end

  def set_default_start_date(attributes)
    work_package.start_date ||= if attributes.has_key?(:start_date)
                                  nil
                                elsif parent_start_earlier_than_due?
                                  work_package.parent.start_date
                                elsif Setting.work_package_startdate_is_adddate?
                                  Date.today
                                end
  end

  def set_default_due_date(attributes)
    work_package.due_date ||= if attributes.has_key?(:due_date)
                                nil
                              elsif parent_due_later_than_start?
                                work_package.parent.due_date
                              end
  end

  def set_templated_description
    # We only set this if the work package is new
    return unless work_package.new_record?

    # And the type was changed
    return unless work_package.type_id_changed?

    # And the new type has a default text
    default_description = work_package.type&.description
    return unless default_description.present?

    # And the current description matches ANY current default text
    return unless work_package.description.blank? || default_description?

    work_package.description = default_description
  end

  def default_description?
    Type
      .pluck(:description)
      .compact
      .map(&method(:normalize_whitespace))
      .include?(normalize_whitespace(work_package.description))
  end

  def normalize_whitespace(string)
    string.gsub(/\s/, ' ').squeeze(' ')
  end

  def set_custom_attributes(attributes)
    assignable_attributes = attributes.select do |key, _|
      CustomField.custom_field_attribute?(key) && work_package.respond_to?(key)
    end

    work_package.attributes = assignable_attributes

    initialize_unset_custom_values
  end

  def unify_dates
    return unless work_package_now_milestone?

    unified_date = work_package.due_date || work_package.start_date
    work_package.start_date = work_package.due_date = unified_date
  end

  def custom_field_context_changed?
    work_package.type_id_changed? || work_package.project_id_changed?
  end

  def work_package_now_milestone?
    work_package.type_id_changed? && work_package.milestone?
  end

  def update_project_dependent_attributes
    return unless work_package.project_id_changed? && work_package.project_id

    model.change_by_system do
      set_version_to_nil
      reassign_category

      reassign_type unless work_package.type_id_changed?
    end
  end

  def update_dates
    unify_dates

    min_start = new_start_date

    return unless min_start

    work_package.due_date = new_due_date(min_start)
    work_package.start_date = min_start
  end

  def set_version_to_nil
    if work_package.version &&
       !work_package.project&.shared_versions.include?(work_package.version)
      work_package.version = nil
    end
  end

  def reassign_category
    # work_package is moved to another project
    # reassign to the category with same name if any
    if work_package.category.present?
      category = work_package.project.categories.find_by(name: work_package.category.name)

      work_package.category = category
    end
  end

  def reassign_type
    available_types = work_package.project.types.order(:position)

    return if available_types.include?(work_package.type) && work_package.type

    work_package.type = available_types.first

    reassign_status assignable_statuses
  end

  def reassign_status(available_statuses)
    return if available_statuses.include?(work_package.status) || work_package.status.is_a?(Status::InexistentStatus)

    new_status = available_statuses.detect(&:is_default) || available_statuses.first
    work_package.status = new_status if new_status.present?
  end

  def reassign_invalid_status_if_type_changed
    # Checks that the issue can not be moved to a type with the status unchanged
    # and the target type does not have this status
    if work_package.type_id_changed? && !work_package.status_id_changed?
      reassign_status work_package.type.statuses(include_default: true)
    end
  end

  # Take over any default custom values
  # for new custom fields
  def initialize_unset_custom_values
    work_package.set_default_values! if custom_field_context_changed?
  end

  def new_start_date
    current_start_date = work_package.start_date || work_package.due_date

    return unless current_start_date && work_package.schedule_automatically?

    min_start = new_start_date_from_parent || new_start_date_from_self

    if min_start && (min_start > current_start_date || work_package.schedule_manually_changed?)
      min_start
    end
  end

  def new_start_date_from_parent
    return unless work_package.parent_id_changed? &&
                  work_package.parent_id

    work_package.parent.soonest_start
  end

  def new_start_date_from_self
    return unless work_package.schedule_manually_changed?

    [min_child_date, work_package.soonest_start].compact.max
  end

  def new_due_date(min_start)
    min_start + (children_duration || work_package.duration) - 1
  end

  def work_package
    model
  end

  def assignable_statuses
    instantiate_contract(work_package, user).assignable_statuses(true)
  end

  def min_child_date
    (work_package.children.map(&:start_date) + work_package.children.map(&:due_date)).compact.min
  end

  def children_duration
    max = max_child_date

    return unless max

    max - min_child_date + 1
  end

  def max_child_date
    (work_package.children.map(&:start_date) + work_package.children.map(&:due_date)).compact.max
  end

  def parent_start_earlier_than_due?
    start = work_package.parent&.start_date
    due = work_package.due_date || work_package.parent&.due_date

    (start && !due) || ((due && start) && (start < due))
  end

  def parent_due_later_than_start?
    due = work_package.parent&.due_date
    start = work_package.start_date || work_package.parent&.start_date

    (due && !start) || ((due && start) && (due > start))
  end
end
