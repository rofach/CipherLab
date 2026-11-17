import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { CipherRequest, CipherResponse } from '../models/cipher.models';
import { AppConfigService } from './app-config.service';

@Injectable({
  providedIn: 'root',
})
export class CipherService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(AppConfigService);

  process(request: CipherRequest): Observable<CipherResponse> {
    const endpoint = `${this.config.apiBaseUrl}/api/cipher/process`;
    return this.http.post<CipherResponse>(endpoint, request);
  }
}
