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

require 'spec_helper'

describe TimeEntries::Scopes::Visible, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end
  let(:permissions) { [:view_time_entries] }

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      author: user2)
  end
  let(:user2) do
    FactoryBot.create(:user)
  end
  let!(:own_project_time_entry) do
    FactoryBot.create(:time_entry,
                      project: project,
                      work_package: work_package,
                      hours: 2,
                      user: user)
  end
  let!(:project_time_entry) do
    FactoryBot.create(:time_entry,
                      project: project,
                      work_package: work_package,
                      hours: 2,
                      user: user2)
  end
  let!(:own_other_project_time_entry) do
    FactoryBot.create(:time_entry,
                      project: FactoryBot.create(:project),
                      user: user)
  end

  describe '.visible' do
    subject { TimeEntry.visible(user) }

    context 'for a user having the view_time_entries permission' do
      it 'retrieves all the time entries of projects the user has the permissions in' do
        expect(subject)
          .to match_array([own_project_time_entry, project_time_entry])
      end
    end

    context 'for a user having the view_own_time_entries permission' do
      let(:permissions) { [:view_own_time_entries] }

      it 'retrieves all the time entries of the user in projects the user has the permissions in' do
        expect(subject)
          .to match_array([own_project_time_entry])
      end
    end
  end
end
