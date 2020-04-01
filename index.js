/**
 * @format
 */

import {AppRegistry, YellowBox} from 'react-native';
import {name as appName} from './app.json';

// Metro's `require` function will warn when we use it with a path,
// so disable this now before we invoke the native components.
YellowBox.ignoreWarnings(['Requiring module']);

AppRegistry.registerComponent(appName, () => AppComponent);
