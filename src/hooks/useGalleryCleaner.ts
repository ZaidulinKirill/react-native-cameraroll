import { useContext } from 'react';

import { GalleryCleanerContext } from '../contexts/GalleryCleanerContext';

export function useGalleryCleaner() {
  return useContext(GalleryCleanerContext);
}
