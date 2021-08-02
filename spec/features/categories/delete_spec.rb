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
require 'features/categories/categories_page'

describe 'Deletion', type: :feature do
  let(:current_user) { FactoryBot.create :admin }
  let(:category) { FactoryBot.create :category }
  let(:categories_page) { CategoriesPage.new(category.project) }
  let(:delete_button) { 'a.icon-delete' }
  let(:confirm_deletion_button) { 'input[type="submit"]' }

  before { allow(User).to receive(:current).and_return current_user }

  shared_context 'delete category' do
    before do
      categories_page.visit_settings

      expect(page).to have_selector(delete_button)

      find(delete_button).click
    end
  end

  shared_examples_for 'deleted category' do
    it { expect(page).to have_selector('div.generic-table--no-results-container') }

    it { expect(page).to have_no_selector(delete_button) }
  end

  describe 'w/o work package' do
    include_context 'delete category'

    it_behaves_like 'deleted category'
  end

  describe 'with work package' do
    let!(:work_package) do
      FactoryBot.create :work_package,
                        project: category.project,
                        category: category
    end

    include_context 'delete category'

    before do
      expect(page).to have_selector(confirm_deletion_button)

      find(confirm_deletion_button).click
    end

    it_behaves_like 'deleted category'
  end
end
