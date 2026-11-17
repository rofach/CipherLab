import { Component, inject, signal } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  ReactiveFormsModule,
  ValidationErrors,
  Validators,
} from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { CipherService } from './services/cipher.service';
import { CipherOperation, CipherResponse } from './models/cipher.models';
import { CaesarTableComponent } from './components/caesar-table/caesar-table.component';

function integerValidator(control: AbstractControl): ValidationErrors | null {
  const raw = control.value;
  if (raw === null || raw === undefined || raw === '') {
    return { integer: true };
  }
  return Number.isInteger(Number(raw)) ? null : { integer: true };
}

function decryptMinLengthValidator(group: AbstractControl): ValidationErrors | null {
  const op = group.get('operation')?.value as CipherOperation | undefined;
  const text = String(group.get('text')?.value ?? '');
  if (op === 'Decrypt' && text.length > 0 && text.length < 2) {
    return { decryptMinLength: true };
  }
  return null;
}

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [ReactiveFormsModule, CaesarTableComponent],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  private readonly fb = inject(FormBuilder);
  private readonly cipherService = inject(CipherService);

  readonly form = this.fb.nonNullable.group(
    {
      text: ['Привіт, Світ! 2026', [Validators.required, Validators.minLength(1)]],
      operation: ['Encrypt' as CipherOperation, [Validators.required]],
      shift: [3, [Validators.required, integerValidator]],
      rails: [3, [Validators.required, integerValidator, Validators.min(2), Validators.max(100)]],
    },
    { validators: decryptMinLengthValidator },
  );

  readonly isLoading = signal(false);
  readonly apiError = signal<string | null>(null);
  readonly response = signal<CipherResponse | null>(null);
  readonly copied = signal(false);

  setOperation(op: CipherOperation): void {
    this.form.controls.operation.setValue(op);
    this.apiError.set(null);
  }

  onSubmit(): void {
    this.apiError.set(null);
    this.copied.set(false);

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const raw = this.form.getRawValue();
    this.isLoading.set(true);

    this.cipherService
      .process({
        text: raw.text,
        operation: raw.operation,
        shift: Number(raw.shift),
        rails: Number(raw.rails),
      })
      .subscribe({
        next: (res) => {
          this.isLoading.set(false);
          this.response.set(res);
        },
        error: (err: HttpErrorResponse) => {
          this.isLoading.set(false);
          const serverMsg =
            err.error?.title ||
            err.error?.detail ||
            (err.error?.errors
              ? Object.values(err.error.errors).flat().join(' ')
              : null);
          this.apiError.set(
            serverMsg ||
              'Не вдалося звернутися до сервера. Перевірте, чи запущено ASP.NET Core API.',
          );
        },
      });
  }

  copyResult(): void {
    const res = this.response();
    if (!res) {
      return;
    }
    navigator.clipboard?.writeText(res.resultText);
    this.copied.set(true);
    setTimeout(() => this.copied.set(false), 1800);
  }

  hasError(controlName: 'text' | 'shift' | 'rails'): boolean {
    const ctrl = this.form.controls[controlName];
    if (controlName === 'text' && this.hasDecryptLengthError()) {
      return true;
    }
    return ctrl.invalid && (ctrl.dirty || ctrl.touched);
  }

  hasDecryptLengthError(): boolean {
    const ctrl = this.form.controls.text;
    return this.form.hasError('decryptMinLength') && (ctrl.dirty || ctrl.touched);
  }
}
