import { Component, input } from '@angular/core';
import { CaesarStep } from '../../models/cipher.models';

@Component({
  selector: 'app-caesar-table',
  standalone: true,
  templateUrl: './caesar-table.component.html',
})
export class CaesarTableComponent {
  readonly stepNumber = input.required<number>();
  readonly shift = input.required<number>();
  readonly isEncrypt = input.required<boolean>();
  readonly steps = input.required<CaesarStep[]>();
  readonly outputText = input<string | null>(null);

  displayChar(ch: string): string {
    return ch === ' ' ? '␠' : ch;
  }
}
