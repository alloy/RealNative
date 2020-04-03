```
██████╗ ███████╗ █████╗ ██╗         ███╗   ██╗ █████╗ ████████╗██╗██╗   ██╗███████╗
██╔══██╗██╔════╝██╔══██╗██║         ████╗  ██║██╔══██╗╚══██╔══╝██║██║   ██║██╔════╝
██████╔╝█████╗  ███████║██║         ██╔██╗ ██║███████║   ██║   ██║██║   ██║█████╗
██╔══██╗██╔══╝  ██╔══██║██║         ██║╚██╗██║██╔══██║   ██║   ██║╚██╗ ██╔╝██╔══╝
██║  ██║███████╗██║  ██║███████╗    ██║ ╚████║██║  ██║   ██║   ██║ ╚████╔╝ ███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝
```

ℹ️ _This was [an April Fool’s 2020 project](https://twitter.com/alloy/status/1245654709421002754). While there may be interesting learnings to take away from this, I would not advice creating applications in this manner generally._

A [React Native](https://reactnative.dev) application with _only_ user-land **C** code. For those of us that _do_ want to make use of React’s approach to defining views, but also realize that modern languages like **Objective-C** and **Swift** are just too high-level. Really, stitching together views needs to be optimized as much as possible. (PRs to port this code to assembler are much appreciated.)

Highlights include:

* Change code, re-compile, wait. Finally have that time again to [play with swords](https://xkcd.com/303/).
* No longer be required to neatly separate view/controller code from native [threaded] code that affects the entire system.
* Actual **C**SS (even if just flexbox).

See the [Components.c](./src/Components.c) file for the definitions of the components that make up the app and as a starting point to browse [the rest of the user-land source](./src) from.

## Install

```sh
git clone https://github.com/alloy/RealNative.git && cd RealNative
yarn
pushd ios && pod install && popd
yarn ios
```

## LICENSE

Available under the [MIT license](./LICENSE).

Thanks to [Richard J. Ross III](https://stackoverflow.com/users/427309/richard-j-ross-iii) for [porting](https://stackoverflow.com/a/10290255/95397) the basic scaffolding of an iOS app to C.
