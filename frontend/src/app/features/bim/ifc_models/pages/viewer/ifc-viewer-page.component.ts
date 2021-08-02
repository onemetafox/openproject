import {
  ChangeDetectionStrategy, Component, Injector, ViewEncapsulation,
} from '@angular/core';
import { GonService } from 'core-app/core/gon/gon.service';
import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import { WorkPackageFilterButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import { ZenModeButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {
  bimListViewIdentifier,
  bimViewerViewIdentifier,
  BimViewService,
} from 'core-app/features/bim/ifc_models/pages/viewer/bim-view.service';
import { BimViewToggleButtonComponent } from 'core-app/features/bim/ifc_models/toolbar/view-toggle/bim-view-toggle-button.component';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { QueryParamListenerService } from 'core-app/features/work-packages/components/wp-query/query-param-listener.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { BimManageIfcModelsButtonComponent } from 'core-app/features/bim/ifc_models/toolbar/manage-ifc-models-button/bim-manage-ifc-models-button.component';
import { WorkPackageCreateButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-create-button/wp-create-button.component';
import { StateService, TransitionService } from '@uirouter/core';
import { BehaviorSubject } from 'rxjs';
import { BcfImportButtonComponent } from 'core-app/features/bim/ifc_models/toolbar/import-export-bcf/bcf-import-button.component';
import { BcfExportButtonComponent } from 'core-app/features/bim/ifc_models/toolbar/import-export-bcf/bcf-export-button.component';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';

@Component({
  templateUrl: '../../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
    './styles/generic.sass',
  ],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    QueryParamListenerService,
  ],
})
export class IFCViewerPageComponent extends PartitionedQuerySpacePageComponent {
  text = {
    title: this.I18n.t('js.bcf.management'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
  };

  newRoute$ = new BehaviorSubject<string | undefined>(undefined);

  transitionUnsubscribeFn:Function;

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageCreateButtonComponent,
      inputs: {
        stateName$: this.newRoute$,
        allowed: ['work_packages.createWorkPackage', 'work_package.copy'],
      },
    },
    {
      component: BcfImportButtonComponent,
      show: () => this.ifcData.allowed('manage_bcf'),
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: BcfExportButtonComponent,
      show: () => this.ifcData.allowed('manage_bcf'),
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: WorkPackageFilterButtonComponent,
      show: () => this.bimView.currentViewerState() !== bimViewerViewIdentifier,
    },
    {
      component: BimViewToggleButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-mobile',
    },
    {
      component: BimManageIfcModelsButtonComponent,
      show: () =>
        // Hide 'Manage models' toolbar button on plugin environment (ie: Revit)
        this.viewerBridgeService.shouldShowViewer
               && this.ifcData.allowed('manage_ifc_models'),

    },
  ];

  get newRoute() {
    // Open new work packages in full view when there
    // is no viewer (ie: Revit)
    return this.viewerBridgeService.shouldShowViewer
      ? this.state.current.data.newRoute
      : 'bim.partitioned.new';
  }

  constructor(readonly ifcData:IfcModelsDataService,
    readonly state:StateService,
    readonly bimView:BimViewService,
    readonly transition:TransitionService,
    readonly gon:GonService,
    readonly injector:Injector,
    readonly viewerBridgeService:ViewerBridgeService) {
    super(injector);
  }

  ngOnInit() {
    super.ngOnInit();
    this.newRoute$.next(this.newRoute);

    this
      .bimView
      .observeUntil(componentDestroyed(this))
      .subscribe((view) => {
        this.filterAllowed = view !== bimViewerViewIdentifier;
      });

    // Keep the new route up to date depending on where we move to
    this.transitionUnsubscribeFn = this.transition.onSuccess({}, () => {
      this.newRoute$.next(this.newRoute);
    });
  }

  /**
   * We disable using the query title for now,
   * but this might be useful later.
   *
   * To re-enable query titles, remove this function.
   *
   * @param query
   */
  updateTitle(query?:QueryResource) {
    if (this.bimView.current === bimListViewIdentifier) {
      super.updateTitle(query);
    } else {
      this.selectedTitle = this.I18n.t('js.bcf.management');
    }

    // For now, disable any editing
    this.titleEditingEnabled = false;
  }
}
