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

require 'support/shared/acts_as_watchable'

describe WorkPackage, type: :model do
  let(:project) { FactoryBot.create(:project) }
  let(:work_package) do
    FactoryBot.create(:work_package,
                      project: project)
  end

  it_behaves_like 'acts_as_watchable included' do
    let(:model_instance) { FactoryBot.create(:work_package) }
    let(:watch_permission) { :view_work_packages }
    let(:project) { model_instance.project }
  end

  # This is not really a trait of acts as watchable but rather of
  # the work package observer + journal observer
  context 'notifications' do
    let(:number_of_recipients) { (work_package.recipients | work_package.watcher_recipients).length }
    let(:current_user) { FactoryBot.create :user }

    before do
      allow(UserMailer).to receive_message_chain :work_package_updated, :deliver

      # Ensure notification setting to be set in a way that will trigger e-mails.
      allow(Setting).to receive(:notified_events).and_return(%w(work_package_updated))
      expect(UserMailer).to receive(:work_package_updated).exactly(number_of_recipients).times

      allow(User).to receive(:current).and_return(current_user)
    end

    it 'sends one delayed mail notification for each watcher recipient' do
      work_package.update description: 'Any new description'
    end
  end
end
