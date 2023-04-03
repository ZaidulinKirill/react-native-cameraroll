import * as React from 'react';

import {
  StyleSheet,
  View,
  Text,
  TouchableOpacity,
  Platform,
} from 'react-native';
import { getAssets, editAsset, deleteAssets } from 'react-native-gallery';
import { request, PERMISSIONS } from 'react-native-permissions';

export default function App() {
  const [result, setResult] = React.useState<any>();

  React.useEffect(() => {
    (async () => {
      if (Platform.OS === 'ios') {
        const status = await request(PERMISSIONS.IOS.PHOTO_LIBRARY);
        console.log(status);
        if (!['granted', 'limited'].includes(status)) {
          return;
        }
      }

      if (Platform.OS === 'android') {
        const status = await request(PERMISSIONS.ANDROID.READ_EXTERNAL_STORAGE);
        console.log(status);
        if (!['granted', 'limited'].includes(status)) {
          return;
        }
      }

      const { items } = await getAssets({
        skip: 1,
        // limit: 1,
        select: [
          // 'id',
          // 'isFavourite',
          'creationDate',
          'mediaType',
          // 'name',
          // 'size',
          // 'uri',
        ],
        mediaType: 'image',
        sortBy: [{ key: 'creationDate', asc: false }],
      });

      //console.log({ items: items, length: items.length, total });
      setResult(items);
    })();
  }, []);

  return (
    <View style={styles.container}>
      {result?.[0] && (
        <TouchableOpacity
          onPress={async () => {
            // console.log(deleteAssets);
            // // console.log(result[0].id);
            // // const ss = await editAsset(result[0].id, {
            // //   isFavourite: !result[0].isFavourite,
            // // });
            // // console.log(ss);
            // console.log(await deleteAssets([result[0].id, result[1].id]));
          }}
        >
          <Text>Click</Text>
        </TouchableOpacity>
      )}
      <Text>Result: {JSON.stringify(result)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
