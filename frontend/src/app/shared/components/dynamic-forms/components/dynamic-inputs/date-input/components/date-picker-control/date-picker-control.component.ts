import {
  AfterViewInit, ChangeDetectorRef, Component, forwardRef, Input, NgZone,
} from '@angular/core';
import * as moment from 'moment';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { OpDatePickerComponent } from 'core-app/shared/components/op-date-picker/op-date-picker.component';

@Component({
  selector: 'op-date-picker-control',
  templateUrl: '../../../../../../op-date-picker/op-date-picker.component.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => DatePickerControlComponent),
      multi: true,
    },
  ],
})
export class DatePickerControlComponent extends OpDatePickerComponent implements ControlValueAccessor, AfterViewInit {
  // Avoid Angular warning (It looks like you're using the disabled attribute with a reactive form directive...)
  @Input('disable') disabled:boolean;

  onControlChange = (_:any) => { };

  onControlTouch = () => { };

  constructor(
    timezoneService:TimezoneService,
    private ngZone:NgZone,
    private changeDetectorRef:ChangeDetectorRef,
  ) {
    super(timezoneService);
  }

  writeValue(date:string):void {
    this.initialDate = this.formatter(date);
  }

  registerOnChange(fn:(_:any) => void):void {
    this.onControlChange = fn;
  }

  registerOnTouched(fn:any):void {
    this.onControlTouch = fn;
  }

  setDisabledState(disabled:boolean):void {
    this.disabled = disabled;
  }

  ngAfterViewInit():void {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        this.initializeDatepicker();
        this.changeDetectorRef.detectChanges();
      });
    });
  }

  onInputChange(_event:KeyboardEvent) {
    const valueToEmit = this.inputIsValidDate()
      ? this.parser(this.currentValue)
      : '';

    this.onControlChange(valueToEmit);
    this.onControlTouch();
  }

  closeOnOutsideClick(event:any) {
    super.closeOnOutsideClick(event);
    this.onControlTouch();
  }

  public parser(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    }
    return null;
  }

  public formatter(data:any):string {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      const d = this.timezoneService.parseDate(data);

      return this.timezoneService.formattedISODate(d);
    }
    return '';
  }
}
