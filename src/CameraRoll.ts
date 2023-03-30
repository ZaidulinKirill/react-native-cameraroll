/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
// import { Platform } from 'react-native';
import { RNCameraroll } from './CameraRollNative';
import type { GetAssetsParams } from './types';

/**
 * `CameraRoll` provides access to the local camera roll or photo library.
 */
export class CameraRoll {
  /**
   * Returns a Promise with photo identifier objects from the local camera
   * roll of the device matching shape defined by `getPhotosReturnChecker`.
   */
  static getAssets(params: GetAssetsParams): Promise<any> {
    return RNCameraroll.getAssets(params);
  }
}
