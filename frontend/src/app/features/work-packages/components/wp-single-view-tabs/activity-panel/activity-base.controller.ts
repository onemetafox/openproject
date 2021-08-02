// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ChangeDetectorRef, Directive, OnInit } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ActivityEntryInfo } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/activity-entry-info';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { Transition } from '@uirouter/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';

@Directive()
export class ActivityPanelBaseController extends UntilDestroyedMixin implements OnInit {
  public workPackage:WorkPackageResource;

  public workPackageId:string;

  // All activities retrieved for the work package
  public unfilteredActivities:HalResource[] = [];

  // Visible activities
  public visibleActivities:ActivityEntryInfo[] = [];

  public reverse:boolean;

  public showToggler:boolean;

  public onlyComments = false;

  public togglerText:string;

  public text = {
    commentsOnly: this.I18n.t('js.label_activity_show_only_comments'),
    showAll: this.I18n.t('js.label_activity_show_all'),
  };

  constructor(readonly apiV3Service:APIV3Service,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    readonly $transition:Transition,
    readonly wpActivity:WorkPackagesActivityService) {
    super();

    this.reverse = wpActivity.isReversed;
    this.togglerText = this.text.commentsOnly;
  }

  ngOnInit() {
    this
      .apiV3Service
      .work_packages
      .id(this.workPackageId)
      .requireAndStream()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;
        this.wpActivity.require(this.workPackage).then((activities:any) => {
          this.updateActivities(activities);
          this.cdRef.detectChanges();
        });
      });
  }

  protected updateActivities(activities:HalResource[]) {
    this.unfilteredActivities = activities;

    const visible = this.getVisibleActivities();
    this.visibleActivities = visible.map((el:HalResource, i:number) => this.info(el, i));
    this.showToggler = this.shouldShowToggler();
  }

  protected shouldShowToggler() {
    const count_all = this.unfilteredActivities.length;
    const count_with_comments = this.getActivitiesWithComments().length;

    return count_all > 1
      && count_with_comments > 0
      && count_with_comments < this.unfilteredActivities.length;
  }

  protected getVisibleActivities() {
    if (!this.onlyComments) {
      return this.unfilteredActivities;
    }
    return this.getActivitiesWithComments();
  }

  protected getActivitiesWithComments() {
    return this.unfilteredActivities
      .filter((activity:HalResource) => !!_.get(activity, 'comment.html'));
  }

  public toggleComments() {
    this.onlyComments = !this.onlyComments;
    this.updateActivities(this.unfilteredActivities);

    if (this.onlyComments) {
      this.togglerText = this.text.showAll;
    } else {
      this.togglerText = this.text.commentsOnly;
    }
  }

  public info(activity:HalResource, index:number) {
    return this.wpActivity.info(this.unfilteredActivities, activity, index);
  }
}
