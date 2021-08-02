import {
  ChangeDetectionStrategy, Component, NgZone, OnInit,
} from '@angular/core';
import { WorkPackageListViewComponent } from 'core-app/features/work-packages/routing/wp-list-view/wp-list-view.component';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import {
  bimSplitViewCardsIdentifier,
  bimSplitViewListIdentifier,
  BimViewService,
} from 'core-app/features/bim/ifc_models/pages/viewer/bim-view.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { UIRouterGlobals } from '@uirouter/core';
import { distinctUntilChanged, pluck } from 'rxjs/operators';
import { States } from 'core-app/core/states/states.service';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { splitViewRoute } from 'core-app/features/work-packages/routing/split-view-routes.helper';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';

@Component({
  templateUrl: './bcf-list-container.component.html',
  styleUrls: ['./bcf-list-container.component.sass'],
  providers: [
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    DragAndDropService,
    CausedUpdatesService,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BcfListContainerComponent extends WorkPackageListViewComponent implements OnInit {
  @InjectField() bimView:BimViewService;

  @InjectField() ifcModelsService:IfcModelsDataService;

  @InjectField() wpTableColumns:WorkPackageViewColumnsService;

  @InjectField() uIRouterGlobals:UIRouterGlobals;

  @InjectField() viewer:ViewerBridgeService;

  @InjectField() states:States;

  @InjectField() bcfApi:BcfApiService;

  @InjectField() zone:NgZone;

  public wpTableConfiguration = {
    dragAndDropEnabled: false,
  };

  public showViewPointInFlight:boolean;

  ngOnInit() {
    super.ngOnInit();

    // Ensure we add a bcf thumbnail column
    // until we can load the initial query
    this.wpTableColumns
      .onReady()
      .then(() => this.wpTableColumns.addColumn('bcfThumbnail', 2));

    this.uIRouterGlobals
      .params$!
      .pipe(
        this.untilDestroyed(),
        pluck('cards'),
        distinctUntilChanged(),
      )
      .subscribe((cards:boolean) => {
        if (cards == null || cards || this.deviceService.isMobile) {
          this.showTableView = false;
        } else {
          this.showTableView = true;
        }

        this.cdRef.detectChanges();
      });
  }

  protected updateViewRepresentation(query:QueryResource) {
    // Overwrite the parent method because we are setting the view
    // above through the cards parameter (showTableView)
  }

  public showResizerInCardView():boolean {
    if (this.noResults && this.ifcModelsService.models.length === 0) {
      return false;
    }
    return this.bimView.currentViewerState() === bimSplitViewCardsIdentifier
             || this.bimView.currentViewerState() === bimSplitViewListIdentifier;
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }) {
    const { workPackageId, double } = event;

    if (!this.showViewPointInFlight) {
      this.showViewPointInFlight = true;

      this.zone.runOutsideAngular(() => {
        setTimeout(() => this.showViewPointInFlight = false, 500);
      });

      const wp = this.states.workPackages.get(workPackageId).value;

      if (wp && this.viewer.viewerVisible() && wp.bcfViewpoints) {
        this.viewer.showViewpoint(wp, 0);
      }
    }

    if (double) {
      this.goToWpDetailState(workPackageId, this.uIRouterGlobals.params.cards);
    }
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }) {
    this.goToWpDetailState(event.workPackageId, this.uIRouterGlobals.params.cards, true);
  }

  goToWpDetailState(workPackageId:string, cards:boolean, focus?:boolean) {
    // Show the split view when there is a viewer (browser)
    // Show only wp details when there is no viewer, plugin environment (ie: Revit)
    const stateToGo = this.viewer.shouldShowViewer
      ? splitViewRoute(this.$state)
      : 'bim.partitioned.show';
    // Passing the card param to the new state because the router doesn't keep
    // it when going to 'bim.partitioned.show'
    const params = { workPackageId, cards, focus };

    this.$state.go(stateToGo, params);
  }
}
