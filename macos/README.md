Minetest cross build support building script:

Some example:

`./sfence_minetest_scripts/macos/macos_build_with_deps.sh https://github.com/minetest/minetest.git 5.9.0 ./minetest_build_x86_64_105 Debug "x86_64" "10.15" "build|run" 2>&1 | tee mac_x86_64_log`
