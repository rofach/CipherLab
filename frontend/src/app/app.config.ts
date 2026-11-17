import {
  ApplicationConfig,
  inject,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
} from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { AppConfigService } from './services/app-config.service';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(),
    provideAppInitializer(() => inject(AppConfigService).load()),
  ],
};
