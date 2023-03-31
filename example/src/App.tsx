import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { getAssets } from 'react-native-gallery';
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
        limit: 100,
        select: ['isFavourite'],
        assetType: 'all',
      });

      console.log({ items: items, length: items.length, total });
      setResult(JSON.stringify(items));
    })();
  }, []);

  return (
    <View style={styles.container}>
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
