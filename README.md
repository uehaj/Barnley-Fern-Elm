Draw one of famous fractal shape 'Barnsley Fern' in Elm language.

See http://en.wikipedia.org/wiki/Barnsley_fern .

* how to run

    elm-get install
    patch -d elm_dependencies -p 1 < pach-to-jcollard-generator-0.3.patch
    elm-reactor

* how to build for publish generated html and js to the web.

    mkdir -p build/runtime
    cp `elm -g` build/runtime
    elm -m --set-runtime=./runtime/elm-runtime.js \*.elm
    # cp -r build TO_SOMEWHERE # publish
