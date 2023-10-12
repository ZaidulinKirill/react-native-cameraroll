/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Platform } from 'react-native';

import { RNCameraroll } from './CameraRollNative';
import type { GetAssetsParams, GetAssetsResult } from './types';

/**
 * `CameraRoll` provides access to the local camera roll or photo library.
 */
export class CameraRoll {
  /**
   * Fetch assets from your local gallery
   */
  static async getAssets(params: GetAssetsParams): Promise<GetAssetsResult> {
    const result = await RNCameraroll.getAssets(
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
              if (x.key === 'creationDate') {
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

    return {
      ...result,
      items: result.items.map((item: any) => {
        if (Platform.OS === 'ios') {
          return {
            ...(params?.select?.includes('id') && item.id && { id: item.id }),
            ...(params?.select?.includes('uri') &&
              item.id && { uri: `ph://${item.id}` }),
            ...(params?.select?.includes('name') &&
              item.name && { name: item.name }),
            ...(params?.select?.includes('mediaType') &&
              (item.mediaType || item.mediaType === 0) && {
                type:
                  item.mediaType === 1
                    ? 'image'
                    : item.mediaType === 2
                    ? 'video'
                    : 'unknown',
              }),
            ...(params?.select?.includes('size') &&
              (item.size || item.size === 0) && { size: item.size }),
            ...(params?.select?.includes('creationDate') &&
              item.creationDate !== -1 && {
                creationDate: new Date(item.creationDate * 1000),
              }),
            ...(params?.select?.includes('uri') && {
              uri: item.uri,
            }),
            ...(params?.select?.includes('isFavorite') && {
              isFavorite: item.isFavorite,
            }),
          };
        }

        if (Platform.OS === 'android') {
          return {
            ...(item.id && { id: item.id }),
            ...(item.name && { name: item.name }),
            ...(item.uri && { uri: item.uri }),
            ...(item.size && { size: item.size }),
            ...(item.isFavorite && { isFavorite: item.isFavorite === '1' }),
            ...(item.mediaType && {
              mediaType:
                item.mediaType === 1
                  ? 'image'
                  : item.mediaType === 3
                  ? 'video'
                  : 'unknown',
            }),
            ...(item.creationDate && {
              creationDate: new Date(parseInt(item.creationDate, 10) * 1000),
            }),
          };
        }

        throw new Error('Not implemented');
      }),
    };
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
}
