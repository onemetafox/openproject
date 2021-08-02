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

import { Injectable } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { Subject } from 'rxjs';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Injectable()
export class CommentService {
  // Replacement for ng1 $scope.$emit on activty-entry to mark comments to be quoted.
  // Should be generalized if needed for more than that.
  public quoteEvents = new Subject<string>();

  constructor(
    readonly I18n:I18nService,
    private workPackageNotificationService:WorkPackageNotificationService,
    private NotificationsService:NotificationsService,
  ) {
  }

  public createComment(workPackage:WorkPackageResource, comment:{ raw:string }) {
    return workPackage.addComment(
      { comment },
      { 'Content-Type': 'application/json; charset=UTF-8' },
    )
      .catch((error:any) => this.errorAndReject(error, workPackage));
  }

  public updateComment(activity:HalResource, comment:string) {
    const options = {
      ajax: {
        method: 'PATCH',
        data: JSON.stringify({ comment }),
        contentType: 'application/json; charset=utf-8',
      },
    };

    return activity.update(
      { comment },
      { 'Content-Type': 'application/json; charset=UTF-8' },
    ).then((activity:HalResource) => {
      this.NotificationsService.addSuccess(
        this.I18n.t('js.work_packages.comment_updated'),
      );

      return activity;
    }).catch((error:any) => this.errorAndReject(error));
  }

  private errorAndReject(error:HalResource, workPackage?:WorkPackageResource) {
    this.workPackageNotificationService.handleRawError(error, workPackage);

    // returning a reject will enable to correctly work with subsequent then/catch handlers.
    return Promise.reject(error);
  }
}
