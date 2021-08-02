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

require 'spec_helper'

describe 'Custom actions me value', type: :feature, js: true do
  shared_let(:admin) { FactoryBot.create :admin }

  let(:permissions) { %i(view_work_packages edit_work_packages) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:user) do
    FactoryBot.create(:user,
                             member_in_project: project,
                             member_through_role: role)
  end
  let(:type) { FactoryBot.create(:type_task) }
  let(:project) { FactoryBot.create(:project, types: [type], name: 'This project') }
  let!(:custom_field) { FactoryBot.create :user_wp_custom_field, types: [type], projects: [project] }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                      type: type,
                      project: project)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:default_priority) do
    FactoryBot.create(:default_priority, name: 'Normal')
  end
  let(:index_ca_page) { Pages::Admin::CustomActions::Index.new }

  before do
    with_enterprise_token(:custom_actions)
    login_as(admin)
  end

  it 'can assign user custom field to self' do
    # create custom action 'Unassign'
    index_ca_page.visit!

    new_ca_page = index_ca_page.new
    retry_block do
      new_ca_page.visit!
      new_ca_page.set_name('Set CF to me')
      new_ca_page.add_action(custom_field.name, I18n.t('custom_actions.actions.assigned_to.executing_user_value'))
    end

    new_ca_page.create

    assign = CustomAction.last
    expect(assign.actions.length).to eq(1)
    expect(assign.conditions.length).to eq(0)
    expect(assign.actions.first.values).to eq(['current_user'])

    login_as user
    wp_page.visit!

    wp_page.expect_custom_action('Set CF to me')
    wp_page.click_custom_action('Set CF to me')
    wp_page.expect_attributes "customField#{custom_field.id}": user.name
  end
end
