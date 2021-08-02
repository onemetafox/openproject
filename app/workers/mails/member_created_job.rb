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

class Mails::MemberCreatedJob < Mails::MemberJob
  private

  alias_method :send_for_project_user, :send_added_project

  def send_for_group_user(current_user, user_member, group_member, message)
    if new_roles_added?(user_member, group_member)
      send_updated_project(current_user, user_member, message)
    elsif all_roles_added?(user_member, group_member)
      send_added_project(current_user, user_member, message)
    end
  end

  def new_roles_added?(user_member, group_member)
    (group_member.member_roles.map(&:id) - user_member.member_roles.map(&:inherited_from)).length <
      group_member.member_roles.length && user_member.member_roles.any? { |mr| mr.inherited_from.nil? }
  end

  def all_roles_added?(user_member, group_member)
    (user_member.member_roles.map(&:inherited_from) - group_member.member_roles.map(&:id)).empty?
  end
end
