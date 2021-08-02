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

@Injectable({ providedIn: 'root' })
export class FocusHelperService {
  private minimumOffsetForNewSwitchInMs = 100;

  private lastFocusSwitch = -this.minimumOffsetForNewSwitchInMs;

  private lastPriority = -1;

  private static FOCUSABLE_SELECTORS = 'a, button, :input, [tabindex], select';

  public throttleAndCheckIfAllowedFocusChangeBasedOnTimeout() {
    const allowFocusSwitch = (Date.now() - this.lastFocusSwitch) >= this.minimumOffsetForNewSwitchInMs;

    // Always update so that a chain of focus-change-requests gets considered as one
    this.lastFocusSwitch = Date.now();

    return allowFocusSwitch;
  }

  public checkIfAllowedFocusChange(priority?:any) {
    const checkTimeout = this.throttleAndCheckIfAllowedFocusChangeBasedOnTimeout();

    if (checkTimeout) {
      // new timeout window -> reset priority
      this.lastPriority = -1;
      return checkTimeout;
    }

    if (priority > this.lastPriority) {
      // within timeout window
      this.lastPriority = priority;
      return true;
    }

    return checkTimeout;
  }

  public getFocusableElement(element:JQuery) {
    const focusser = element.find('input.ui-select-focusser');

    if (focusser.length > 0) {
      return focusser[0];
    }

    let focusable = element;

    if (!element.is(FocusHelperService.FOCUSABLE_SELECTORS)) {
      focusable = element.find(FocusHelperService.FOCUSABLE_SELECTORS);
    }

    return focusable[0];
  }

  public focus(element:JQuery) {
    const focusable = jQuery(this.getFocusableElement(element));
    const $focusable = jQuery(focusable);
    const isDisabled = $focusable.is('[disabled]');

    if (isDisabled && !$focusable.attr('ng-disabled')) {
      $focusable.prop('disabled', false);
    }

    focusable.focus();

    if (isDisabled && !$focusable.attr('ng-disabled')) {
      $focusable.prop('disabled', true);
    }
  }

  public focusElement(element:JQuery, priority?:any) {
    if (!this.checkIfAllowedFocusChange(priority)) {
      return;
    }

    setTimeout(() => {
      this.focus(element);
    }, 10);
  }
}
