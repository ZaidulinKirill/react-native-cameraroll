import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import { getAssets, editAsset } from 'react-native-gallery';
import { request, PERMISSIONS } from 'react-native-permissions';

export default function App() {
  const [result, setResult] = React.useState<any>();

  React.useEffect(() => {
    (async () => {
      const status = await request(PERMISSIONS.IOS.PHOTO_LIBRARY);
      console.log(status);
      if (!['granted', 'limited'].includes(status)) {
        return;
      }

      const { items, total } = await getAssets({
        skip: 0,
        limit: 1,
        select: ['id', 'isFavourite'],
        assetType: 'all',
      });

      console.log({ items: items, length: items.length, total });
      setResult(items);
    })();
  }, []);

  return (
    <View style={styles.container}>
      {result?.[0] && (
        <TouchableOpacity
          onPress={async () => {
            console.log(result[0].id);
            const ss = await editAsset(result[0].id, {
              isFavourite: !result[0].isFavourite,
            });
            console.log(ss);
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
