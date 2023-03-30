/**
 * Shape of the param arg for the `getAssets` function.
 */
export type GetAssetsParams = {
  /**
   * The number of photos/videos you want to fetch
   */
  limit?: number;

  /**
   * The number of photos/videos you want to fetch
   */
  sortBy?: { key: string; asc: boolean }[];
};
