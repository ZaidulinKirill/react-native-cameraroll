import {
  useAlert,
  useAppActivityEffect,
  usePermissions,
} from '@kirz/react-native-toolkit';
import AsyncStorage from '@react-native-async-storage/async-storage';
import React, {
  PropsWithChildren,
  createContext,
  useCallback,
  useMemo,
  useRef,
  useState,
} from 'react';
import { Platform } from 'react-native';

import { CameraRoll } from '../CameraRoll';
import { GalleryAsset } from '../types';

export type GalleryFetchStatus =
  | 'unknown'
  | 'error'
  | 'fetching'
  | 'fetched'
  | 'blocked';

export type GalleryCleanerAlbum = keyof GalleryCleanerContextType['albums'];

export type GalleryAssetsGroup<T extends string> = {
  status: GalleryFetchStatus;
  items: T extends 'similarPhotos' ? GalleryAsset[][] : GalleryAsset[];
  progress: number;
};

export type GalleryCleanerContextType = {
  status: GalleryFetchStatus;
  albums: {
    screenshots: GalleryAssetsGroup<'screenshots'>;
    selfies: GalleryAssetsGroup<'selfies'>;
    videos: GalleryAssetsGroup<'videos'>;
    similarPhotos: GalleryAssetsGroup<'similarPhotos'>;
    blurryPhotos: GalleryAssetsGroup<'blurryPhotos'>;
  };
  fetchAlbums: (
    albums: GalleryCleanerAlbum[],
    fetchNext?: boolean,
  ) => Promise<void>;
  deleteAsset: (assetId: string) => Promise<boolean>;
  deleteAssets: (assetIds: string[]) => Promise<boolean>;
  getAssociatedAlbums: (
    assetIds: string[],
  ) => Record<string, GalleryCleanerAlbum[]>;
};

export const GalleryCleanerContext = createContext<GalleryCleanerContextType>(
  {} as any,
);

export function GalleryCleanerProvider({ children }: PropsWithChildren) {
  const { checkPermissionStatus } = usePermissions();
  const { showAlert } = useAlert();
  const [status, setStatus] = useState<GalleryFetchStatus>('unknown');
  const [albums, setAlbums] = useState<GalleryCleanerContextType['albums']>({
    screenshots: { status: 'unknown', progress: 0, items: [] },
    selfies: { status: 'unknown', progress: 0, items: [] },
    videos: { status: 'unknown', progress: 0, items: [] },
    blurryPhotos: { status: 'unknown', progress: 0, items: [] },
    similarPhotos: { status: 'unknown', progress: 0, items: [] },
  });

  const albumsFetchRequested = useRef<GalleryCleanerAlbum[]>([]);

  const fetchAlbum = useCallback<
    <T extends GalleryCleanerAlbum>(album: T) => Promise<GalleryAssetsGroup<T>>
  >(async (album) => {
    if (album === 'screenshots' || album === 'selfies' || album === 'videos') {
      const items = await CameraRoll.getAssets({
        collectionType: 'smartAlbum',
        collectionSubType: album,
        select: [
          'id',
          'createdAt',
          'name',
          'size',
          'uri',
          ...(album === 'videos' ? ['duration' as const] : []),
        ],
      });

      return {
        progress: 100,
        items: items
          .filter((x) => !!x.uri && x.createdAt && x.size)
          .map((x) => ({
            id: x.id!,
            uri: x.uri!,
            name: x.name!,
            createdAt: x.createdAt!,
            size: x.size,
            mediaType: album === 'videos' ? 'video' : 'image',
            ...(album === 'videos' && {
              duration: x.duration ?? 0,
            }),
          })),
      } as any;
    }

    if (album === 'similarPhotos') {
      const groups = await CameraRoll.findSimilarImages();

      return {
        progress: 100,
        items: groups,
      };
    }

    if (album === 'blurryPhotos') {
      const processedIdsStorageKey = '__processed_blurry_photos__';
      const processedIds: string[] = JSON.parse(
        (await AsyncStorage.getItem(processedIdsStorageKey)) ?? '[]',
      );

      const foundIdsStorageKey = '__found_blurry_photos__';
      const foundIds: string[] = JSON.parse(
        (await AsyncStorage.getItem(foundIdsStorageKey)) ?? '[]',
      );

      const [totalAssetsCount, prevResults] = await Promise.all([
        CameraRoll.getAssetsCount({
          mediaType: 'image',
        }),
        CameraRoll.getAssets({
          mediaType: 'image',
          ids: foundIds,
          select: ['id', 'createdAt', 'name', 'size', 'uri'],
        }),
      ]);

      let newProcessedIds: string[] = [];
      const items = await CameraRoll.findBlurryImages({
        ignoreIds: processedIds,
        onFinished(processedIds) {
          newProcessedIds = [...processedIds];
        },
      });

      await Promise.all([
        AsyncStorage.setItem(
          processedIdsStorageKey,
          JSON.stringify([...processedIds, ...newProcessedIds]),
        ),
        AsyncStorage.setItem(
          foundIdsStorageKey,
          JSON.stringify([
            ...prevResults.map((x) => x.id!),
            ...items.map((x) => x.id!),
          ]),
        ),
      ]);

      return {
        progress: totalAssetsCount,
        items: [...prevResults, ...items],
      };
    }

    throw new Error('Not implemented');
  }, []);

  const fetchAlbums = useCallback(
    async (albums: GalleryCleanerAlbum[], fetchNext = false) => {
      try {
        if (!fetchNext) {
          setStatus('fetching');

          albumsFetchRequested.current = albums;
        }

        const { status } = await checkPermissionStatus(
          Platform.OS === 'ios'
            ? 'ios.permission.PHOTO_LIBRARY'
            : [
                'android.permission.READ_MEDIA_IMAGES',
                'android.permission.READ_MEDIA_VIDEO',
              ],
        );

        if (status === 'blocked') {
          setStatus('blocked');
          return;
        }

        for (let index = 0; index < albums.length; index++) {
          const album = albums[index]!;
          try {
            setAlbums((prev) => ({
              ...prev,
              [album]: { status: 'fetching', progress: 0, items: [] },
            }));

            const { items, progress } = await fetchAlbum(album);
            setAlbums((prev) => ({
              ...prev,
              [album]: { status: 'fetched', progress, items },
            }));
          } catch (err) {
            // @ts-ignore
            showAlert('error', {
              message: (err as Error).message,
            });
            setAlbums((prev) => ({
              ...prev,
              [album]: { status: 'error', progress: 0, items: [] },
            }));
          }
        }

        if (!fetchNext) {
          setStatus('fetched');
        }
      } catch (err) {
        // @ts-ignore
        showAlert('error', {
          code: 'gallery:fetch-albums',
          message: (err as Error).message,
        });
        if (!fetchNext) {
          setStatus('error');
        }
      }
    },
    [],
  );

  const deleteAssets = useCallback(async (assetIds: string[]) => {
    const { status } = await checkPermissionStatus(
      Platform.OS === 'ios'
        ? 'ios.permission.PHOTO_LIBRARY'
        : [
            'android.permission.READ_MEDIA_IMAGES',
            'android.permission.READ_MEDIA_VIDEO',
          ],
    );
    if (status === 'blocked') {
      // @ts-ignore
      showAlert('error', {
        code: 'gallery:access-denied',
        message: 'Access to photo library required',
      });
      setStatus('error');
      return false;
    }

    const { success } = await CameraRoll.deleteAssets(assetIds);
    if (!success) {
      return false;
    }

    setAlbums((prev) => ({
      ...(Object.fromEntries(
        (['screenshots', 'selfies', 'videos', 'blurryPhotos'] as const).map(
          (key) => [
            key,
            {
              ...prev[key],
              items: prev[key].items.filter((x) => !assetIds.includes(x.id!)),
            },
          ],
        ),
      ) as any),
      similarPhotos: {
        ...prev.similarPhotos,
        items: prev.similarPhotos.items
          .map((group) => group.filter((x) => !assetIds.includes(x.id!)))
          .filter((group) => group.length > 1),
      },
    }));

    return true;
  }, []);

  const deleteAsset = useCallback(async (assetId: string) => {
    return await deleteAssets([assetId]);
  }, []);

  const getAssociatedAlbums = useCallback(
    (assetIds: string[]) => {
      const result: Record<string, GalleryCleanerAlbum[]> = {};

      Object.entries(albums).forEach(([album, { items }]) => {
        items.flat().forEach((item) => {
          if (assetIds.includes(item.id)) {
            result[item.id] = result[item.id] ?? [];
            result[item.id]!.push(album as GalleryCleanerAlbum);
          }
        });
      });

      return result;
    },
    [albums],
  );

  useAppActivityEffect(
    (initial) => {
      if (
        initial ||
        !albumsFetchRequested.current.length ||
        status !== 'unknown'
      ) {
        return;
      }

      (async () => {
        const { status } = await checkPermissionStatus(
          Platform.OS === 'ios'
            ? 'ios.permission.PHOTO_LIBRARY'
            : [
                'android.permission.READ_MEDIA_IMAGES',
                'android.permission.READ_MEDIA_VIDEO',
              ],
        );

        if (status === 'granted') {
          fetchAlbums(albumsFetchRequested.current);
        }
      })();
    },
    [status],
  );

  const contextData = useMemo<GalleryCleanerContextType>(
    () => ({
      status,
      albums,
      fetchAlbums,
      deleteAsset,
      deleteAssets,
      getAssociatedAlbums,
    }),
    [status, albums, fetchAlbums, deleteAsset, deleteAssets],
  );

  return (
    <GalleryCleanerContext.Provider value={contextData}>
      {children}
    </GalleryCleanerContext.Provider>
  );
}
