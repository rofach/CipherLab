import { Injectable } from '@angular/core';

interface RuntimeConfig {
  apiBaseUrl?: string;
}

@Injectable({
  providedIn: 'root',
})
export class AppConfigService {
  private baseUrl = '';

  get apiBaseUrl(): string {
    return this.baseUrl;
  }

  async load(): Promise<void> {
    try {
      const response = await fetch('/config.json', { cache: 'no-store' });
      if (!response.ok) {
        return;
      }
      const config = (await response.json()) as RuntimeConfig;
      this.baseUrl = (config.apiBaseUrl ?? '').replace(/\/+$/, '');
    } catch {
      this.baseUrl = '';
    }
  }
}
