# hashlink-launcher
A Game/Program launcher with support automatic updates

It works by checking for deployed packages on bintray containing the game and launcher images.

If you want to use it yourself, create a repo on bintray, with two packages. 
One for your game image, and one for the launcher (the file built here).
I named my packages `data`, and `launcher-data`.

Set the variables to correct values in the top of `src/Main.hx`.
If you used the same package names, you only need to change `bintrayUser` and `bintrayRepo`.

Then you can style it a bit however you want.

## Deploying packages

To deploy new versions, create a new version in bintray.

A version should contain one file, a zip file containing the HashLink image:
Game Example:
```
game-0.0.1.zip
 |-game.dat
```

Add it to the version, and publish. It should now work. 

The launcher package works the same way.

Both the launcher and game package should contain at least one base version.

## Distributing
To distribute, build the launcher image, and put it in the same dir as hashlink. [More info](https://github.com/HaxeFoundation/hashlink/wiki/Distribution-&--Packaging)

The files required are the following:

###Windows
```
 OpenAL32.dll
 SDL2.dll
 fmt.hdll
 hl.exe
 libhl.dll
 msvcr120.dll
 openal.hdll
 sdl.hdll
 soft_oal.dll
 ssl.hdll
 ui.hdll
 uv.hdll
```

###Linux
```
 fmt.hdll
 hl
 libSDL2-2.0.so
 libSDL2-2.0.so.0
 libhl.so
 libmbedcrypto.so.3
 libmbedtls.so.12
 libmbedx509.so.0
 libogg.so.0
 libopenal.so.1
 libpng16.so.16
 libturbojpeg.so.0
 libuv.so.1
 libvorbis.so.0
 libvorbisfile.so.3
 mysql.hdll
 openal.hdll
 sdl.hdll
 ssl.hdll
 ui.hdll
 uv.hdll
```


