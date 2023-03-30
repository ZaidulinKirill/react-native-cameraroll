import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import { getAssets } from 'react-native-gallery';

export default function App() {
  const [result, setResult] = React.useState<any>();

  React.useEffect(() => {
    getAssets({
      limit: 25,
      // sortBy: ['test', 'fest'],
    } as any).then((items) => {
      console.log(items);
      setResult(JSON.stringify(items));
    });
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
