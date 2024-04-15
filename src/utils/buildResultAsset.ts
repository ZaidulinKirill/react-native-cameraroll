import { Platform } from 'react-native';

export function buildResultAsset(item: any) {
  if (Platform.OS === 'ios') {
    return {
      ...(item.id != null && { id: item.id }),
      ...(item.id != null && { uri: `ph://${item.id}` }),
      ...(item.name != null && { name: item.name }),
      ...(item.mediaType != null && {
        mediaType:
          item.mediaType === 1
            ? 'image'
            : item.mediaType === 2
            ? 'video'
            : 'unknown',
      }),
      ...(item.size != null && { size: item.size }),
      ...(item.createdAt != null && {
        createdAt:
          item.createdAt === -1
            ? null
            : new Date(item.createdAt * 1000).toISOString(),
      }),
      ...(item.isFavorite != null && {
        isFavorite: item.isFavorite,
      }),
      ...(item.duration != null && {
        duration: item.duration,
      }),
      ...(item.width != null && {
        width: item.width,
      }),
      ...(item.height != null && {
        height: item.height,
      }),
    };
  }

  if (Platform.OS === 'android') {
    return {
      ...(item.id != null && { id: item.id }),
      ...(item.name != null && { name: item.name }),
      ...(item.uri != null && { uri: item.uri }),
      ...(item.size != null && { size: item.size }),
      ...(item.isFavorite != null && { isFavorite: item.isFavorite === '1' }),
      ...(item.mediaType != null && {
        mediaType:
          item.mediaType === 1
            ? 'image'
            : item.mediaType === 3
            ? 'video'
            : 'unknown',
      }),
      ...(item.createdAt != null && {
        createdAt: new Date(parseInt(item.createdAt, 10) * 1000).toISOString(),
      }),
      ...(item.duration != null && {
        duration: item.duration,
      }),
      ...(item.width != null && {
        width: item.width,
      }),
      ...(item.height != null && {
        height: item.height,
      }),
    };
  }

  throw new Error('Not implemented');
}
