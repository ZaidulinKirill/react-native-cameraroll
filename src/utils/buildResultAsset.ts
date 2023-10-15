import { Platform } from 'react-native';

export function buildResultAsset(item: any) {
  if (Platform.OS === 'ios') {
    return {
      ...(item.id != null && { id: item.id }),
      ...(item.id != null && { uri: `ph://${item.id}` }),
      ...(item.name != null && { name: item.name }),
      ...(item.mediaType != null && {
        type:
          item.mediaType === 1
            ? 'image'
            : item.mediaType === 2
            ? 'video'
            : 'unknown',
      }),
      ...(item.size != null && { size: item.size }),
      ...(item.creationDate != null && {
        creationDate:
          item.creationDate === -1 ? null : new Date(item.creationDate * 1000),
      }),
      ...(item.isFavorite != null && {
        isFavorite: item.isFavorite,
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
      ...(item.creationDate != null && {
        creationDate: new Date(parseInt(item.creationDate, 10) * 1000),
      }),
    };
  }

  throw new Error('Not implemented');
}
