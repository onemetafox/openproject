import { Injectable, Injector } from '@angular/core';
import { BcfViewpointInterface } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.interface';
import { Observable } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { StateService } from '@uirouter/core';

@Injectable()
export abstract class ViewerBridgeService {
  @InjectField() state:StateService;

  /**
   * Determine whether a viewer should be shown,
   * wether 'bim.partitioned.split' state/route should be activated
   */
  abstract shouldShowViewer:boolean;

  /**
   * Check if we are on a router state where there is a place
   * where the viewer could be shown
   */
  get routeWithViewer():boolean {
    return this.state.includes('bim.partitioned.split');
  }

  constructor(readonly injector:Injector) {}

  /**
   * Get a viewpoint from the viewer
   */
  abstract getViewpoint$():Observable<BcfViewpointInterface>;

  /**
   * Show the given viewpoint JSON in the viewer
   * @param viewpoint
   */
  abstract showViewpoint(workPackage:WorkPackageResource, index:number):void;

  /**
   * Determine whether a viewer is present to ensure we can show viewpoints
   */
  abstract viewerVisible():boolean;

  /**
   * Fires when viewer becomes visible.
   */
  abstract viewerVisible$:Observable<boolean>;
}
