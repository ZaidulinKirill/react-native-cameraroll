/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Platform } from 'react-native';

import {
  RNCameraroll,
  RNSimilarImageDetector,
  RNBlurryImageDetector,
} from './CameraRollNative';
import type { GalleryAsset, GetAssetsParams, VideoInfo } from './types';
import { buildResultAsset } from './utils/buildResultAsset';

/**
 * `CameraRoll` provides access to the local camera roll or photo library.
 */
export class CameraRoll {
  /**
   * Fetch assets from your local gallery
   */
  static async getAssets(params: GetAssetsParams): Promise<GalleryAsset[]> {
    const { items } = await RNCameraroll.getAssets(
      Platform.select({
        ios: {
          ...params,
          select: params.select,
          collectionType: (() => {
            if (params.collectionType === 'album') {
              return 1;
            }

            if (params.collectionType === 'smartAlbum') {
              return 2;
            }

            return undefined;
          })(),
          collectionSubType: (() => {
            if (params.collectionSubType === 'selfies') {
              return 210;
            }

            if (params.collectionSubType === 'screenshots') {
              return 211;
            }

            if (params.collectionSubType === 'livePhotos') {
              return 213;
            }

            if (params.collectionSubType === 'videos') {
              return 202;
            }

            return undefined;
          })(),
        },
        android: {
          ...params,
          sortBy: params.sortBy?.map((x) => {
            const key = (() => {
              if (x.key === 'createdAt') {
                return 'date_added';
              } else if (x.key === 'modificationDate') {
                return 'date_modified';
              } else if (x.key === 'fileSize') {
                return '_size';
              } else if (x.key === 'mediaType') {
                return 'media_type';
              }

              return x.key;
            })();

            return { key, asc: x.asc };
          }),
        },
      }),
    );

    return items.map(buildResultAsset);
  }

  /**
   * Find similar images
   */
  static async findSimilarImages(interval = 15): Promise<GalleryAsset[][]> {
    const groups = await RNSimilarImageDetector.findSimilarImagesFromGallery(
      interval,
    );

    return groups.map((items: any[]) => items.map(buildResultAsset));
  }

  /**
   * Find blurry images
   */
  static async findBlurryImages({
    ignoreIds = [],
    threshold = 5,
    itemsPerPage = 500,
    onFinished,
  }: {
    ignoreIds?: string[];
    threshold?: number;
    itemsPerPage?: number;
    onFinished?: (processedIds: string[]) => void;
  } = {}): Promise<GalleryAsset[]> {
    const { items, processedIds } =
      await RNBlurryImageDetector.findBlurryImagesFromGallery(
        ignoreIds,
        threshold,
        itemsPerPage,
      );

    onFinished?.(processedIds);

    return items.map(buildResultAsset);
  }

  /**
   * Fetch assets from your local gallery
   */
  static async getAssetsCount(
    params: Omit<GetAssetsParams, 'skip' | 'limit' | 'sortBy' | 'select'>,
  ): Promise<{ total: number }> {
    const result = await RNCameraroll.getAssets({ ...params, totalOnly: true });

    return result;
  }

  /**
   * Edit isFavorite value
   */
  static async editIsFavorite(
    id: string,
    value: boolean,
  ): Promise<{ success: boolean }> {
    return RNCameraroll.editIsFavorite(id, value);
  }

  /**
   * Delete gallery assets
   */
  static deleteAssets(ids: string[]): Promise<{ success: boolean }> {
    return RNCameraroll.deleteAssets(ids);
  }

  /**
   * Get video asset details
   */
  static async getAssetVideoInfo(id: string): Promise<VideoInfo | null> {
    return RNCameraroll.getAssetVideoInfo(id);
  }

  /**
   * Save assets to Camera Roll
   */
  static saveAssets(files: string[]) {
    return RNCameraroll.saveAssets(files);
  }

  /**
   * Save asset thumbnail to the file
   */
  static saveThumbnail(
    id: string,
    filename: string,
    width: number,
    height: number,
  ) {
    return RNCameraroll.saveThumbnail(id, filename, width, height);
  }
}
