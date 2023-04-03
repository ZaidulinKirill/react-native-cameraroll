export type SortByKey =
  | 'creationDate'
  | 'modificationDate'
  | 'mediaType'
  | 'fileSize';

export type SelectKey =
  | 'id'
  | 'name'
  | 'mediaType'
  | 'size'
  | 'creationDate'
  | 'uri'
  | 'isFavorite';

/**
 * Fetching params
 */
export type GetAssetsParams = {
  /**
   * Media type
   */
  mediaType?: 'image' | 'video' | 'all';

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
    mediaType?: 'unknown' | 'video' | 'image';
    size?: number;
    creationDate?: Date;
    uri?: string;
    isFavorite?: boolean;
  }[];
};
