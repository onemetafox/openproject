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

import { HttpErrorResponse } from '@angular/common/http';
import {
  AfterViewInit, Component, ElementRef, Injector, ViewChild,
} from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { JobStatusModalComponent } from 'core-app/features/job-status/job-status-modal/job-status.modal';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpenProjectBackupService } from 'core-app/core/backup/op-backup.service';

export const backupSelector = 'backup';

@Component({
  selector: backupSelector,
  templateUrl: './backup.component.html',
})
export class BackupComponent implements AfterViewInit {
  public text = {
    info: this.i18n.t('js.backup.info'),
    note: this.i18n.t('js.backup.note'),
    title: this.i18n.t('js.backup.title'),
    lastBackup: this.i18n.t('js.backup.last_backup'),
    lastBackupFrom: this.i18n.t('js.backup.last_backup_from'),
    includeAttachments: this.i18n.t('js.backup.include_attachments'),
    options: this.i18n.t('js.backup.options'),
    downloadBackup: this.i18n.t('js.backup.download_backup'),
    requestBackup: this.i18n.t('js.backup.request_backup'),
    attachmentsDisabled: this.i18n.t('js.backup.attachments_disabled'),
  };

  public jobStatusId:string = this.elementRef.nativeElement.dataset.jobStatusId;

  public lastBackupDate:string = this.elementRef.nativeElement.dataset.lastBackupDate;

  public lastBackupAttachmentId:string = this.elementRef.nativeElement.dataset.lastBackupAttachmentId;

  public mayIncludeAttachments:boolean = this.elementRef.nativeElement.dataset.mayIncludeAttachments != 'false';

  public isInProgress = false;

  public includeAttachments = true;

  public backupToken = '';

  @InjectField() opBackup:OpenProjectBackupService;

  @ViewChild('backupTokenInput') backupTokenInput:ElementRef;

  constructor(
    readonly elementRef:ElementRef,
    public injector:Injector,
    protected i18n:I18nService,
    protected notificationsService:NotificationsService,
    protected opModalService:OpModalService,
    protected pathHelper:PathHelperService,
  ) {
    this.includeAttachments = this.mayIncludeAttachments;
  }

  ngAfterViewInit() {
    this.backupTokenInput.nativeElement.focus();
  }

  public isDownloadReady():boolean {
    return this.jobStatusId !== undefined && this.jobStatusId !== ''
      && this.lastBackupAttachmentId !== undefined && this.lastBackupAttachmentId !== '';
  }

  public getDownloadUrl():string {
    return this.pathHelper.attachmentDownloadPath(this.lastBackupAttachmentId, undefined);
  }

  public includeAttachmentsDefault():boolean {
    return this.mayIncludeAttachments;
  }

  public includeAttachmentsTitle():string {
    return this.mayIncludeAttachments ? '' : this.text.attachmentsDisabled;
  }

  public triggerBackup(event?:JQuery.TriggeredEvent) {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }

    const { backupToken } = this;

    this.backupToken = '';

    this.opBackup
      .triggerBackup(backupToken, this.includeAttachments)
      .toPromise()
      .then((resp:any) => {
        this.jobStatusId = resp.jobStatusId;
        this.opModalService.show(JobStatusModalComponent, 'global', { jobId: resp.jobStatusId });
      })
      .catch((error:HttpErrorResponse) => {
        this.notificationsService.addError(error.error);
      });
  }
}
