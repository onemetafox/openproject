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
require File.expand_path('../support/shared/become_member', __dir__)

describe Project, type: :model do
  include BecomeMember
  shared_let(:admin) { FactoryBot.create :admin }

  let(:active) { true }
  let(:project) { FactoryBot.create(:project, active: active) }
  let(:build_project) { FactoryBot.build_stubbed(:project, active: active) }
  let(:user) { FactoryBot.create(:user) }

  describe '#active?' do
    context 'if active' do
      it 'is true' do
        expect(project).to be_active
      end
    end

    context 'if not active' do
      let(:active) { false }

      it 'is false' do
        expect(project).not_to be_active
      end
    end
  end

  describe '#archived?' do
    context 'if active' do
      it 'is true' do
        expect(project).not_to be_archived
      end
    end

    context 'if not active' do
      let(:active) { false }

      it 'is false' do
        expect(project).to be_archived
      end
    end
  end

  context 'when the wiki module is enabled' do
    let(:project) { FactoryBot.create(:project, disable_modules: 'wiki') }

    before :each do
      project.enabled_module_names = project.enabled_module_names | ['wiki']
      project.save
      project.reload
    end

    it 'creates a wiki' do
      expect(project.wiki).to be_present
    end

    it 'creates a wiki menu item named like the default start page' do
      expect(project.wiki.wiki_menu_items).to be_one
      expect(project.wiki.wiki_menu_items.first.title).to eq(project.wiki.start_page)
    end
  end

  describe '#copy_allowed?' do
    let(:user) { FactoryBot.build_stubbed(:user) }
    let(:project) { FactoryBot.build_stubbed(:project) }
    let(:permission_granted) { true }

    before do
      allow(user)
        .to receive(:allowed_to?)
        .with(:copy_projects, project)
        .and_return(permission_granted)

      login_as(user)
    end

    context 'with copy project permission' do
      it 'is true' do
        expect(project.copy_allowed?).to be_truthy
      end
    end

    context 'without copy project permission' do
      let(:permission_granted) { false }

      it 'is false' do
        expect(project.copy_allowed?).to be_falsey
      end
    end
  end

  describe 'status' do
    let(:status) { FactoryBot.build_stubbed(:project_status) }
    let(:stubbed_project) do
      FactoryBot.build_stubbed(:project,
                               status: status)
    end

    it 'has a status' do
      expect(stubbed_project.status)
        .to eql status
    end

    it 'is destroyed along with the project' do
      status = project.create_status explanation: 'some description'

      project.destroy!

      expect(Projects::Status.where(id: status.id))
        .not_to exist
    end
  end

  describe 'name' do
    let(:project) { FactoryBot.build_stubbed :project, name: '     Hello    World   ' }

    before do
      project.valid?
    end

    it 'trims the name' do
      expect(project.name).to eql('Hello World')
    end
  end

  describe '#types_used_by_work_packages' do
    let(:project) { FactoryBot.create(:project_with_types) }
    let(:type) { project.types.first }
    let(:other_type) { FactoryBot.create(:type) }
    let(:project_work_package) { FactoryBot.create(:work_package, type: type, project: project) }
    let(:other_project) { FactoryBot.create(:project, types: [other_type, type]) }
    let(:other_project_work_package) { FactoryBot.create(:work_package, type: other_type, project: other_project) }

    it 'returns the type used by a work package of the project' do
      project_work_package
      other_project_work_package

      expect(project.types_used_by_work_packages).to match_array [project_work_package.type]
    end
  end

  context '#rolled_up_versions' do
    let!(:project) { FactoryBot.create(:project) }
    let!(:parent_version1) { FactoryBot.create(:version, project: project) }
    let!(:parent_version2) { FactoryBot.create(:version, project: project) }

    it 'should include the versions for the current project' do
      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2]
    end

    it 'should include versions for a subproject' do
      subproject = FactoryBot.create(:project, parent: project)
      subproject_version = FactoryBot.create(:version, project: subproject)

      project.reload

      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2, subproject_version]
    end

    it 'should include versions for a sub-subproject' do
      subproject = FactoryBot.create(:project, parent: project)
      sub_subproject = FactoryBot.create(:project, parent: subproject)
      sub_subproject_version = FactoryBot.create(:version, project: sub_subproject)

      project.reload

      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2, sub_subproject_version]
    end

    it 'should only check active projects' do
      subproject = FactoryBot.create(:project, parent: project)
      FactoryBot.create(:version, project: subproject)
      subproject.update(active: false)

      project.reload

      expect(subproject)
        .not_to be_active
      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2]
    end
  end
end
