GRADLE = gradle

MAKE_OCAML = $(MAKE) -C ocaml

ANDROID_ASSETS = android/app/src/main/assets/

app-debug = $(ANDROID_ASSETS)app-debug.apk

android: $(app-debug)

cli:
	$(MAKE_OCAML) ffg_ladder.exe

$(app-debug): $(ANDROID_ASSETS)stubs.js
	$(GRADLE) -p android assembleDebug

$(ANDROID_ASSETS)stubs.js:
	$(MAKE_OCAML) stubs.bc.js
	mkdir -p $(ANDROID_ASSETS)
	cp ocaml/_build/default/stubs/stubs.bc.js \
	   $(ANDROID_ASSETS)stubs.js

clean:
	$(MAKE_OCAML) clean
	$(GRADLE) -p android clean
	rm -rf $(ANDROID_ASSETS)

.PHONY: clean android
