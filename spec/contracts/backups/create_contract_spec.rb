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
require 'contracts/shared/model_contract_shared_context'

describe Backups::CreateContract do
  let(:backup) { Backup.new }
  let(:contract) { described_class.new backup, current_user, options: { backup_token: backup_token.plain_value } }
  let(:backup_token) { FactoryBot.create :backup_token, user: current_user }

  include_context 'ModelContract shared context'

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  context 'with regular user who has the :create_backup permission' do
    let(:current_user) { FactoryBot.create :user, global_permissions: [:create_backup] }

    it_behaves_like 'contract is valid'
  end
end
