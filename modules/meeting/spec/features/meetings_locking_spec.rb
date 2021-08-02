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

describe 'Meetings locking', type: :feature, js: true do
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[meetings] }
  let(:user) { FactoryBot.create :admin }
  let!(:meeting) { FactoryBot.create :meeting }
  let!(:agenda) { FactoryBot.create :meeting_agenda, meeting: meeting }

  before do
    login_as(user)

    visit meeting_path(meeting)
  end

  it 'shows an error when trying to update a meeting update while editing' do
    # Edit agenda
    within '#tab-content-agenda' do
      find('.button--edit-agenda').click

      SeleniumHubWaiter.wait
      agenda.text = 'blabla'
      agenda.save!

      click_on 'Save'
    end

    expect(page).to have_text 'Information has been updated by at least one other user in the meantime.'
    expect(page).to have_selector '#edit-meeting_agenda'
  end
end
