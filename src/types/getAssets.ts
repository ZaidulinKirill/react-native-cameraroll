export type SortByKey =
  | 'creationDate'
  | 'modificationDate'
  | 'duration'
  | 'mediaType'
  | 'favorite'
  | 'hidden'
  | 'fileSize';

export type SelectKey = 'id' | 'name' | 'type' | 'size' | 'extension' | 'uri';

/**
 * Fetching params
 */
export type GetAssetsParams = {
  /**
   * Number of photos/videos you want to skip
   */
  skip?: number;

  /**
   * Number of photos/videos you want to fetch
   */
  limit?: number;

  /**
   * Sort order of the result
   */
  sortBy?: { key: SortByKey; asc: boolean }[];

  /**
   * Selection set for every item
   */
  select?: SelectKey[];
};

/**
 * Result of getAssets method
 */
export type GetAssetsResult = {
  /**
   * Number of photos/videos you want to skip
   */
  items: {
    id?: string;
    name?: string;
    type?: 'unknown' | 'video' | 'image';
    size?: number;
    extension?: string;
  }[];

  /**
   * Number of total items
   */
  total: number;
};
