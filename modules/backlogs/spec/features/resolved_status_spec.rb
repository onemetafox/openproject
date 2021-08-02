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

describe 'Resolved status',
         type: :feature do
  let!(:project) do
    FactoryBot.create(:project,
                      enabled_module_names: %w(backlogs))
  end
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i(edit_project))
  end
  let!(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:settings_page) { Pages::Projects::Settings.new(project) }

  before do
    login_as current_user
  end

  it 'allows setting a status as done although it is not closed' do
    settings_page.visit_tab! 'backlogs'

    check status.name
    click_button 'Save'

    settings_page.expect_notification(message: 'Successful update')

    expect(page)
      .to have_checked_field(status.name)
  end
end
