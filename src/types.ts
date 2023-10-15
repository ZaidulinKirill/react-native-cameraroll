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
   * Collection type
   */
  collectionType?: 'album' | 'smartAlbum';

  /**
   * Collection subtype
   */
  collectionSubType?: 'selfies' | 'screenshots' | 'livePhotos' | 'videos';

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

export type GalleryAsset = {
  id?: string;
  name?: string;
  mediaType?: 'unknown' | 'video' | 'image';
  size?: number;
  creationDate?: Date;
  uri?: string;
  isFavorite?: boolean;
};

/**
 * Video asset details
 */
export type VideoInfo = {
  bitrate: number;
  width: number;
  height: number;
};
