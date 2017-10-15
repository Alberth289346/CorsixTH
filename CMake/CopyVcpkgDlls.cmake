# Add an extra step to copy built DLLs on MSVC
IF (MSVC AND USE_VCPKG_DEPS)
    # Copy the DLLs from vcpkg into the resulting build folder
    # The DLLs are either in bin/ or debug/bin/ depending on
    # build configuration
    add_custom_command(TARGET CorsixTH POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${VCPKG_INSTALLED_PATH}/$<$<CONFIG:Debug>:debug/>bin"
        $<TARGET_FILE_DIR:CorsixTH>)

    add_custom_command(TARGET CorsixTH POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${VCPKG_INSTALLED_PATH}/share/lua"
        $<TARGET_FILE_DIR:CorsixTH>)

    add_custom_command(TARGET CorsixTH POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E remove
        $<TARGET_FILE_DIR:CorsixTH>/COPYRIGHT)
ENDIF()
