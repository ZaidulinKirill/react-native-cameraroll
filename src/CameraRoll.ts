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
   * Returns a Promise with photo identifier objects from the local camera
   * roll of the device matching shape defined by `getPhotosReturnChecker`.
   */
  static async getAssets(params: GetAssetsParams): Promise<GetAssetsResult> {
    // "uri": asset.mediaType != .video ? "ph://\(asset.localIdentifier)" : "",

    const result = await RNCameraroll.getAssets(
      Platform.select({
        ios: {
          ...params,
          select: params.select
            ?.map((x) => {
              if (x === 'extension') {
                return 'ext';
              }

              return x;
            })
            .filter((x) => !['uri'].includes(x)),
        },
        android: { ...params },
      })
    );

    return {
      ...result,
      items: result.items.map((item: any) => {
        if (Platform.OS === 'ios') {
          return {
            ...(params?.select?.includes('id') && item.id && { id: item.id }),
            ...(params?.select?.includes('name') &&
              item.name && { name: item.name }),
            ...(params?.select?.includes('size') &&
              (item.size || item.size === 0) && { size: item.size }),
            ...(params?.select?.includes('type') &&
              (item.type || item.type === 0) && {
                type:
                  item.type === 1
                    ? 'image'
                    : item.type === 2
                    ? 'video'
                    : 'unknown',
              }),
            ...(params?.select?.includes('extension') &&
              item.ext && { extension: item.ext.toLowerCase() }),
            ...(params?.select?.includes('uri') && {
              uri: `ph://${item.id}`,
            }),
          };
        }

        if (Platform.OS === 'android') {
          return {
            ...(item.id && { id: item.id }),
            ...(item.name && { name: item.name }),
            ...((item.size || item.size === 0) && { size: item.size }),
            ...(item.ext && { extension: item.ext }),
          };
        }

        throw new Error('Not implemented');
      }),
    };
  }
}
