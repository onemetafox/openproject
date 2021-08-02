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

describe WorkPackage, type: :model do
  describe '#relation' do
    let(:closed_state) do
      FactoryBot.create(:status,
                        is_closed: true)
    end

    describe '#duplicate' do
      let(:status) { FactoryBot.create(:status) }
      let(:type) { FactoryBot.create(:type) }
      let(:original) do
        FactoryBot.create(:work_package,
                          project: project,
                          type: type,
                          status: status)
      end
      let(:project) { FactoryBot.create(:project, members: { current_user => workflow.role }) }
      let(:dup_1) do
        FactoryBot.create(:work_package,
                          project: project,
                          type: type,
                          status: status)
      end
      let(:relation_org_dup_1) do
        FactoryBot.create(:relation,
                          from: dup_1,
                          to: original,
                          relation_type: Relation::TYPE_DUPLICATES)
      end
      let(:workflow) do
        FactoryBot.create(:workflow,
                          old_status: status,
                          new_status: closed_state,
                          type_id: type.id)
      end
      current_user { FactoryBot.create(:user) }

      context 'closes duplicates' do
        let(:dup_2) do
          FactoryBot.create(:work_package,
                            project: project,
                            type: type,
                            status: status)
        end
        let(:relation_dup_1_dup_2) do
          FactoryBot.create(:relation,
                            from: dup_2,
                            to: dup_1,
                            relation_type: Relation::TYPE_DUPLICATES)
        end
        # circular dependency
        let(:relation_dup_2_org) do
          FactoryBot.create(:relation,
                            from: dup_2,
                            to: original,
                            relation_type: Relation::TYPE_DUPLICATES)
        end

        before do
          relation_org_dup_1
          relation_dup_1_dup_2
          relation_dup_2_org

          original.status = closed_state
          original.save!

          dup_1.reload
          dup_2.reload
        end

        it 'only duplicates are closed' do
          expect(dup_1.closed?).to be_truthy
          expect(dup_2.closed?).to be_truthy
        end
      end

      context 'duplicated is not closed' do
        before do
          relation_org_dup_1

          dup_1.status = closed_state
          dup_1.save!

          original.reload
        end

        subject { original.closed? }

        it { is_expected.to be_falsey }
      end
    end

    describe '#soonest_start' do
      let(:predecessor) do
        FactoryBot.create(:work_package,
                          due_date: predecessor_due_date)
      end
      let(:predecessor_due_date) { nil }
      let(:successor) do
        FactoryBot.create(:work_package,
                          schedule_manually: successor_schedule_manually,
                          project: predecessor.project)
      end
      let(:successor_schedule_manually) { false }
      let(:successor_child) do
        FactoryBot.create(:work_package,
                          schedule_manually: successor_child_schedule_manually,
                          parent: successor,
                          project: predecessor.project)
      end
      let(:successor_child_schedule_manually) { false }
      let(:successor_grandchild) do
        FactoryBot.create(:work_package,
                          parent: successor_child,
                          project: predecessor.project)
      end
      let(:relation_successor) do
        FactoryBot.create(:relation,
                          from: predecessor,
                          to: successor,
                          relation_type: Relation::TYPE_PRECEDES)
      end
      let(:work_packages) { [predecessor, successor, successor_child] }
      let(:relations) { [relation_successor] }

      before do
        work_packages
        relations
      end

      context 'without a predecessor' do
        let(:work_packages) { [successor] }
        let(:relations) { [] }

        it { expect(successor.soonest_start).to be_nil }
      end

      context 'with a predecessor' do
        let(:work_packages) { [predecessor, successor] }

        context 'start date exists in predecessor' do
          let(:predecessor_due_date) { Date.today }

          it { expect(successor_child.soonest_start).to eq(predecessor.due_date + 1) }
        end

        context 'no date in predecessor' do
          it { expect(successor_child.soonest_start).to be_nil }
        end
      end

      context 'with the parent having a predecessor' do
        let(:work_packages) { [predecessor, successor, successor_child] }

        context 'start date exists in predecessor' do
          let(:predecessor_due_date) { Date.today }

          it { expect(successor_child.soonest_start).to eq(predecessor.due_date + 1) }

          context 'with the parent manually scheduled' do
            let(:successor_schedule_manually) { true }

            it { expect(successor_child.soonest_start).to be_nil }
          end
        end

        context 'no start date exists in related work packages' do
          it { expect(successor_child.soonest_start).to be_nil }
        end
      end

      context 'with the grandparent having a predecessor' do
        let(:work_packages) { [predecessor, successor, successor_child, successor_grandchild] }

        context 'start date exists in predecessor' do
          let(:predecessor_due_date) { Date.today }

          it { expect(successor_grandchild.soonest_start).to eq(predecessor.due_date + 1) }

          context 'with the grandparent manually scheduled' do
            let(:successor_schedule_manually) { true }

            it { expect(successor_grandchild.soonest_start).to be_nil }
          end

          context 'with the parent manually scheduled' do
            let(:successor_child_schedule_manually) { true }

            it { expect(successor_grandchild.soonest_start).to be_nil }
          end
        end

        context 'no start date exists in related work packages' do
          it { expect(successor_grandchild.soonest_start).to be_nil }
        end
      end
    end
  end
end
