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

describe Notifications::GroupMemberAlteredJob, type: :model do
  subject(:service_call) do
    described_class.new.perform(members_ids, message)
  end
  let(:time) { Time.now }
  let(:member1) do
    FactoryBot.build_stubbed(:member, updated_at: time, created_at: time)
  end
  let(:member2) do
    FactoryBot.build_stubbed(:member, updated_at: time + 1.second, created_at: time)
  end
  let(:members) { [member1, member2] }
  let(:members_ids) { members.map(&:id) }
  let(:message) { "Some message" }

  before do
    allow(OpenProject::Notifications)
      .to receive(:send)

    allow(Member)
      .to receive(:where)
      .with(id: members_ids)
      .and_return(members)
  end

  it 'sends a created notification for the membership with the matching timestamps' do
    service_call

    expect(OpenProject::Notifications)
      .to have_received(:send)
      .with(OpenProject::Events::MEMBER_CREATED, member: member1, message: message)
  end

  it 'sends an updated notification for the membership with the mismatching timestamps' do
    service_call

    expect(OpenProject::Notifications)
      .to have_received(:send)
      .with(OpenProject::Events::MEMBER_UPDATED, member: member2, message: message)
  end
end
