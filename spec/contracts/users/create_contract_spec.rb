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
require_relative 'shared_contract_examples'

describe Users::CreateContract do
  include_context 'ModelContract shared context'

  it_behaves_like 'user contract' do
    let(:user) { User.new(attributes) }
    let(:contract) { described_class.new(user, current_user) }
    let(:attributes) do
      {
        firstname: user_firstname,
        lastname: user_lastname,
        login: user_login,
        mail: user_mail,
        password: user_password,
        password_confirmation: user_password_confirmation
      }
    end

    context 'when admin' do
      let(:current_user) { FactoryBot.build_stubbed(:admin) }

      it_behaves_like 'contract is valid'

      describe 'requires a password set when active' do
        before do
          user.password = nil
          user.password_confirmation = nil
          user.activate
        end

        it_behaves_like 'contract is invalid', password: :blank

        context 'when password is set' do
          before do
            user.password = user.password_confirmation = 'password!password!'
          end

          it_behaves_like 'contract is valid'
        end
      end
    end
  end
end
