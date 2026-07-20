/**
 * Settings API — local browser persistence for admin settings.
 */
const SETTINGS_STORAGE_KEY = 'handygo_platform_settings';

export const settingsApi = {
  /**
   * Load all settings sections. Returns the 4 sections or defaults.
   */
  getSettings: async (): Promise<{
    general: Record<string, unknown>;
    notifications: Record<string, unknown>;
    platform: Record<string, unknown>;
    security: Record<string, unknown>;
  }> => {
    const stored = localStorage.getItem(SETTINGS_STORAGE_KEY);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch {
        // Ignore malformed local data
      }
    }

    return { general: {}, notifications: {}, platform: {}, security: {} };
  },

  /**
   * Save a specific section of settings.
   */
  saveSettings: async (
    section: 'general' | 'notifications' | 'platform' | 'security',
    data: Record<string, unknown>,
  ): Promise<void> => {
    const stored = localStorage.getItem(SETTINGS_STORAGE_KEY);
    let all: Record<string, unknown> = {};
    try {
      all = stored ? JSON.parse(stored) : {};
    } catch {
      all = {};
    }

    all[section] = data;
    localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(all));
  },
};
