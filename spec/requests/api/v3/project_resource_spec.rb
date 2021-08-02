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
require 'rack/test'

describe 'API v3 Project resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:admin) { FactoryBot.create(:admin) }
  let(:project) do
    FactoryBot.create(:project, public: false, status: project_status, active: project_active)
  end
  let(:project_active) { true }
  let(:project_status) do
    FactoryBot.build(:project_status, project: nil)
  end
  let(:other_project) do
    FactoryBot.create(:project, public: false)
  end
  let(:role) { FactoryBot.create(:role) }
  let(:custom_field) do
    FactoryBot.create(:text_project_custom_field)
  end
  let(:custom_value) do
    CustomValue.create(custom_field: custom_field,
                       value: '1234',
                       customized: project)
  end

  before do
    login_as(current_user)
  end

  describe '#get /projects/:id' do
    let(:get_path) { api_v3_paths.project project.id }
    let!(:parent_project) do
      FactoryBot.create(:project, public: false).tap do |p|
        project.parent = p
        project.save!
      end
    end
    let!(:parent_memberships) do
      FactoryBot.create(:member,
                        user: current_user,
                        project: parent_project,
                        roles: [FactoryBot.create(:role, permissions: [])])
    end

    subject(:response) do
      get get_path

      last_response
    end

    context 'logged in user' do
      it 'responds with 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'responds with the correct project' do
        expect(subject.body).to include_json('Project'.to_json).at_path('_type')
        expect(subject.body).to be_json_eql(project.identifier.to_json).at_path('identifier')
      end

      it 'links to the parent project' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.project(parent_project.id).to_json)
          .at_path('_links/parent/href')
      end

      it 'includes custom fields' do
        custom_value

        expect(subject.body)
          .to be_json_eql(custom_value.value.to_json)
          .at_path("customField#{custom_field.id}/raw")
      end

      it 'includes the project status' do
        expect(subject.body)
          .to be_json_eql(project_status.explanation.to_json)
          .at_path("statusExplanation/raw")

        expect(subject.body)
          .to be_json_eql(api_v3_paths.project_status(project_status.code).to_json)
          .at_path("_links/status/href")
      end

      context 'requesting nonexistent project' do
        let(:get_path) { api_v3_paths.project 9999 }

        before do
          response
        end

        it_behaves_like 'not found' do
          let(:id) { 9999 }
          let(:type) { 'Project' }
        end
      end

      context 'requesting project without sufficient permissions' do
        let(:get_path) { api_v3_paths.project other_project.id }

        before do
          response
        end

        it_behaves_like 'not found' do
          let(:id) { another_project.id.to_s }
          let(:type) { 'Project' }
        end
      end

      context 'not being allowed to see the parent project' do
        let!(:parent_memberships) do
        end

        it 'shows the `undisclosed` uri' do
          expect(subject.body)
            .to be_json_eql(API::V3::URN_UNDISCLOSED.to_json)
            .at_path('_links/parent/href')
        end
      end

      context 'with the project being archived/inactive' do
        let(:project_active) { false }

        context 'with the user being admin' do
          let(:current_user) { admin }

          it 'responds with 200 OK' do
            expect(subject.status).to eq(200)
          end

          it 'responds with the correct project' do
            expect(subject.body).to include_json('Project'.to_json).at_path('_type')
            expect(subject.body).to be_json_eql(project.identifier.to_json).at_path('identifier')
          end
        end

        context 'with the user being no admin' do
          it 'responds with 404' do
            expect(subject.status).to eq(404)
          end
        end
      end
    end

    context 'not logged in user' do
      let(:current_user) { FactoryBot.create(:anonymous) }

      before do
        get get_path
      end

      it_behaves_like 'not found'
    end
  end

  describe '#get /projects' do
    let(:get_path) { api_v3_paths.projects }
    let(:response) { last_response }
    let(:projects) { [project, other_project] }

    before do
      projects

      get get_path
    end

    it 'succeeds' do
      expect(response.status)
        .to eql(200)
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'Project'

    context 'filtering for project by ancestor' do
      let(:projects) { [project, other_project, parent_project] }

      let(:parent_project) do
        parent_project = FactoryBot.create(:project, public: false, members: { current_user => role })

        project.update_attribute(:parent_id, parent_project.id)

        parent_project
      end

      let(:filter_query) do
        [{ ancestor: { operator: '=', values: [parent_project.id.to_s] } }]
      end

      let(:get_path) do
        "#{api_v3_paths.projects}?filters=#{CGI.escape(JSON.dump(filter_query))}"
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'Project'

      it 'returns the child project' do
        expect(response.body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path('_embedded/elements/0/_links/self/href')
      end
    end

    context 'with filtering by capability action' do
      let(:other_project) do
        FactoryBot.create(:project, members: [current_user])
      end
      let(:projects) { [project, other_project] }
      let(:role) { FactoryBot.create(:role, permissions: [:copy_projects]) }

      let(:get_path) do
        api_v3_paths.path_for :projects, filters: [{ "user_action": { "operator": "=", "values": ["projects/copy"] } }]
      end

      it_behaves_like 'API V3 collection response', 1, 1, 'Project'

      it 'returns the project the current user has the capability in' do
        expect(response.body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
                .at_path('_embedded/elements/0/_links/self/href')
      end
    end

    context 'filtering for principals (members)' do
      let(:other_project) do
        Role.non_member
        FactoryBot.create(:public_project)
      end
      let(:projects) { [project, other_project] }

      context 'if filtering for a value' do
        let(:filter_query) do
          [{ principal: { operator: '=', values: [current_user.id.to_s] } }]
        end

        let(:get_path) do
          "#{api_v3_paths.projects}?filters=#{CGI.escape(JSON.dump(filter_query))}"
        end

        it 'returns the filtered for value' do
          expect(response.body)
            .to be_json_eql(project.id.to_json)
            .at_path('_embedded/elements/0/id')
        end
      end

      context 'if filtering for a negative value' do
        let(:filter_query) do
          [{ principal: { operator: '!', values: [current_user.id.to_s] } }]
        end

        let(:get_path) do
          "#{api_v3_paths.projects}?filters=#{CGI.escape(JSON.dump(filter_query))}"
        end

        it 'returns the projects not matching the value' do
          expect(last_response.body)
            .to be_json_eql(other_project.id.to_json)
            .at_path('_embedded/elements/0/id')
        end
      end
    end

    context 'with filtering by visiblity' do
      let(:public_project) do
        # Otherwise, the public project is invisible
        FactoryBot.create(:non_member)

        FactoryBot.create(:public_project)
      end
      let(:member_project) do
        FactoryBot.create(:project, members: { other_user => role })
      end
      let(:non_member_project) do
        FactoryBot.create(:project)
      end
      let(:archived_member_project) do
        FactoryBot.create(:project, members: { other_user => role }, active: false)
      end
      let(:projects) { [member_project, public_project, non_member_project, archived_member_project] }
      let(:role) { FactoryBot.create(:role, permissions: []) }
      let(:other_user) do
        FactoryBot.create(:user)
      end

      let(:get_path) do
        api_v3_paths.path_for :projects, filters: [{ "visible": { "operator": "=", "values": [other_user.id.to_s] } }]
      end

      current_user { admin }

      it_behaves_like 'API V3 collection response', 2, 2, 'Project'

      it 'contains the expected projects' do
        expect(last_response.body)
          .to be_json_eql(public_project.id.to_json)
                .at_path('_embedded/elements/0/id')

        expect(last_response.body)
          .to be_json_eql(member_project.id.to_json)
                .at_path('_embedded/elements/1/id')
      end
    end

    context 'with the project being archived/inactive' do
      let(:project_active) { false }
      let(:projects) { [project] }

      context 'with the user being admin' do
        let(:current_user) { admin }

        it 'responds with 200 OK' do
          expect(last_response.status).to eq(200)
        end

        it_behaves_like 'API V3 collection response', 1, 1, 'Project'
      end

      context 'with the user being no admin' do
        it_behaves_like 'API V3 collection response', 0, 0, 'Project'

        it 'responds with 200' do
          expect(last_response.status).to eq(200)
        end
      end
    end
  end

  describe '#post /projects' do
    let(:current_user) do
      FactoryBot.create(:user).tap do |u|
        FactoryBot.create(:global_member,
                          principal: u,
                          roles: [global_role])
      end
    end
    let(:global_role) do
      FactoryBot.create(:global_role, permissions: permissions)
    end
    let(:permissions) { [:add_project] }
    let(:path) { api_v3_paths.projects }
    let(:body) do
      {
        identifier: 'new_project_identifier',
        name: 'Project name'
      }.to_json
    end

    before do
      login_as current_user

      post path, body
    end

    it 'responds with 201 CREATED' do
      expect(last_response.status).to eq(201)
    end

    it 'creates a project' do
      expect(Project.count)
        .to eql(1)
    end

    it 'returns the created project' do
      expect(last_response.body)
        .to be_json_eql('Project'.to_json)
        .at_path('_type')
      expect(last_response.body)
        .to be_json_eql('Project name'.to_json)
        .at_path('name')
    end

    context 'with a status' do
      let(:body) do
        {
          identifier: 'new_project_identifier',
          name: 'Project name',
          statusExplanation: { raw: "Some explanation." },
          _links: {
            status: {
              href: api_v3_paths.project_status('off_track')
            }
          }
        }.to_json
      end

      it 'sets the status' do
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.project_status('off_track').to_json)
                .at_path('_links/status/href')

        expect(last_response.body)
          .to be_json_eql(
            {
              "format": "markdown",
              "html": "<p class=\"op-uc-p\">Some explanation.</p>",
              "raw": "Some explanation."
            }.to_json
          )
          .at_path("statusExplanation")
      end

      it 'creates a project and a status' do
        expect(Project.count)
          .to eql(1)

        expect(Projects::Status.count)
          .to eql(1)
      end
    end

    context 'with a custom field' do
      let(:body) do
        {
          identifier: 'new_project_identifier',
          name: 'Project name',
          "customField#{custom_field.id}": {
            "raw": "CF text"
          }
        }.to_json
      end

      it 'sets the cf value' do
        expect(last_response.body)
          .to be_json_eql("CF text".to_json)
          .at_path("customField#{custom_field.id}/raw")
      end
    end

    context 'without permission to create projects' do
      let(:permissions) { [] }

      it 'responds with 403' do
        expect(last_response.status).to eq(403)
      end

      it 'creates no project' do
        expect(Project.count)
          .to eql(0)
      end
    end

    context 'with missing name' do
      let(:body) do
        {
          identifier: 'some_identifier'
        }.to_json
      end

      it 'responds with 422' do
        expect(last_response.status).to eq(422)
      end

      it 'creates no project' do
        expect(Project.count)
          .to eql(0)
      end

      it 'denotes the error' do
        expect(last_response.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path('message')
      end
    end

    context 'with a faulty status' do
      let(:body) do
        {
          identifier: 'new_project_identifier',
          name: 'Project name',
          statusExplanation: "Some explanation.",
          _links: {
            status: {
              href: api_v3_paths.project_status('faulty')
            }
          }
        }.to_json
      end

      it 'responds with 422' do
        expect(last_response.status).to eq(422)
      end

      it 'creates no project' do
        expect(Project.count)
          .to eql(0)
      end

      it 'denotes the error' do
        expect(last_response.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql("Status is not set to one of the allowed values.".to_json)
          .at_path('message')
      end
    end
  end

  describe '#patch /projects/:id' do
    let(:current_user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_with_permissions: permissions)
    end
    let(:permissions) { [:edit_project] }
    let(:path) { api_v3_paths.project(project.id) }
    let(:body) do
      {
        identifier: 'new_project_identifier',
        name: 'Project name'
      }
    end

    before do
      login_as current_user

      patch path, body.to_json
    end

    it 'responds with 200 OK' do
      expect(last_response.status).to eq(200)
    end

    it 'alters the project' do
      project.reload

      expect(project.name)
        .to eql(body[:name])

      expect(project.identifier)
        .to eql(body[:identifier])
    end

    it 'returns the updated project' do
      expect(last_response.body)
        .to be_json_eql('Project'.to_json)
        .at_path('_type')
      expect(last_response.body)
        .to be_json_eql(body[:name].to_json)
        .at_path('name')
    end

    context 'with a custom field' do
      let(:body) do
        {
          "customField#{custom_field.id}": {
            "raw": "CF text"
          }
        }
      end

      it 'responds with 200 OK' do
        expect(last_response.status).to eq(200)
      end

      it 'sets the cf value' do
        expect(project.reload.send("custom_field_#{custom_field.id}"))
          .to eql("CF text")
      end
    end

    context 'without permission to patch projects' do
      let(:permissions) { [] }

      it 'responds with 403' do
        expect(last_response.status).to eq(403)
      end

      it 'does not change the project' do
        attributes_before = project.attributes

        expect(project.reload.name)
          .to eql(attributes_before['name'])
      end
    end

    context 'with a nil status' do
      let(:body) do
        {
          statusExplanation: {
            raw: "Some explanation."
          },
          _links: {
            status: {
              href: nil
            }
          }
        }
      end

      it 'alters the status' do
        expect(last_response.body)
          .to be_json_eql(nil.to_json)
          .at_path('_links/status/href')

        status = project.status.reload
        expect(status.code).to be_nil
        expect(status.explanation).to eq 'Some explanation.'

        expect(last_response.body)
          .to be_json_eql(
            {
              "format": "markdown",
              "html": "<p class=\"op-uc-p\">Some explanation.</p>",
              "raw": "Some explanation."
            }.to_json
          )
          .at_path("statusExplanation")
      end
    end

    context 'with a status' do
      let(:body) do
        {
          statusExplanation: {
            raw: "Some explanation."
          },
          _links: {
            status: {
              href: api_v3_paths.project_status('off_track')
            }
          }
        }
      end

      it 'alters the status' do
        expect(last_response.body)
          .to be_json_eql(api_v3_paths.project_status('off_track').to_json)
          .at_path('_links/status/href')

        expect(last_response.body)
          .to be_json_eql(
            {
              "format": "markdown",
              "html": "<p class=\"op-uc-p\">Some explanation.</p>",
              "raw": "Some explanation."
            }.to_json
          )
          .at_path("statusExplanation")
      end

      it 'persists the altered status' do
        project_status.reload

        expect(project_status.code)
          .to eql('off_track')

        expect(project_status.explanation)
          .to eql('Some explanation.')
      end
    end

    context 'with faulty name' do
      let(:body) do
        {
          name: nil
        }
      end

      it 'responds with 422' do
        expect(last_response.status).to eq(422)
      end

      it 'does not change the project' do
        attributes_before = project.attributes

        expect(project.reload.name)
          .to eql(attributes_before['name'])
      end

      it 'denotes the error' do
        expect(last_response.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(last_response.body)
          .to be_json_eql("Name can't be blank.".to_json)
          .at_path('message')
      end
    end

    context 'with a faulty status' do
      let(:body) do
        {
          _links: {
            status: {
              href: api_v3_paths.project_status("bogus")
            }
          }
        }
      end

      it 'responds with 422' do
        expect(last_response.status).to eq(422)
      end

      it 'does not change the project status' do
        code_before = project_status.code

        expect(project_status.reload.code)
          .to eql(code_before)
      end

      it 'denotes the error' do
        expect(last_response.body)
          .to be_json_eql('Error'.to_json)
                .at_path('_type')

        expect(last_response.body)
          .to be_json_eql("Status is not set to one of the allowed values.".to_json)
                .at_path('message')
      end
    end

    context 'deactivating (archiving) the project' do
      context 'for an admin' do
        let(:current_user) do
          FactoryBot.create(:admin)
        end
        let(:project) do
          FactoryBot.create(:project).tap do |p|
            p.children << child_project
          end
        end
        let(:child_project) do
          FactoryBot.create(:project)
        end

        let(:body) do
          {
            active: false
          }
        end

        it 'responds with 200 OK' do
          expect(last_response.status)
            .to eql(200)
        end

        it 'archives the project' do
          expect(project.reload.active)
            .to be_falsey
        end

        it 'archives the child project' do
          expect(child_project.reload.active)
            .to be_falsey
        end
      end

      context 'for a non admin' do
        let(:body) do
          {
            active: false
          }
        end

        it 'responds with 403' do
          expect(last_response.status)
            .to eql(403)
        end

        it 'does not alter the project' do
          expect(project.reload.active)
            .to be_truthy
        end
      end
    end
  end

  describe '#delete /api/v3/projects/:id' do
    let(:path) { api_v3_paths.project(project.id) }
    let(:setup) {}

    before do
      login_as current_user

      setup

      delete path

      # run the deletion job
      perform_enqueued_jobs
    end

    subject { last_response }

    context 'with required permissions (admin)' do
      let(:current_user) { FactoryBot.create(:admin) }

      it 'responds with HTTP No Content' do
        expect(subject.status).to eq 204
      end

      it 'deletes the project' do
        expect(Project.exists?(project.id)).to be_falsey
      end

      context 'for a project with work packages' do
        let(:work_package) { FactoryBot.create(:work_package, project: project) }
        let(:setup) { work_package }

        it 'deletes the work packages' do
          expect(WorkPackage.exists?(work_package.id)).to be_falsey
        end
      end

      context 'for a project with members' do
        let(:member) do
          FactoryBot.create(:member,
                            project: project,
                            principal: current_user,
                            roles: [FactoryBot.create(:role)])
        end
        let(:member_role) { member.member_roles.first }
        let(:setup) do
          member
          member_role
        end

        it 'deletes the member' do
          expect(Member.exists?(member.id)).to be_falsey
        end

        it 'deletes the MemberRole' do
          expect(MemberRole.exists?(member_role.id)).to be_falsey
        end
      end

      context 'for a project with a forum' do
        let(:forum) do
          FactoryBot.create(:forum,
                            project: project)
        end
        let(:setup) do
          forum
        end

        it 'deletes the forum' do
          expect(Forum.exists?(forum.id)).to be_falsey
        end
      end

      context 'for a non-existent project' do
        let(:path) { api_v3_paths.project 0 }

        it_behaves_like 'not found' do
          let(:id) { 0 }
          let(:type) { 'Project' }
        end
      end

      context 'for a project which has a version foreign work packages refer to' do
        let(:version) { FactoryBot.create(:version, project: project) }
        let(:work_package) { FactoryBot.create(:work_package, version: version) }

        let(:setup) { work_package }

        it 'responds with 422' do
          expect(subject.status).to eq 422
        end

        it 'explains the error' do
          expect(subject.body)
            .to be_json_eql(I18n.t(:'activerecord.errors.models.project.foreign_wps_reference_version').to_json)
            .at_path('message')
        end
      end
    end

    context 'without required permissions' do
      it 'responds with 403' do
        expect(subject.status).to eq 403
      end
    end
  end
end
