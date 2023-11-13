import { CameraRoll } from './CameraRoll';

export * from './CameraRoll';
export * from './types';

export { useGalleryCleaner } from './hooks/useGalleryCleaner';
export {
  GalleryCleanerProvider,
  GalleryFetchStatus,
  GalleryCleanerAlbum,
  GalleryAssetsGroup,
} from './contexts/GalleryCleanerContext';

export const fetchAssets = CameraRoll.getAssets;
export const fetchAssetsCount = CameraRoll.getAssetsCount;
export const editIsFavorite = CameraRoll.editIsFavorite;
export const deleteAssets = CameraRoll.deleteAssets;
