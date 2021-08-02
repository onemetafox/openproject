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

class Members::CreateService < ::BaseServices::Create
  around_call :post_process

  def post_process
    service_call = yield

    return unless service_call.success?

    member = service_call.result

    add_group_memberships(member)
    send_notification(member)
  end

  protected

  def send_notification(member)
    OpenProject::Notifications.send(OpenProject::Events::MEMBER_CREATED,
                                    member: member,
                                    message: params[:notification_message])
  end

  def add_group_memberships(member)
    return unless member.principal.is_a?(Group)

    Groups::AddUsersService
      .new(member.principal, current_user: user, contract_class: EmptyContract)
      .call(ids: member.principal.user_ids, send_notifications: false)
  end

  def set_attributes_params(params)
    super.except(:notification_message)
  end
end
